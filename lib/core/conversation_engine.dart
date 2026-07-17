enum IntentType { reminder, document, note, contact, question, unknown }

class ConversationEngine {
  IntentType detectIntent(String text) {
    final input = text.toLowerCase().trim();

    // Reminder
    if (_containsAny(input, [
      "remind",
      "reminder",
      "remember",
      "tomorrow",
      "today",
      "next week",
      "meeting",
      "appointment",
      "alarm",
      "মনে কর",
      "মনে করিয়ে",
      "কাল",
      "আজ",
      "আগামীকাল",
      "याद",
      "कल",
    ])) {
      return IntentType.reminder;
    }

    // Document
    if (_containsAny(input, [
      "document",
      "aadhaar",
      "pan",
      "passport",
      "license",
      "certificate",
      "ডকুমেন্ট",
      "আধার",
      "প্যান",
    ])) {
      return IntentType.document;
    }

    // Note
    if (_containsAny(input, [
      "note",
      "write",
      "save this",
      "লিখে রাখ",
      "নোট",
    ])) {
      return IntentType.note;
    }

    // Contact
    if (_containsAny(input, [
      "contact",
      "phone",
      "call",
      "mobile",
      "যোগাযোগ",
      "কল",
      "ফোন",
    ])) {
      return IntentType.contact;
    }

    // Question
    if (input.endsWith("?") ||
        _containsAny(input, [
          "what",
          "when",
          "where",
          "why",
          "how",
          "কি",
          "কেন",
          "কোথায়",
          "কখন",
        ])) {
      return IntentType.question;
    }

    return IntentType.unknown;
  }

  bool _containsAny(String input, List<String> words) {
    for (final word in words) {
      if (input.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
