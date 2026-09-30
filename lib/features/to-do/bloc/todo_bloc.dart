import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/firestore_repository.dart';
import '../data/todo_model.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FirestoreRepository _repository;
  StreamSubscription? _subscription;

  TaskBloc(this._repository) : super(TaskLoading()) {
    on<LoadTasksEvent>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository.getTasksStream().listen(
            (tasks) => add(_TasksUpdatedEvent(tasks)),
            onError: (err) => emit(TaskError(err.toString())),
          );
    });

    on<_TasksUpdatedEvent>((event, emit) => emit(TaskLoaded(event.tasks)));

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
    return super.close();
  }
}
