import '../models/reminder_result.dart';

class IntentEngine {
  const IntentEngine();

  ReminderResult analyze(String input) {
    final String text = input.trim().toLowerCase();

    if (text.startsWith('remind me')) {
      return ReminderResult.detected(title: input.substring(9).trim());
    }

    return ReminderResult.notReminder();
  }
}
