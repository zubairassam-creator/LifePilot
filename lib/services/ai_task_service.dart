import 'package:flutter/material.dart';

import '../models/lifepilot_task.dart';
import 'task_storage_service.dart';

class AITaskService {
  static Future<LifePilotTask> createTask({
    required String title,
    String description = '',
    String category = 'Personal',
    DateTime? dueDateTime,
  }) async {
    final now = DateTime.now();

    final task = LifePilotTask(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      dueDateTime: dueDateTime,
      createdAt: now,
      updatedAt: now,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      reminderEnabled: dueDateTime != null,
      reminderMode: ReminderMode.normal,
      repeatType: RepeatType.none,
      isAiGenerated: true,
      aiConfidence: 1.0,
    );

    await TaskStorageService.addTask(task);

    return task;
  }
}
