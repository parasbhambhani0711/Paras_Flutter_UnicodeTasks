import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/firestore_repository.dart';

abstract class NoteEvent {}
class LoadNotesEvent extends NoteEvent {}
class AddNoteEvent extends NoteEvent {
  final String title;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;

  AddNoteEvent(
    this.title,
    this.content, {
    this.mediaUrl,
    this.mediaType,
    this.fileName,
  });
}
class DeleteNoteEvent extends NoteEvent {
  final String noteId;
  DeleteNoteEvent(this.noteId);
}
class SearchNotesEvent extends NoteEvent {
  final String query;
  SearchNotesEvent(this.query);
}
class SortNotesEvent extends NoteEvent {
  final NoteSortOption sortOption;
  SortNotesEvent(this.sortOption);
}
class FilterNotesEvent extends NoteEvent {
  final NoteFilterOption filterOption;
  FilterNotesEvent(this.filterOption);
}

abstract class NoteState {}
class NoteLoading extends NoteState {}
class NoteLoaded extends NoteState {
  final List<NoteModel> rawNotes;
  final String searchQuery;
  final NoteSortOption sortOption;
  final NoteFilterOption filterOption;

  NoteLoaded({
    required this.rawNotes,
    this.searchQuery = '',
    this.sortOption = NoteSortOption.dateNewest,
    this.filterOption = NoteFilterOption.all,
  });

  List<NoteModel> get filteredNotes {
    List<NoteModel> list = List.from(rawNotes);

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList();
    }

    if (filterOption == NoteFilterOption.hasMedia) {
      list = list
          .where((n) => n.mediaUrl != null && n.mediaUrl!.isNotEmpty)
          .toList();
    } else if (filterOption == NoteFilterOption.textOnly) {
      list =
          list.where((n) => n.mediaUrl == null || n.mediaUrl!.isEmpty).toList();
    }

    switch (sortOption) {
      case NoteSortOption.dateNewest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NoteSortOption.dateOldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NoteSortOption.alphaAZ:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.alphaZA:
        list.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return list;
  }
}
class NoteError extends NoteState {
  final String message;
  NoteError(this.message);
}

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final FirestoreRepository _repository;
  StreamSubscription? _subscription;

  List<NoteModel> _latestRawNotes = [];
  String _currentSearchQuery = '';
  NoteSortOption _currentSortOption = NoteSortOption.dateNewest;
  NoteFilterOption _currentFilterOption = NoteFilterOption.all;

  NoteBloc(this._repository) : super(NoteLoading()) {
    on<LoadNotesEvent>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository.getNotesStream().listen(
        (notes) {
          _latestRawNotes = notes;
          add(_NotesUpdatedEvent(notes));
        },
        onError: (err) => emit(NoteError(err.toString())),
      );
    });

    on<_NotesUpdatedEvent>((event, emit) {
      emit(NoteLoaded(
        rawNotes: _latestRawNotes,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<SearchNotesEvent>((event, emit) {
      _currentSearchQuery = event.query;
      emit(NoteLoaded(
        rawNotes: _latestRawNotes,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<SortNotesEvent>((event, emit) {
      _currentSortOption = event.sortOption;
      emit(NoteLoaded(
        rawNotes: _latestRawNotes,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<FilterNotesEvent>((event, emit) {
      _currentFilterOption = event.filterOption;
      emit(NoteLoaded(
        rawNotes: _latestRawNotes,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
        filterOption: _currentFilterOption,
      ));
    });

    on<AddNoteEvent>((event, emit) async {
      await _repository.addNote(
        event.title,
        event.content,
        mediaUrl: event.mediaUrl,
        mediaType: event.mediaType,
        fileName: event.fileName,
      );
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

class _NotesUpdatedEvent extends NoteEvent {
  final List<NoteModel> notes;
  _NotesUpdatedEvent(this.notes);
}
