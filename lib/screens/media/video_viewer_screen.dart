
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';


class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing video: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _downloadVideo() async {
    if (_isDownloading) return;

   
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download videos. Please grant permission from Settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final String fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');

       
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
          if (directory == null) throw Exception('Could not access storage');
        }
      } else {
        
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Could not access storage');

      final String savePath = '${directory.path}/$fileName';
      final File file = File(savePath);

      await Dio().download(
        widget.videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video saved to Downloads: $fileName'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    
    if (await Permission.photos.isGranted && await Permission.videos.isGranted) {
      return true;
    }

    
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ].request();

    return statuses[Permission.storage]!.isGranted ||
        (statuses[Permission.photos]!.isGranted && statuses[Permission.videos]!.isGranted);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isInitialized)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadVideo,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isInitialized)
            Center(
              child: Chewie(controller: _chewieController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _downloadProgress,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
