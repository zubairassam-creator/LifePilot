class MemoryEngine {
  final List<String> _conversation = [];

  void addUserMessage(String message) {
    _conversation.add("USER: $message");
  }

  void addAssistantMessage(String message) {
    _conversation.add("AI: $message");
  }

  void remember(String item) {
    _conversation.add("MEMORY: $item");
  }

  List<String> recall() {
    return List.unmodifiable(_conversation);
  }

  String? lastUserMessage() {
    for (int i = _conversation.length - 1; i >= 0; i--) {
      if (_conversation[i].startsWith("USER: ")) {
        return _conversation[i].substring(6);
      }
    }
    return null;
  }

  void forgetAll() {
    _conversation.clear();
  }
}
