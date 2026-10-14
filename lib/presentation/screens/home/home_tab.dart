import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../logic/task/task_bloc.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PageController carouselController = PageController();
    final List<String> studyTips = [
      "Pomodoro Technique: Study 25 mins, rest 5 mins.",
      "Active Recall: Test yourself frequently while revising.",
      "Spaced Repetition: Review notes after 1, 3, and 7 days.",
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, ${FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student'}!',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppTheme.primaryNavy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.format_quote,
                        color: AppTheme.brandRed, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '"Arise, awake, and stop not till the goal is reached."',
                        style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Study Tips Carousel',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: PageView.builder(
                controller: carouselController,
                itemCount: studyTips.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: AppTheme.brandRed),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(studyTips[index],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your Subjects',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy)),
            const SizedBox(height: 8),
            StreamBuilder<List<String>>(
              stream: context.read<FirestoreRepository>().getSubjectsStream(),
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? ['General'];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  itemCount: subjects.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == subjects.length) {
                      return InkWell(
                        onTap: () => _showAddSubjectDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          color: Colors.red.shade50,
                          elevation: 1,
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle,
                                    color: AppTheme.brandRed),
                                SizedBox(width: 6),
                                Text('Add Subject',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryNavy)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final subjectName = subjects[idx];
                    final isGeneral = subjectName == 'General';

                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.book,
                                color: AppTheme.brandRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subjectName,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isGeneral)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'rename') {
                                      _showRenameSubjectDialog(
                                          context, subjectName);
                                    } else if (value == 'delete') {
                                      _showDeleteSubjectDialog(
                                          context, subjectName);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              size: 16, color: Colors.blueGrey),
                                          SizedBox(width: 8),
                                          Text('Rename',
                                              style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Upcoming Tasks',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy)),
            const SizedBox(height: 8),
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoaded) {
                  final pending =
                      state.rawTasks.where((t) => !t.isCompleted).toList();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions,
                          color: AppTheme.brandRed),
                      title: Text('${pending.length} Pending Tasks'),
                      subtitle: Text(pending.isNotEmpty
                          ? 'Next: ${pending.first.title}'
                          : 'No pending tasks!'),
                    ),
                  );
                }
                return const Card(
                    child: ListTile(title: Text('Loading tasks...')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Subject'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Computer Networks')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<FirestoreRepository>()
                    .addSubject(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Subject'),
          )
        ],
      ),
    );
  }

  void _showRenameSubjectDialog(BuildContext context, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename "$oldName"'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'New Subject Name',
                hintText: 'e.g., Data Structures & Algorithms')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty &&
                  controller.text.trim() != oldName) {
                context
                    .read<FirestoreRepository>()
                    .renameSubject(oldName, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          )
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, String subjectName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$subjectName"?'),
        content: const Text(
            'Are you sure you want to remove this subject? Existing tasks in this subject will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<FirestoreRepository>().deleteSubject(subjectName);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
