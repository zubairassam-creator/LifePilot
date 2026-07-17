import 'package:flutter/material.dart';

class ReminderResult {
  final bool isReminder;
  final String title;
  final DateTime? date;
  final TimeOfDay? time;

  const ReminderResult({
    required this.isReminder,
    this.title = '',
    this.date,
    this.time,
  });

  factory ReminderResult.notReminder() {
    return const ReminderResult(isReminder: false);
  }

  factory ReminderResult.detected({
    required String title,
    DateTime? date,
    TimeOfDay? time,
  }) {
    return ReminderResult(
      isReminder: true,
      title: title,
      date: date,
      time: time,
    );
  }
}
