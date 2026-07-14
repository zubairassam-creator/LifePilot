import 'package:flutter/material.dart';

class ParsedVoiceTask {
  final String title;

  // The actual date/time of the event or task.
  final DateTime? eventDate;
  final TimeOfDay? eventTime;

  // When LifePilot should notify the user.
  final DateTime? reminderDate;
  final TimeOfDay? reminderTime;

  // Examples: none, daily, weekly, yearly.
  final String recurrence;

  // Whether LifePilot needs more information.
  final bool needsFollowUp;

  // Question LifePilot should ask when information is missing.
  final String? followUpQuestion;

  const ParsedVoiceTask({
    required this.title,
    this.eventDate,
    this.eventTime,
    this.reminderDate,
    this.reminderTime,
    this.recurrence = 'none',
    this.needsFollowUp = false,
    this.followUpQuestion,
  });
}

class VoiceTaskParser {
  static ParsedVoiceTask parse(String spokenText) {
    String title = spokenText.trim();

    DateTime? eventDate;
    TimeOfDay? eventTime;

    DateTime? reminderDate;
    TimeOfDay? reminderTime;

    String recurrence = 'none';

    bool needsFollowUp = false;
    String? followUpQuestion;

    final DateTime now = DateTime.now();

    final bool isBirthday = RegExp(
      r'\bbirthday\b|\bbday\b|\bbirthday\b',
      caseSensitive: false,
    ).hasMatch(title);

    final bool isAnniversary = RegExp(
      r'\banniversary\b',
      caseSensitive: false,
    ).hasMatch(title);

    // TODAY
    if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(title)) {
      eventDate = DateTime(now.year, now.month, now.day);

      title = title.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '');
    }

    // TOMORROW
    if (RegExp(r'\btomorrow\b', caseSensitive: false).hasMatch(title)) {
      final DateTime tomorrow = now.add(const Duration(days: 1));

      eventDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      title = title.replaceAll(
        RegExp(r'\btomorrow\b', caseSensitive: false),
        '',
      );
    }

    // DATE SUCH AS 25 MAY / 25TH MAY
    final RegExp datePattern = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+'
      r'(january|february|march|april|may|june|july|august|'
      r'september|october|november|december)\b',
      caseSensitive: false,
    );

    final RegExpMatch? dateMatch = datePattern.firstMatch(title);

    if (dateMatch != null) {
      final int day = int.parse(dateMatch.group(1)!);

      final int month = _monthNumber(dateMatch.group(2)!);

      DateTime candidateDate = DateTime(now.year, month, day);

      // If the date already passed this year, use next year.
      if (candidateDate.isBefore(DateTime(now.year, now.month, now.day))) {
        candidateDate = DateTime(now.year + 1, month, day);
      }

      eventDate = candidateDate;

      title = title.replaceRange(dateMatch.start, dateMatch.end, '');
    }

    // TIME SUCH AS 10 AM / 10:30 PM / AT 10 AM
    final RegExp timePattern = RegExp(
      r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?)',
      caseSensitive: false,
    );
    final RegExpMatch? timeMatch = timePattern.firstMatch(title);

    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final int minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;

      final String period = timeMatch
          .group(3)!
          .toLowerCase()
          .replaceAll('.', '')
          .replaceAll(' ', '');

      if (period == 'pm' && hour != 12) {
        hour += 12;
      }

      if (period == 'am' && hour == 12) {
        hour = 0;
      }

      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        eventTime = TimeOfDay(hour: hour, minute: minute);
      }

      title = title.replaceRange(timeMatch.start, timeMatch.end, '');
    }

    // BIRTHDAYS AND ANNIVERSARIES DEFAULT TO YEARLY.
    if (isBirthday || isAnniversary) {
      recurrence = 'yearly';

      if (eventDate != null) {
        reminderDate = eventDate.subtract(const Duration(days: 1));

        // Temporary default reminder time.
        reminderTime = const TimeOfDay(hour: 9, minute: 0);
      }
    }

    // NORMAL TASK WITH DATE AND TIME.
    if (!isBirthday &&
        !isAnniversary &&
        eventDate != null &&
        eventTime != null) {
      reminderDate = eventDate;
      reminderTime = eventTime;
    }

    // ASK FOLLOW-UP WHEN DATE IS MISSING.
    if (eventDate == null) {
      needsFollowUp = true;
      followUpQuestion = 'When should I schedule this task?';
    }

    // ASK FOLLOW-UP WHEN NORMAL TASK TIME IS MISSING.
    if (!isBirthday &&
        !isAnniversary &&
        eventDate != null &&
        eventTime == null) {
      needsFollowUp = true;
      followUpQuestion = 'What time should I remind you?';
    }

    // REMOVE COMMON VOICE COMMAND WORDS.
    title = title.replaceFirst(
      RegExp(
        r'^\s*(remind me to|create task|create a task|'
        r'add task|add a task)\s+',
        caseSensitive: false,
      ),
      '',
    );

    // REMOVE COMMON CONNECTING WORDS LEFT AFTER PARSING.
    title = title.replaceAll(
      RegExp(r'\b(is on|on|at)\b', caseSensitive: false),
      ' ',
    );

    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedVoiceTask(
      title: title,
      eventDate: eventDate,
      eventTime: eventTime,
      reminderDate: reminderDate,
      reminderTime: reminderTime,
      recurrence: recurrence,
      needsFollowUp: needsFollowUp,
      followUpQuestion: followUpQuestion,
    );
  }

  static int _monthNumber(String monthName) {
    const List<String> months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];

    return months.indexOf(monthName.toLowerCase()) + 1;
  }
}
