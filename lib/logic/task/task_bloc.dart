import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/enums/app_enums.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/firestore_repository.dart';

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
class SearchTasksEvent extends TaskEvent {
  final String query;
  SearchTasksEvent(this.query);
}
class SortTasksEvent extends TaskEvent {
  final TaskSortOption sortOption;
  SortTasksEvent(this.sortOption);
}
class FilterTasksEvent extends TaskEvent {
  final TaskFilterOption filterOption;
  FilterTasksEvent(this.filterOption);
}

abstract class TaskState {}
class TaskLoading extends TaskState {}
class TaskLoaded extends TaskState {
  final List<TaskModel> rawTasks;
  final String searchQuery;
  final TaskSortOption sortOption;
  final TaskFilterOption filterOption;

  TaskLoaded({
    required this.rawTasks,
    this.searchQuery = '',
    this.sortOption = TaskSortOption.dateNewest,
    this.filterOption = TaskFilterOption.all,
  });

  List<TaskModel> get filteredTasks {
    List<TaskModel> list = List.from(rawTasks);

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.subject.toLowerCase().contains(q))
          .toList();
    }

    if (filterOption == TaskFilterOption.pending) {
      list = list.where((t) => !t.isCompleted).toList();
    } else if (filterOption == TaskFilterOption.completed) {
      list = list.where((t) => t.isCompleted).toList();
    }

    switch (sortOption) {
      case TaskSortOption.dateNewest:
        break;
      case TaskSortOption.dateOldest:
        list = list.reversed.toList();
        break;
      case TaskSortOption.alphaAZ:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case TaskSortOption.alphaZA:
        list.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return list;
  }
}
class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FirestoreRepository _repository;
  StreamSubscription? _subscription;
  Timer? _autoVanishTimer;

  List<TaskModel> _latestRawTasks = [];
  String _currentSearchQuery = '';
  TaskSortOption _currentSortOption = TaskSortOption.dateNewest;
  TaskFilterOption _currentFilterOption = TaskFilterOption.all;

  TaskBloc(this._repository) : super(TaskLoading()) {
    _autoVanishTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_latestRawTasks.isNotEmpty) {
        add(LoadTasksEvent());
      }
    });

    on<LoadTasksEvent>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository.getTasksStream().listen(
        (tasks) {
          _latestRawTasks = tasks;
          final pendingCount = tasks.where((t) => !t.isCompleted).length;
          NotificationService.scheduleHourlyReminder(pendingCount);
          add(_TasksUpdatedEvent(tasks));
        },
        onError: (err) => emit(TaskError(err.toString())),
      );
    });

    on<_TasksUpdatedEvent>((event, emit) {
      emit(TaskLoaded(
        rawTasks: _latestRawTasks,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<SearchTasksEvent>((event, emit) {
      _currentSearchQuery = event.query;
      emit(TaskLoaded(
        rawTasks: _latestRawTasks,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<SortTasksEvent>((event, emit) {
      _currentSortOption = event.sortOption;
      emit(TaskLoaded(
        rawTasks: _latestRawTasks,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<FilterTasksEvent>((event, emit) {
      _currentFilterOption = event.filterOption;
      emit(TaskLoaded(
        rawTasks: _latestRawTasks,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<AddTaskEvent>((event, emit) async {
      await _repository.addTask(event.title, event.subject);
    });

    on<ToggleTaskEvent>((event, emit) async {
      await _repository.toggleTask(event.taskId, event.currentStatus);
    });

    on<DeleteTaskEvent>((event, emit) async {
      await _repository.deleteTask(event.taskId);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _autoVanishTimer?.cancel();
    return super.close();
  }
}

class _TasksUpdatedEvent extends TaskEvent {
  final List<TaskModel> tasks;
  _TasksUpdatedEvent(this.tasks);
}
