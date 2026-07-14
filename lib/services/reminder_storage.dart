import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';

class ReminderStorage {
  static const String storageKey = 'lifepilot_reminders_v1';

  static Future<List<Reminder>> loadReminders() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? savedData = preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);

      return decodedData
          .map(
            (item) => Reminder.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveReminders(List<Reminder> reminders) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String encodedData = jsonEncode(
      reminders.map((item) => item.toJson()).toList(),
    );

    await preferences.setString(storageKey, encodedData);
  }
}
