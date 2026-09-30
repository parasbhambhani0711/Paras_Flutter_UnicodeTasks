import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/to-do/data/todo_model.dart';
import '../../features/Notes/data/note_model.dart';

class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- Dynamic Subjects ---
  Stream<List<String>> getSubjectsStream() {
    if (_uid == null) return Stream.value(['General']);
    return _db
        .collection('Users')
        .doc(_uid)
        .collection('subjects')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return ['General'];
      }
      final list = snap.docs.map((doc) => doc['name'] as String).toList();
      if (!list.contains('General')) list.insert(0, 'General');
      return list;
    });
  }

  Future<void> addSubject(String name) async {
    if (_uid == null) return;
    await _db
        .collection('Users')
        .doc(_uid)
        .collection('subjects')
        .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
  }

  // --- Tasks ---
  Stream<List<TaskModel>> getTasksStream() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('Users')
        .doc(_uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Future<void> addTask(String title, String subject) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('tasks').add({
      'title': title,
      'subject': subject,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTask(String taskId, bool currentStatus) async {
    if (_uid == null) return;
    await _db
        .collection('Users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});
  }

  Future<void> deleteTask(String taskId) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('tasks').doc(taskId).delete();
  }

  // --- Notes ---
  Stream<List<NoteModel>> getNotesStream() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('Users')
        .doc(_uid)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NoteModel.fromFirestore(doc)).toList());
  }

  Future<void> addNote(String title, String content) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('notes').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    if (_uid == null) return;
    await _db.collection('Users').doc(_uid).collection('notes').doc(noteId).delete();
  }
}
