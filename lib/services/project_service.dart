import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'projects';

  Stream<List<Project>> getProjects() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Project>> searchProjects(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
    });
  }

  Future<Project?> getProject(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return doc.exists ? Project.fromFirestore(doc) : null;
  }

  Future<String> uploadMedia(File file, String projectId, bool isImage) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = file.path.split('.').last.toLowerCase();
      final String type = isImage ? 'images' : 'videos';
      final String fileName = 'projects/$projectId/$type/$timestamp.$extension';

      final Reference storageRef = _storage.ref().child(fileName);

      final SettableMetadata metadata = SettableMetadata(
        contentType: isImage 
            ? 'image/${extension == 'jpg' ? 'jpeg' : extension}'
            : 'video/$extension',
        customMetadata: {
          'projectId': projectId,
          'timestamp': timestamp,
          'type': type,
        },
      );

      final TaskSnapshot uploadTask = await storageRef.putFile(file, metadata);

      if (uploadTask.state == TaskState.success) {
        final String downloadUrl = await uploadTask.ref.getDownloadURL();
        print('File uploaded successfully. URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload failed: ${uploadTask.state}');
      }
    } catch (e) {
      print('Error uploading media: $e');
      throw Exception('Failed to upload media. Please try again.');
    }
  }

 
  Future<void> addMediaUrl(String projectId, String url, bool isImage) async {
    try {
      final field = isImage ? 'imageUrls' : 'videoUrls';
      await _firestore.collection(_collection).doc(projectId).update({
        field: FieldValue.arrayUnion([url])
      });
    } catch (e) {
      print('Error adding media URL: $e');
      throw Exception('Failed to update project with media URL.');
    }
  }

  
  Future<void> createSampleProjects() async {
    final List<Map<String, dynamic>> sampleProjects = [
      {
        'name': 'Tech Park Project',
        'description': 'Modern IT park development in Whitefield',
        'location': const GeoPoint(12.9698, 77.7500),
        'imageUrls': ['http://www.mtdigroup.com/files/mtdi/styles/full/public/img/techparkcosmos.jpg'],
        'videoUrls': [],
        'createdAt': DateTime.now(),
      },
      {
        'name': 'Residential Complex',
        'description': 'Luxury apartments in Electronic City',
        'location': const GeoPoint(12.8458, 77.6692),
        'imageUrls': [],
        'videoUrls': [],
        'createdAt': DateTime.now(),
      },
      {
        'name': 'Commercial Hub',
        'description': 'Mixed-use development in Koramangala',
        'location': const GeoPoint(12.9349, 77.6205),
        'imageUrls': [],
        'videoUrls': [],
        'createdAt': DateTime.now(),
      },
      {
        'name': 'Garden Towers',
        'description': 'Eco-friendly office space in Indiranagar',
        'location': const GeoPoint(12.9784, 77.6408),
        'imageUrls': [],
        'videoUrls': [],
        'createdAt': DateTime.now(),
      },
      {
        'name': 'Metro Plaza',
        'description': 'Retail complex near MG Road',
        'location': const GeoPoint(12.9716, 77.6019),
        'imageUrls': [],
        'videoUrls': [],
        'createdAt': DateTime.now(),
      },
    ];

    for (final project in sampleProjects) {
      await _firestore.collection(_collection).add(project);
    }
  }
} 