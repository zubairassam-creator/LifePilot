import '../models/reminder.dart';
import 'task_storage_service.dart';
import 'reminder_mapper.dart';

class ReminderStorage {
  /// Load all reminders from Hive
  static Future<List<Reminder>> loadReminders() async {
    final tasks = TaskStorageService.getAllTasks();

    return tasks.map((task) => ReminderMapper.fromTask(task)).toList();
  }

  /// Save all reminders to Hive
  static Future<void> saveReminders(List<Reminder> reminders) async {
    final tasks = reminders
        .map((reminder) => ReminderMapper.toTask(reminder))
        .toList();

    await TaskStorageService.replaceAllTasks(tasks);
  }

  /// Add one reminder
  static Future<void> addReminder(Reminder reminder) async {
    await TaskStorageService.addTask(ReminderMapper.toTask(reminder));
  }

  /// Update one reminder
  static Future<void> updateReminder(Reminder reminder) async {
    await TaskStorageService.updateTask(ReminderMapper.toTask(reminder));
  }

  /// Delete one reminder
  static Future<void> deleteReminder(String reminderId) async {
    await TaskStorageService.deleteTask(reminderId);
  }
}
