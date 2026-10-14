class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final String? base64Image;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.base64Image,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
