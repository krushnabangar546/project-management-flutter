
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _isDownloading = false;

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

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download images. Please grant permission from Settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      
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
        widget.imageUrl,
        savePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to Downloads: $fileName'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
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
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadImage,
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(widget.imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
              ),
            ),
            errorBuilder: (context, error, stackTrace) => Center(
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
                    'Error loading image: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Saving to gallery...',
                      style: TextStyle(color: Colors.white),
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