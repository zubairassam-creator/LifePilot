import 'package:hive/hive.dart';

import '../models/lifepilot_task.dart';

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
  }

  /// Update an existing task
  static Future<void> updateTask(LifePilotTask task) async {
    await _taskBox.put(task.id, task);
  }

  /// Delete task
  static Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
  }

  /// Get task by ID
  static LifePilotTask? getTask(String taskId) {
    return _taskBox.get(taskId);
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

  /// Remove everything (Development only)
  static Future<void> clearAll() async {
    await _taskBox.clear();
  }

  /// Close database
  static Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }
}
