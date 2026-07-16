import 'package:flutter/material.dart';

enum NotificationMode { normal, speak, repeatSpeak, silent }

class Reminder {
  final int id;
  final String title;
  final DateTime date;
  final int hour;
  final int minute;
  final String priority;

  final NotificationMode notificationMode;

  bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.hour,
    required this.minute,
    required this.priority,
    this.notificationMode = NotificationMode.normal,
    this.isCompleted = false,
  });

  TimeOfDay get time {
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime get scheduledDateTime {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool get isMissed {
    return !isCompleted && scheduledDateTime.isBefore(DateTime.now());
  }

  Reminder copyWith({
    int? id,
    String? title,
    DateTime? date,
    int? hour,
    int? minute,
    String? priority,
    NotificationMode? notificationMode,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      priority: priority ?? this.priority,
      notificationMode: notificationMode ?? this.notificationMode,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hour': hour,
      'minute': minute,
      'priority': priority,
      'notificationMode': notificationMode.name,
      'isCompleted': isCompleted,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    NotificationMode mode = NotificationMode.normal;

    final String? modeString = json['notificationMode'] as String?;

    switch (modeString) {
      case 'speak':
        mode = NotificationMode.speak;
        break;

      case 'repeatSpeak':
        mode = NotificationMode.repeatSpeak;
        break;

      case 'silent':
        mode = NotificationMode.silent;
        break;

      default:
        mode = NotificationMode.normal;
    }

    return Reminder(
      id:
          json['id'] as int? ??
          DateTime.now().microsecondsSinceEpoch.remainder(2147483647),
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      priority: json['priority'] as String,
      notificationMode: mode,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
