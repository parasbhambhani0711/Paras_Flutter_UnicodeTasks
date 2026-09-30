part of 'notes_bloc.dart';

abstract class NoteEvent {}

class LoadNotesEvent extends NoteEvent {}

class AddNoteEvent extends NoteEvent {
  final String title;
  final String content;
  AddNoteEvent(this.title, this.content);
}

class DeleteNoteEvent extends NoteEvent {
  final String noteId;
  DeleteNoteEvent(this.noteId);
}

class _NotesUpdatedEvent extends NoteEvent {
  final List<NoteModel> notes;
  _NotesUpdatedEvent(this.notes);
}
