import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../media/image_viewer_screen.dart';
import '../media/video_viewer_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProjectService _projectService = ProjectService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  late Project _currentProject;
  bool _isRefreshing = false;
  String _addButtonText = 'Add Image';
  IconData _addButtonIcon = Icons.add_photo_alternate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentProject = widget.project;
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _addButtonText = _tabController.index == 0 ? 'Add Image' : 'Add Video';
          _addButtonIcon = _tabController.index == 0 ? Icons.add_photo_alternate : Icons.video_call;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshProject() async {
    setState(() => _isRefreshing = true);
    try {
      final updatedProject = await _projectService.getProject(_currentProject.id);
      if (updatedProject != null && mounted) {
        setState(() => _currentProject = updatedProject);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showVideoPlayer(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  void _showImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }

  Future<void> _pickAndUploadMedia(bool isImage) async {
    try {
      final XFile? file = isImage
          ? await _picker.pickImage(source: ImageSource.gallery)
          : await _picker.pickVideo(source: ImageSource.gallery);

      if (file == null) return;

      setState(() => _isUploading = true);

      final String url = await _projectService.uploadMedia(
        File(file.path),
        _currentProject.id,
        isImage,
      );

      await _projectService.addMediaUrl(_currentProject.id, url, isImage);
      await _refreshProject();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isImage ? 'Image' : 'Video'} uploaded successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentProject.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentProject.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Images',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Videos',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshProject,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Images Tab
                _buildMediaGrid(
                  _currentProject.imageUrls,
                  true,
                  Icons.image,
                  'No images yet',
                ),
                // Videos Tab
                _buildMediaGrid(
                  _currentProject.videoUrls,
                  false,
                  Icons.video_library,
                  'No videos yet',
                ),
              ],
            ),
          ),
          if (_isUploading || _isRefreshing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isUploading 
                        ? 'Uploading ${_tabController.index == 0 ? 'Image' : 'Video'}...'
                        : 'Refreshing...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndUploadMedia(_tabController.index == 0),
        icon: Icon(_addButtonIcon),
        label: Text(_addButtonText),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMediaGrid(
    List<String> urls,
    bool isImage,
    IconData placeholderIcon,
    String emptyMessage,
  ) {
    if (urls.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshProject,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      placeholderIcon,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh or tap the button below to add media',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProject,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (isImage) {
                  _showImageViewer(url);
                } else {
                  _showVideoPlayer(url);
                }
              },
              child: isImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Play Video',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
