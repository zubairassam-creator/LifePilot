import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'lifepilot_task.g.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0)
  low,

  @HiveField(1)
  normal,

  @HiveField(2)
  high,

  @HiveField(3)
  critical,
}

@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  completed,

  @HiveField(2)
  archived,
}

@HiveType(typeId: 2)
enum ReminderMode {
  @HiveField(0)
  silent,

  @HiveField(1)
  normal,

  @HiveField(2)
  speakAloud,
}

@HiveType(typeId: 3)
enum RepeatType {
  @HiveField(0)
  none,

  @HiveField(1)
  daily,

  @HiveField(2)
  weekly,

  @HiveField(3)
  monthly,

  @HiveField(4)
  yearly,
}

@HiveType(typeId: 4)
@immutable
class LifePilotTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final TaskPriority priority;

  @HiveField(5)
  final TaskStatus status;

  @HiveField(6)
  final DateTime? dueDateTime;

  @HiveField(7)
  final bool reminderEnabled;

  @HiveField(8)
  final ReminderMode reminderMode;

  @HiveField(9)
  final RepeatType repeatType;

  @HiveField(10)
  final bool isPinned;

  @HiveField(11)
  final bool isAiGenerated;

  @HiveField(12)
  final double aiConfidence;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  @HiveField(15)
  final DateTime? completedAt;

  LifePilotTask({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.pending,
    this.dueDateTime,
    this.reminderEnabled = true,
    this.reminderMode = ReminderMode.normal,
    this.repeatType = RepeatType.none,
    this.isPinned = false,
    this.isAiGenerated = false,
    this.aiConfidence = 1.0,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  LifePilotTask copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDateTime,
    bool? reminderEnabled,
    ReminderMode? reminderMode,
    RepeatType? repeatType,
    bool? isPinned,
    bool? isAiGenerated,
    double? aiConfidence,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return LifePilotTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDateTime: dueDateTime ?? this.dueDateTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMode: reminderMode ?? this.reminderMode,
      repeatType: repeatType ?? this.repeatType,
      isPinned: isPinned ?? this.isPinned,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
