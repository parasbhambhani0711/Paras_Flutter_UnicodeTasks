// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../data/models/note_model.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../logic/note/note_bloc.dart';

class NoteFormDialog extends StatefulWidget {
  final NoteModel? note;
  const NoteFormDialog({super.key, this.note});

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;

  File? _attachedFile;
  String? _mediaType;
  String? _fileName;
  String? _existingMediaUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _mediaType = widget.note?.mediaType;
    _fileName = widget.note?.fileName;
    _existingMediaUrl = widget.note?.mediaUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _attachedFile = File(image.path);
        _mediaType = 'image';
        _fileName = image.name;
        _existingMediaUrl = null;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.isNotEmpty && result.first.path != null) {
      setState(() {
        _attachedFile = File(result.first.path!);
        _mediaType = 'pdf';
        _fileName = result.first.name;
        _existingMediaUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final hasAttachment = _attachedFile != null ||
        (_existingMediaUrl != null && _existingMediaUrl!.isNotEmpty);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Note' : 'Add Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Content (Supports LaTeX & Markdown)')),
            const SizedBox(height: 16),
            const Text(
              'Attach Media (Cloudinary)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Image'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
              ],
            ),
            if (hasAttachment) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _mediaType == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.insert_drive_file,
                      color: AppTheme.brandRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName ?? widget.note?.fileName ?? 'Attached File',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _attachedFile = null;
                          _mediaType = null;
                          _fileName = null;
                          _existingMediaUrl = null;
                        });
                      },
                    )
                  ],
                ),
              )
            ],
            if (_isUploading) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Uploading to Cloudinary...',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _isUploading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isUploading
              ? null
              : () async {
                  final title = _titleCtrl.text.trim();
                  final content = _contentCtrl.text.trim();
                  if (title.isEmpty) return;

                  String? uploadedUrl = _existingMediaUrl;
                  String? finalMediaType = _mediaType;
                  String? finalFileName = _fileName;

                  if (_attachedFile != null && _mediaType != null) {
                    setState(() => _isUploading = true);
                    final uploadResult = await CloudinaryService.uploadFile(
                        _attachedFile!, _mediaType!);

                    if (uploadResult != null) {
                      uploadedUrl = uploadResult['secure_url'];
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Cloudinary Upload Failed')),
                      );
                      setState(() => _isUploading = false);
                      return;
                    }
                  }

                  if (isEditing) {
                    context.read<FirestoreRepository>().updateNote(
                          widget.note!.id,
                          title,
                          content,
                          mediaUrl: uploadedUrl,
                          mediaType: finalMediaType,
                          fileName: finalFileName,
                        );
                  } else {
                    context.read<NoteBloc>().add(AddNoteEvent(
                          title,
                          content,
                          mediaUrl: uploadedUrl,
                          mediaType: finalMediaType,
                          fileName: finalFileName,
                        ));
                  }

                  Navigator.pop(context);
                },
          child: Text(isEditing ? 'Save Changes' : 'Save Note'),
        )
      ],
    );
  }
}
