part of 'todo_bloc.dart';

abstract class TaskEvent {}

class LoadTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final String title;
  final String subject;
  AddTaskEvent(this.title, this.subject);
}

class ToggleTaskEvent extends TaskEvent {
  final String taskId;
  final bool currentStatus;
  ToggleTaskEvent(this.taskId, this.currentStatus);
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  DeleteTaskEvent(this.taskId);
}

class _TasksUpdatedEvent extends TaskEvent {
  final List<TaskModel> tasks;
  _TasksUpdatedEvent(this.tasks);
}
