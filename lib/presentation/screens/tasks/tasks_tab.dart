// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../logic/task/task_bloc.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final Set<String> _fadingTaskIds = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      context.read<TaskBloc>().add(SearchTasksEvent(val));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tasks or subjects...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                context
                                    .read<TaskBloc>()
                                    .add(SearchTasksEvent(''));
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    final currentSort = state is TaskLoaded
                        ? state.sortOption
                        : TaskSortOption.dateNewest;

                    return PopupMenuButton<TaskSortOption>(
                      icon: const Icon(Icons.sort, color: AppTheme.primaryNavy),
                      tooltip: 'Sort Tasks',
                      initialValue: currentSort,
                      onSelected: (option) {
                        context.read<TaskBloc>().add(SortTasksEvent(option));
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                            value: TaskSortOption.dateNewest,
                            child: Text('Date: Newest First')),
                        const PopupMenuItem(
                            value: TaskSortOption.dateOldest,
                            child: Text('Date: Oldest First')),
                        const PopupMenuItem(
                            value: TaskSortOption.alphaAZ,
                            child: Text('Alphabetical (A-Z)')),
                        const PopupMenuItem(
                            value: TaskSortOption.alphaZA,
                            child: Text('Alphabetical (Z-A)')),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              final currentFilter = state is TaskLoaded
                  ? state.filterOption
                  : TaskFilterOption.all;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: currentFilter == TaskFilterOption.all,
                      onSelected: (_) => context
                          .read<TaskBloc>()
                          .add(FilterTasksEvent(TaskFilterOption.all)),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Pending'),
                      selected: currentFilter == TaskFilterOption.pending,
                      onSelected: (_) => context
                          .read<TaskBloc>()
                          .add(FilterTasksEvent(TaskFilterOption.pending)),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: currentFilter == TaskFilterOption.completed,
                      onSelected: (_) => context
                          .read<TaskBloc>()
                          .add(FilterTasksEvent(TaskFilterOption.completed)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 12),
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
                  final displayTasks = state.filteredTasks;

                  if (displayTasks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching tasks found.',
                        style: TextStyle(color: Colors.grey),
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
                          duration: const Duration(milliseconds: 900),
                          opacity:
                              isFading ? 0.0 : (task.isCompleted ? 0.35 : 1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
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
                                        const Duration(milliseconds: 900));

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
                                duration: const Duration(milliseconds: 400),
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
                              subtitle: Text(
                                task.isCompleted
                                    ? '${task.subject} • Clears automatically in 24h'
                                    : task.subject,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.grey),
                                onPressed: () {
                                  context
                                      .read<TaskBloc>()
                                      .add(DeleteTaskEvent(task.id));
                                },
                              ),
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
