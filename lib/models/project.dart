import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final GeoPoint location;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrls,
    required this.videoUrls,
    required this.createdAt,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final List<dynamic> rawImageUrls = data['imageUrls'] ?? [];
    final List<dynamic> rawVideoUrls = data['videoUrls'] ?? [];
    
    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] as GeoPoint,
      imageUrls: rawImageUrls.map((url) => url.toString()).toList(),
      videoUrls: rawVideoUrls.map((url) => url.toString()).toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'createdAt': createdAt,
    };
  }
} 