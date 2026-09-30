// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/firestore_repository.dart';
import '../bloc/todo_bloc.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  bool _showCompleted = false;
  final Set<String> _fadingTaskIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showCompleted ? 'Showing All Tasks' : 'Showing Active Tasks',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showCompleted = !_showCompleted),
                  icon: Icon(
                    _showCompleted
                        ? Icons.visibility_off
                        : Icons.check_circle_outline,
                    color: AppTheme.brandRed,
                  ),
                  label: Text(
                    _showCompleted ? 'Hide Completed' : 'Show Completed',
                    style: const TextStyle(color: AppTheme.primaryNavy),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TaskError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is TaskLoaded) {
                  final displayTasks = _showCompleted
                      ? state.tasks
                      : state.tasks.where((t) => !t.isCompleted).toList();

                  if (displayTasks.isEmpty) {
                    return Center(
                      child: Text(
                        _showCompleted
                            ? 'No tasks created yet!'
                            : 'All caught up! Tap + to add a task.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: displayTasks.length,
                    itemBuilder: (context, index) {
                      final task = displayTasks[index];
                      final isFading = _fadingTaskIds.contains(task.id);
                      final isDone = task.isCompleted || isFading;

                      return Dismissible(
                        key: Key(task.id),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          context
                              .read<TaskBloc>()
                              .add(DeleteTaskEvent(task.id));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Task "${task.title}" deleted')));
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity:
                              isFading ? 0.0 : (task.isCompleted ? 0.35 : 1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isDone ? Colors.grey.shade100 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isDone
                                  ? []
                                  : const [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 4)
                                    ],
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: AppTheme.brandRed,
                                checkColor: Colors.white,
                                value: isDone,
                                onChanged: (_) async {
                                  if (!task.isCompleted) {
                                    setState(() {
                                      _fadingTaskIds.add(task.id);
                                    });

                                    await Future.delayed(
                                        const Duration(milliseconds: 500));

                                    if (mounted) {
                                      context.read<TaskBloc>().add(
                                          ToggleTaskEvent(
                                              task.id, task.isCompleted));
                                      setState(() {
                                        _fadingTaskIds.remove(task.id);
                                      });
                                    }
                                  } else {
                                    context.read<TaskBloc>().add(
                                        ToggleTaskEvent(
                                            task.id, task.isCompleted));
                                  }
                                },
                              ),
                              title: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: AppTheme.brandRed,
                                  decorationThickness: 2.0,
                                  color: isDone
                                      ? Colors.grey.shade600
                                      : AppTheme.primaryNavy,
                                  fontWeight: isDone
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  fontSize: 16,
                                ),
                                child: Text(task.title),
                              ),
                              subtitle: Text(task.subject,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Study Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<String>>(
              stream: context.read<FirestoreRepository>().getSubjectsStream(),
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? ['General'];
                selectedSubject ??= subjects.first;

                return DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Select Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (val) => selectedSubject = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                context.read<TaskBloc>().add(AddTaskEvent(
                      titleCtrl.text.trim(),
                      selectedSubject ?? 'General',
                    ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Task'),
          )
        ],
      ),
    );
  }
}
