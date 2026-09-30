import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String subject;
  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    this.isCompleted = false,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? 'General',
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
