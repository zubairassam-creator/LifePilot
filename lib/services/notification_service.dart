import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/lifepilot_task.dart';
import '../models/reminder.dart';
import 'voice_reminder_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _spokenChannel =
      MethodChannel('lifepilot/spoken_reminders');

  static const String channelId = 'lifepilot_reminders';
  static const String channelName = 'LifePilot Reminders';
  static const String channelDescription =
      'Notifications for scheduled LifePilot reminders';

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      settings: initializationSettings,

      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? reminderTitle = response.payload;

        if (reminderTitle != null && reminderTitle.isNotEmpty) {
          await VoiceReminderService.speakReminder(reminderTitle);
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.requestExactAlarmsPermission();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    await androidPlugin?.createNotificationChannel(channel);
  }


  static int notificationIdForTask(LifePilotTask task) {
    final parsedId = int.tryParse(task.id);

    if (parsedId != null) {
      return parsedId.remainder(2147483647);
    }

    return task.id.hashCode.abs().remainder(2147483647);
  }

  static Future<void> scheduleTask(LifePilotTask task) async {
    final dueDateTime = task.dueDateTime;

    if (dueDateTime == null) {
      throw Exception('Task must have a due date to schedule a reminder.');
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day,
      dueDateTime.hour,
      dueDateTime.minute,
    );

    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      throw Exception('Reminder time must be in the future.');
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final notificationId = notificationIdForTask(task);

    await notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'LifePilot Reminder',
      body: task.title,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.title,
    );

    if (task.reminderMode == ReminderMode.speakAloud) {
      await scheduleSpokenReminder(
        id: notificationId,
        scheduledAt: dueDateTime,
        text: task.title,
      );
    }
  }

  static Future<void> cancelTask(LifePilotTask task) async {
    final notificationId = notificationIdForTask(task);
    await notificationsPlugin.cancel(id: notificationId);
    await cancelSpokenReminder(notificationId);
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.hour,
      reminder.minute,
    );

    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      throw Exception('Reminder time must be in the future.');
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.zonedSchedule(
      id: reminder.id,
      title: 'LifePilot Reminder',
      body: reminder.title,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // We now send the reminder title as the payload.
      payload: reminder.title,
    );
  }

  static Future<void> cancelReminder(int reminderId) async {
    await notificationsPlugin.cancel(id: reminderId);
    await cancelSpokenReminder(reminderId);
  }

  static Future<void> scheduleSpokenReminder({
    required int id,
    required DateTime scheduledAt,
    required String text,
  }) async {
    try {
      await _spokenChannel.invokeMethod<void>('schedule', {
        'id': id,
        'atMillis': scheduledAt.millisecondsSinceEpoch,
        'text': text,
      });
    } catch (_) {
      // Non-Android platforms keep the normal notification fallback.
    }
  }

  static Future<void> cancelSpokenReminder(int id) async {
    try {
      await _spokenChannel.invokeMethod<void>('cancel', {'id': id});
    } catch (_) {
      // Non-Android platforms keep the normal notification fallback.
    }
  }
}
