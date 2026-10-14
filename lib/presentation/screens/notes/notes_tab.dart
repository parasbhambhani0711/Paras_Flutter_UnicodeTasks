import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/models/note_model.dart';
import '../../../logic/note/note_bloc.dart';
import 'note_form_dialog.dart';
import 'note_detail_screen.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
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
                      context.read<NoteBloc>().add(SearchNotesEvent(val));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search notes by title or content...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                context
                                    .read<NoteBloc>()
                                    .add(SearchNotesEvent(''));
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
                BlocBuilder<NoteBloc, NoteState>(
                  builder: (context, state) {
                    final currentSort = state is NoteLoaded
                        ? state.sortOption
                        : NoteSortOption.dateNewest;

                    return PopupMenuButton<NoteSortOption>(
                      icon: const Icon(Icons.sort, color: AppTheme.primaryNavy),
                      tooltip: 'Sort Notes',
                      initialValue: currentSort,
                      onSelected: (option) {
                        context.read<NoteBloc>().add(SortNotesEvent(option));
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                            value: NoteSortOption.dateNewest,
                            child: Text('Date: Newest First')),
                        const PopupMenuItem(
                            value: NoteSortOption.dateOldest,
                            child: Text('Date: Oldest First')),
                        const PopupMenuItem(
                            value: NoteSortOption.alphaAZ,
                            child: Text('Alphabetical (A-Z)')),
                        const PopupMenuItem(
                            value: NoteSortOption.alphaZA,
                            child: Text('Alphabetical (Z-A)')),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<NoteBloc, NoteState>(
            builder: (context, state) {
              final currentFilter = state is NoteLoaded
                  ? state.filterOption
                  : NoteFilterOption.all;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Notes'),
                      selected: currentFilter == NoteFilterOption.all,
                      onSelected: (_) => context
                          .read<NoteBloc>()
                          .add(FilterNotesEvent(NoteFilterOption.all)),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Has Attachment'),
                      selected: currentFilter == NoteFilterOption.hasMedia,
                      onSelected: (_) => context
                          .read<NoteBloc>()
                          .add(FilterNotesEvent(NoteFilterOption.hasMedia)),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Text Only'),
                      selected: currentFilter == NoteFilterOption.textOnly,
                      onSelected: (_) => context
                          .read<NoteBloc>()
                          .add(FilterNotesEvent(NoteFilterOption.textOnly)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 12),
          Expanded(
            child: BlocBuilder<NoteBloc, NoteState>(
              builder: (context, state) {
                if (state is NoteLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is NoteLoaded) {
                  final displayNotes = state.filteredNotes;

                  if (displayNotes.isEmpty) {
                    return const Center(
                        child: Text('No matching notes found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayNotes.length,
                    itemBuilder: (context, index) {
                      final note = displayNotes[index];
                      final hasMedia =
                          note.mediaUrl != null && note.mediaUrl!.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteDetailScreen(note: note),
                              ),
                            );
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy),
                                ),
                              ),
                              if (hasMedia) ...[
                                Icon(
                                  note.mediaType == 'pdf'
                                      ? Icons.picture_as_pdf
                                      : Icons.image,
                                  size: 18,
                                  color: AppTheme.brandRed,
                                ),
                                const SizedBox(width: 4),
                              ]
                            ],
                          ),
                          subtitle: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueGrey),
                                onPressed: () =>
                                    _showEditNoteDialog(context, note),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => context
                                    .read<NoteBloc>()
                                    .add(DeleteNoteEvent(note.id)),
                              ),
                            ],
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
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.note_add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const NoteFormDialog(),
    );
  }

  void _showEditNoteDialog(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => NoteFormDialog(note: note),
    );
  }
}
