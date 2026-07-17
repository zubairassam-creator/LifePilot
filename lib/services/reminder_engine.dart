import '../models/reminder.dart';
import '../models/reminder_result.dart';
import 'notification_service.dart';
import 'reminder_storage.dart';

class ReminderEngine {
  /// Creates a reminder, saves it, and schedules its notification.
  static Future<void> create({
    required Reminder reminder,
    required List<Reminder> reminderList,
  }) async {
    reminderList.add(reminder);

    await ReminderStorage.saveReminders(reminderList);

    await NotificationService.scheduleReminder(reminder);
  }

  /// Detects whether the user's input is asking for a reminder.
  ReminderResult analyze(String input) {
    final String text = input.toLowerCase().trim();

    if (text.startsWith('remind me')) {
      return ReminderResult.detected(title: input.substring(9).trim());
    }

    return ReminderResult.notReminder();
  }
}
