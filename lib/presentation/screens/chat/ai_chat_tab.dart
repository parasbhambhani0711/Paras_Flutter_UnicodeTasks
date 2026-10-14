import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/sanitizers.dart';
import '../../../logic/chat/chat_bloc.dart';
import '../../widgets/safe_latex_builder.dart';
import '../../widgets/scrollable_table_builder.dart';

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _base64Image;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.brandRed),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.primaryNavy),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final textPrompt = _msgController.text.trim();
    if (textPrompt.isEmpty && _selectedImage == null) return;

    context.read<ChatBloc>().add(
          SendMessageEvent(
            textPrompt.isNotEmpty ? textPrompt : 'Attached image query',
            imagePath: _selectedImage?.path,
            base64Image: _base64Image,
          ),
        );

    setState(() {
      _msgController.clear();
      _selectedImage = null;
      _base64Image = null;
    });
  }

  Widget _buildSmartMarkdown(String text) {
    final cleanedText = sanitizeAiResponse(text);

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
            fontSize: 14, color: AppTheme.primaryNavy, height: 1.4),
        strong: const TextStyle(
            fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        h1: const TextStyle(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18),
        h2: const TextStyle(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatStateData) {
            _scrollToBottom();
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
            }
          }
        },
        builder: (context, state) {
          final chatData = state as ChatStateData;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatData.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatData.messages[index];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? AppTheme.primaryNavy
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.imagePath != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(msg.imagePath!),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            msg.isUser
                                ? Text(
                                    msg.text,
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : _buildSmartMarkdown(msg.text),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (chatData.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.brandRed)),
                      SizedBox(width: 10),
                      Text('Astra AI Agent is operating...'),
                    ],
                  ),
                ),
              if (_selectedImage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImage = null;
                                _base64Image = null;
                              }),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Image attached! Add your comment or doubt below.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.primaryNavy),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_a_photo,
                          color: AppTheme.brandRed),
                      onPressed: _showImageSourcePicker,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIvory,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _msgController,
                          maxLines: 5,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                              color: AppTheme.primaryNavy, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Add comment or ask doubt...',
                            hintStyle:
                                TextStyle(color: Colors.black38, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.brandRed,
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
