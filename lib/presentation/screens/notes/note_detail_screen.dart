// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/sanitizers.dart';
import '../../../data/models/note_model.dart';
import '../../widgets/safe_latex_builder.dart';
import '../../widgets/scrollable_table_builder.dart';

class NoteDetailScreen extends StatelessWidget {
  final NoteModel note;
  const NoteDetailScreen({super.key, required this.note});

  Widget _buildMathMarkdown(BuildContext context, String text) {
    final cleanedText = sanitizeMathText(text);

    return MarkdownBody(
      data: cleanedText,
      selectable: true,
      extensionSet: md.ExtensionSet(
        [
          LatexBlockSyntax(),
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        [
          LatexInlineSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      builders: {
        'latex': SafeLatexElementBuilder(),
        'table': ScrollableTableBuilder(context),
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(
            fontSize: 16, color: AppTheme.primaryNavy, height: 1.5),
        strong: const TextStyle(
            fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        h1: const TextStyle(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 22),
        h2: const TextStyle(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = note.mediaUrl != null && note.mediaUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Created on ${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            _buildMathMarkdown(context, note.content),
            if (hasMedia) ...[
              const SizedBox(height: 24),
              const Text(
                'Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              if (note.mediaType == 'image')
                GestureDetector(
                  onTap: () => _showFullscreenImage(context, note.mediaUrl!),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          width: double.infinity,
                          child: Image.network(
                            note.mediaUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Tap to expand',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (note.mediaType == 'pdf')
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            CloudinaryService.getPdfThumbnailUrl(
                                note.mediaUrl!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.picture_as_pdf,
                                size: 60,
                                color: AppTheme.brandRed),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.fileName ?? 'Attached PDF Document',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final Uri pdfUri = Uri.parse(note.mediaUrl!);
                                try {
                                  final launched = await launchUrl(
                                    pdfUri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!launched) {
                                    await launchUrl(pdfUri,
                                        mode: LaunchMode.platformDefault);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Could not launch PDF: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open PDF'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
            ]
          ],
        ),
      ),
    );
  }
}
