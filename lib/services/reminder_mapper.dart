import '../models/lifepilot_task.dart';
import '../models/reminder.dart';

class ReminderMapper {
  static LifePilotTask toTask(Reminder reminder) {
    return LifePilotTask(
      id: reminder.id.toString(),
      title: reminder.title,
      description: '',
      category: 'Personal',
      priority: _toTaskPriority(reminder.priority),
      status: reminder.isCompleted ? TaskStatus.completed : TaskStatus.pending,
      dueDateTime: reminder.scheduledDateTime,
      reminderEnabled: true,
      reminderMode: _toReminderMode(reminder.notificationMode),
      repeatType: RepeatType.none,
      isPinned: false,
      isAiGenerated: false,
      aiConfidence: 1.0,
      createdAt: reminder.scheduledDateTime,
      updatedAt: DateTime.now(),
      completedAt: reminder.isCompleted ? DateTime.now() : null,
    );
  }

  static Reminder fromTask(LifePilotTask task) {
    final due = task.dueDateTime ?? DateTime.now();

    return Reminder(
      id: int.tryParse(task.id) ?? DateTime.now().millisecondsSinceEpoch,
      title: task.title,
      date: DateTime(due.year, due.month, due.day),
      hour: due.hour,
      minute: due.minute,
      priority: _priorityString(task.priority),
      notificationMode: _notificationMode(task.reminderMode),
      isCompleted: task.status == TaskStatus.completed,
    );
  }

  static TaskPriority _toTaskPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'critical':
        return TaskPriority.critical;
      default:
        return TaskPriority.normal;
    }
  }

  static String _priorityString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
      case TaskPriority.normal:
        return 'Medium';
    }
  }

  static ReminderMode _toReminderMode(NotificationMode mode) {
    switch (mode) {
      case NotificationMode.silent:
        return ReminderMode.silent;

      case NotificationMode.speak:
      case NotificationMode.repeatSpeak:
        return ReminderMode.speakAloud;

      case NotificationMode.normal:
        return ReminderMode.normal;
    }
  }

  static NotificationMode _notificationMode(ReminderMode mode) {
    switch (mode) {
      case ReminderMode.silent:
        return NotificationMode.silent;

      case ReminderMode.speakAloud:
        return NotificationMode.speak;

      case ReminderMode.normal:
        return NotificationMode.normal;
    }
  }
}
