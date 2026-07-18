import 'package:hive/hive.dart';

import '../models/lifepilot_task.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class TaskStorageService {
  static const String _boxName = 'tasks';

  static Box<LifePilotTask>? _box;

  /// Initialize Hive box
  static Future<void> initialize() async {
    _box ??= await Hive.openBox<LifePilotTask>(_boxName);
  }

  static Box<LifePilotTask> get _taskBox {
    if (_box == null) {
      throw Exception(
        'TaskStorageService is not initialized. '
        'Call TaskStorageService.initialize() first.',
      );
    }

    return _box!;
  }

  /// Add a new task
  static Future<void> addTask(LifePilotTask task) async {
    await _taskBox.put(task.id, task);
    await SyncService.enqueue(
      localId: task.id,
      collection: 'tasks',
      operation: 'upsert',
      payload: _taskPayload(task),
    );
  }

  /// Update an existing task
  static Future<void> updateTask(LifePilotTask task) async {
    await _taskBox.put(task.id, task);
    await SyncService.enqueue(
      localId: task.id,
      collection: 'tasks',
      operation: 'upsert',
      payload: _taskPayload(task),
    );
  }

  /// Delete task
  static Future<void> deleteTask(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task != null) {
      await NotificationService.cancelTask(task);
    }
    await _taskBox.delete(taskId);
    await SyncService.enqueue(
      localId: taskId,
      collection: 'tasks',
      operation: 'delete',
    );
  }

  /// Get task by ID
  static LifePilotTask? getTask(String taskId) {
    return _taskBox.get(taskId);
  }

  /// Watch task changes
  static Stream<void> watchTasks() {
    return _taskBox.watch().map((_) {});
  }

  /// Get all tasks
  static List<LifePilotTask> getAllTasks() {
    final tasks = _taskBox.values.toList();

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return tasks;
  }

  /// Pending tasks
  static List<LifePilotTask> getPendingTasks() {
    return getAllTasks()
        .where((task) => task.status == TaskStatus.pending)
        .toList();
  }

  /// Completed tasks
  static List<LifePilotTask> getCompletedTasks() {
    return getAllTasks()
        .where((task) => task.status == TaskStatus.completed)
        .toList();
  }

  /// Tasks due today
  static List<LifePilotTask> getTasksDueToday() {
    final now = DateTime.now();

    return getPendingTasks().where((task) {
      if (task.dueDateTime == null) return false;

      final due = task.dueDateTime!;

      return due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    }).toList();
  }

  /// Tasks by category
  static List<LifePilotTask> getTasksByCategory(String category) {
    return getAllTasks().where((task) => task.category == category).toList();
  }

  /// Number of tasks
  static int taskCount() {
    return _taskBox.length;
  }

  /// Replace all tasks
  static Future<void> replaceAllTasks(List<LifePilotTask> tasks) async {
    await _taskBox.clear();

    for (final task in tasks) {
      await _taskBox.put(task.id, task);
    }
  }

  /// Remove everything (Development only)
  static Future<void> clearAll() async {
    await _taskBox.clear();
  }

  static Map<String, dynamic> _taskPayload(LifePilotTask task) => {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'category': task.category,
    'priority': task.priority.name,
    'status': task.status.name,
    'dueDateTime': task.dueDateTime?.toIso8601String(),
    'reminderEnabled': task.reminderEnabled,
    'reminderMode': task.reminderMode.name,
    'repeatType': task.repeatType.name,
    'createdAt': task.createdAt.toIso8601String(),
    'updatedAt': task.updatedAt.toIso8601String(),
    'completedAt': task.completedAt?.toIso8601String(),
  };

  /// Close database
  static Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}
