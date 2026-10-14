import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    required this.createdAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NoteModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      fileName: data['fileName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
