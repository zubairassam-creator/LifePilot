import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import 'voice_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
          await VoiceService.speak('Reminder. $reminderTitle');
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
  }
}
