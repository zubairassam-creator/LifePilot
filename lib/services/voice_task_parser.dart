import 'package:flutter/material.dart';

class ParsedVoiceTask {
  final String title;
  final DateTime? date;
  final TimeOfDay? time;

  const ParsedVoiceTask({required this.title, this.date, this.time});
}

class VoiceTaskParser {
  static ParsedVoiceTask parse(String spokenText) {
    String title = spokenText.trim();
    DateTime? date;
    TimeOfDay? time;

    final DateTime now = DateTime.now();

    // Detect "today".
    if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(title)) {
      date = DateTime(now.year, now.month, now.day);

      title = title.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '');
    }

    // Detect "tomorrow".
    if (RegExp(r'\btomorrow\b', caseSensitive: false).hasMatch(title)) {
      final DateTime tomorrow = now.add(const Duration(days: 1));

      date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      title = title.replaceAll(
        RegExp(r'\btomorrow\b', caseSensitive: false),
        '',
      );
    }

    // Detect times such as:
    // 10 AM
    // 10:30 AM
    // at 10 AM
    final RegExp timePattern = RegExp(
      r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );

    final RegExpMatch? timeMatch = timePattern.firstMatch(title);

    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final int minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final String period = timeMatch.group(3)!.toLowerCase();

      if (period == 'pm' && hour != 12) {
        hour += 12;
      }

      if (period == 'am' && hour == 12) {
        hour = 0;
      }

      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        time = TimeOfDay(hour: hour, minute: minute);
      }

      title = title.replaceRange(timeMatch.start, timeMatch.end, '');
    }

    // Remove common voice-command words from the beginning.
    title = title.replaceFirst(
      RegExp(
        r'^\s*(remind me to|create task|create a task|add task|add a task)\s+',
        caseSensitive: false,
      ),
      '',
    );

    // Remove extra spaces left after parsing.
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedVoiceTask(title: title, date: date, time: time);
  }
}
