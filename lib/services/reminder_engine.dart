import '../models/reminder.dart';
import 'notification_service.dart';
import 'reminder_storage.dart';

class ReminderEngine {
  /// Create a new reminder
  static Future<void> create({
    required Reminder reminder,
    required List<Reminder> reminderList,
  }) async {
    reminderList.add(reminder);

    await ReminderStorage.saveReminders(reminderList);

    await NotificationService.scheduleReminder(reminder);

    // Reserved for future voice scheduling
    switch (reminder.notificationMode) {
      case NotificationMode.normal:
        break;

      case NotificationMode.speak:
        break;

      case NotificationMode.repeatSpeak:
        break;

      case NotificationMode.silent:
        break;
    }
  }

  /// Update reminder
  static Future<void> update({
    required Reminder oldReminder,
    required Reminder newReminder,
    required List<Reminder> reminderList,
  }) async {
    final index = reminderList.indexWhere((r) => r.id == oldReminder.id);

    if (index == -1) return;

    await NotificationService.cancelReminder(oldReminder.id);

    reminderList[index] = newReminder;

    await ReminderStorage.saveReminders(reminderList);

    await NotificationService.scheduleReminder(newReminder);
  }

  /// Delete reminder
  static Future<void> delete({
    required Reminder reminder,
    required List<Reminder> reminderList,
  }) async {
    reminderList.removeWhere((r) => r.id == reminder.id);

    await ReminderStorage.saveReminders(reminderList);

    await NotificationService.cancelReminder(reminder.id);
  }

  /// Mark completed
  static Future<void> markCompleted({
    required Reminder reminder,
    required List<Reminder> reminderList,
    required bool completed,
  }) async {
    reminder.isCompleted = completed;

    await ReminderStorage.saveReminders(reminderList);

    if (completed) {
      await NotificationService.cancelReminder(reminder.id);
    } else {
      await NotificationService.scheduleReminder(reminder);
    }
  }
}
