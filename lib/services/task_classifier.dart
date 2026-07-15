class TaskClassifier {
  static String classify(String text) {
    final input = text.toLowerCase();

    if (input.contains('birthday') ||
        input.contains("b'day") ||
        input.contains('birth day')) {
      return 'Birthday';
    }

    if (input.contains('pollution') ||
        input.contains('insurance') ||
        input.contains('passport') ||
        input.contains('driving licence') ||
        input.contains('driving license') ||
        input.contains('aadhaar') ||
        input.contains('pan')) {
      return 'Expiry';
    }

    if (input.contains('bill') ||
        input.contains('electricity') ||
        input.contains('water bill')) {
      return 'Bill';
    }

    if (input.contains('doctor') ||
        input.contains('hospital') ||
        input.contains('appointment')) {
      return 'Appointment';
    }

    if (input.contains('meeting')) {
      return 'Meeting';
    }

    if (input.contains('shopping') || input.contains('buy')) {
      return 'Shopping';
    }

    return 'General';
  }
}
