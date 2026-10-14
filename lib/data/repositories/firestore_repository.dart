import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';

class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<String> _cachedSubjects = ['General'];
  List<String> get cachedSubjects => _cachedSubjects;

  Stream<List<String>> getSubjectsStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(['General']);
      return _db
          .collection('Users')
          .doc(user.uid)
          .collection('subjects')
          .snapshots()
          .map((snap) {
        if (snap.docs.isEmpty) {
          _cachedSubjects = ['General'];
          return ['General'];
        }

        final docs = List<QueryDocumentSnapshot>.from(snap.docs);
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });

        final list = docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return data['name'] as String? ?? '';
            })
            .where((name) => name.isNotEmpty)
            .toList();

        if (!list.contains('General')) list.insert(0, 'General');
        _cachedSubjects = list;
        return list;
      });
    });
  }

  Future<void> addSubject(String name) async {
    final uid = _uid;
    if (uid == null || name.trim().isEmpty) return;
    final cleanName = name.trim();

    await _db.collection('Users').doc(uid).collection('subjects').add({
      'name': cleanName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> renameSubject(String oldName, String newName) async {
    final uid = _uid;
    if (uid == null || oldName == 'General' || newName.trim().isEmpty) return;
    final cleanNew = newName.trim();

    final snap = await _db
        .collection('Users')
        .doc(uid)
        .collection('subjects')
        .where('name', isEqualTo: oldName)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.update({'name': cleanNew});
    }

    final taskSnap = await _db
        .collection('Users')
        .doc(uid)
        .collection('tasks')
        .where('subject', isEqualTo: oldName)
        .get();
    for (var doc in taskSnap.docs) {
      await doc.reference.update({'subject': cleanNew});
    }
  }

  Future<void> deleteSubject(String name) async {
    final uid = _uid;
    if (uid == null || name == 'General') return;
    final snap = await _db
        .collection('Users')
        .doc(uid)
        .collection('subjects')
        .where('name', isEqualTo: name)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<TaskModel>> getTasksStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _db
          .collection('Users')
          .doc(user.uid)
          .collection('tasks')
          .snapshots()
          .map((snap) {
        final now = DateTime.now();
        final validTasks = <TaskModel>[];

        for (var doc in snap.docs) {
          final task = TaskModel.fromFirestore(doc);
          if (task.isCompleted) {
            if (task.completedAt == null) {
              validTasks.add(task);
              continue;
            }

            final elapsed = now.difference(task.completedAt!);
            if (elapsed.inSeconds >= 86400) {
              Future.microtask(() => doc.reference.delete());
              continue;
            }
          }
          validTasks.add(task);
        }
        return validTasks;
      });
    });
  }

  Future<void> addTask(String title, String subject) async {
    final uid = _uid;
    if (uid == null) return;
    await addSubject(subject);
    await _db.collection('Users').doc(uid).collection('tasks').add({
      'title': title,
      'subject': subject,
      'isCompleted': false,
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTask(String taskId, bool currentStatus) async {
    final uid = _uid;
    if (uid == null) return;
    final bool newStatus = !currentStatus;
    await _db
        .collection('Users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'isCompleted': newStatus,
      'completedAt': newStatus ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('Users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<List<NoteModel>> getNotesStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _db
          .collection('Users')
          .doc(user.uid)
          .collection('notes')
          .snapshots()
          .map((snap) {
        final docs = List<QueryDocumentSnapshot>.from(snap.docs);
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return docs.map((doc) => NoteModel.fromFirestore(doc)).toList();
      });
    });
  }

  Future<void> addNote(
    String title,
    String content, {
    String? mediaUrl,
    String? mediaType,
    String? fileName,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('Users').doc(uid).collection('notes').add({
      'title': title,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNote(
    String noteId,
    String newTitle,
    String newContent, {
    String? mediaUrl,
    String? mediaType,
    String? fileName,
  }) async {
    final uid = _uid;
    if (uid == null || newTitle.trim().isEmpty) return;

    await _db
        .collection('Users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .update({
      'title': newTitle.trim(),
      'content': newContent.trim(),
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': fileName,
    });
  }

  Future<void> deleteNote(String noteId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('Users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}
