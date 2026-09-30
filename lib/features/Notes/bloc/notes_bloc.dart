import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/firestore_repository.dart';
import '../data/note_model.dart';

part 'notes_event.dart';
part 'notes_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final FirestoreRepository _repository;
  StreamSubscription? _subscription;

  NoteBloc(this._repository) : super(NoteLoading()) {
    on<LoadNotesEvent>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository.getNotesStream().listen(
            (notes) => add(_NotesUpdatedEvent(notes)),
            onError: (err) => emit(NoteError(err.toString())),
          );
    });

    on<_NotesUpdatedEvent>((event, emit) => emit(NoteLoaded(event.notes)));

    on<AddNoteEvent>((event, emit) async {
      await _repository.addNote(event.title, event.content);
    });

    on<DeleteNoteEvent>((event, emit) async {
      await _repository.deleteNote(event.noteId);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
