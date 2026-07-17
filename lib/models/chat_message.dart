enum MessageSender { user, assistant }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime time;

  ChatMessage({required this.text, required this.sender, DateTime? time})
    : time = time ?? DateTime.now();
}
