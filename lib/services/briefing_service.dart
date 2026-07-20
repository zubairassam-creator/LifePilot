import 'dart:developer' as developer;

import '../models/life_memory.dart';
import '../models/lifepilot_task.dart';
import 'life_memory_repository.dart';
import 'task_storage_service.dart';

class BriefingData {
  const BriefingData({
    this.overdue = const [],
    this.today = const [],
    this.upcoming = const [],
    this.expiringSoon = const [],
    this.birthdaysAndEvents = const [],
    this.openLoans = const [],
    this.hasFailures = false,
    this.allFailed = false,
  });

  final List<LifePilotTask> overdue;
  final List<LifePilotTask> today;
  final List<LifePilotTask> upcoming;
  final List<LifeMemory> expiringSoon;
  final List<LifeMemory> birthdaysAndEvents;
  final List<LifeMemory> openLoans;
  final bool hasFailures;
  final bool allFailed;

  bool get isEmpty =>
      overdue.isEmpty &&
      today.isEmpty &&
      upcoming.isEmpty &&
      expiringSoon.isEmpty &&
      birthdaysAndEvents.isEmpty &&
      openLoans.isEmpty;
}

class BriefingService {
  static Future<BriefingData> loadTodayBriefing() async {
    var hasFailures = false;
    var taskSourceFailed = false;
    var memorySourceFailed = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final upcomingLimit = today.add(const Duration(days: 8));
    final expiryLimit = today.add(const Duration(days: 45));

    List<LifePilotTask> overdue = [];
    List<LifePilotTask> todayTasks = [];
    List<LifePilotTask> upcoming = [];
    List<LifeMemory> expiringSoon = [];
    List<LifeMemory> birthdaysAndEvents = [];
    List<LifeMemory> openLoans = [];

    try {
      final tasks = TaskStorageService.getAllTasks();
      overdue = tasks
          .where((task) =>
              task.status != TaskStatus.completed &&
              task.dueDateTime != null &&
              task.dueDateTime!.isBefore(now))
          .toList();
      todayTasks = tasks
          .where((task) =>
              task.status == TaskStatus.pending &&
              task.dueDateTime != null &&
              _isSameDay(task.dueDateTime!, today))
          .toList();
      upcoming = tasks
          .where((task) =>
              task.status == TaskStatus.pending &&
              task.dueDateTime != null &&
              !task.dueDateTime!.isBefore(tomorrow) &&
              task.dueDateTime!.isBefore(upcomingLimit))
          .toList();
      _sortTasks(overdue);
      _sortTasks(todayTasks);
      _sortTasks(upcoming);
    } catch (error, stackTrace) {
      hasFailures = true;
      taskSourceFailed = true;
      developer.log('Failed to load task briefing data', error: error, stackTrace: stackTrace);
    }

    try {
      final memories = LifeMemoryRepository.getAll();
      expiringSoon = memories
          .where((memory) =>
              memory.type == LifeMemoryType.expiry &&
              memory.dueDate != null &&
              !memory.dueDate!.isBefore(today) &&
              memory.dueDate!.isBefore(expiryLimit))
          .toList();
      birthdaysAndEvents = memories
          .where((memory) =>
              (memory.type == LifeMemoryType.birthday || memory.type == LifeMemoryType.event) &&
              memory.eventDate != null &&
              _occursInNextDays(memory.eventDate!, today, 14))
          .toList();
      openLoans = memories
          .where((memory) => memory.type == LifeMemoryType.loanTaken && memory.status == LifeMemoryStatus.open)
          .toList();
      _sortMemoriesByDate(expiringSoon, (memory) => memory.dueDate);
      _sortMemoriesByDate(birthdaysAndEvents, (memory) => _nextOccurrence(memory.eventDate!, today));
      _sortMemoriesByDate(openLoans, (memory) => memory.dueDate);
    } catch (error, stackTrace) {
      hasFailures = true;
      memorySourceFailed = true;
      developer.log('Failed to load memory briefing data', error: error, stackTrace: stackTrace);
    }

    return BriefingData(
      overdue: overdue,
      today: todayTasks,
      upcoming: upcoming,
      expiringSoon: expiringSoon,
      birthdaysAndEvents: birthdaysAndEvents,
      openLoans: openLoans,
      hasFailures: hasFailures,
      allFailed: taskSourceFailed && memorySourceFailed,
    );
  }

  static String buildSpokenBriefing(BriefingData data) {
    final greeting = greetingFor(DateTime.now());
    if (data.allFailed) return '$greeting. I could not load your briefing right now. Please try again.';
    if (data.isEmpty) return '$greeting. Here is your briefing for today. You are all caught up today.';

    final parts = <String>['$greeting. Here is your briefing for today.'];
    parts.add('You have ${_taskCountPhrase(data.overdue.length, 'overdue')} and ${_scheduledTodayPhrase(data.today.length)}.');
    if (data.overdue.isNotEmpty) parts.add('Your overdue ${_itemWord(data.overdue.length)} ${_isAre(data.overdue.length)} ${_join(data.overdue.map((task) => task.title))}.');
    if (data.today.isNotEmpty) parts.add('Today, you need to ${_join(data.today.map(_taskSpokenDetail))}.');
    if (data.upcoming.isNotEmpty) parts.add('Coming up soon, you have ${_join(data.upcoming.map(_taskSpokenDetail))}.');
    if (data.expiringSoon.isNotEmpty) parts.add('Expiring soon: ${_join(data.expiringSoon.map(_memorySpokenDetail))}.');
    if (data.birthdaysAndEvents.isNotEmpty) parts.add('Birthdays and events: ${_join(data.birthdaysAndEvents.map(_memorySpokenDetail))}.');
    if (data.openLoans.isNotEmpty) parts.add('Open loans: ${_join(data.openLoans.map(_loanSpokenDetail))}.');
    final emptyMemorySections = [data.expiringSoon, data.birthdaysAndEvents, data.openLoans].where((items) => items.isEmpty).length;
    if (emptyMemorySections == 3) parts.add('You have no upcoming expiries, birthdays, events, or open loans.');
    return parts.join(' ');
  }

  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  static void _sortTasks(List<LifePilotTask> tasks) => tasks.sort((a, b) => (a.dueDateTime ?? a.createdAt).compareTo(b.dueDateTime ?? b.createdAt));
  static void _sortMemoriesByDate(List<LifeMemory> memories, DateTime? Function(LifeMemory) date) => memories.sort((a, b) => (date(a) ?? a.updatedAt).compareTo(date(b) ?? b.updatedAt));
  static bool _occursInNextDays(DateTime eventDate, DateTime today, int days) => !_nextOccurrence(eventDate, today).isBefore(today) && _nextOccurrence(eventDate, today).isBefore(today.add(Duration(days: days + 1)));
  static DateTime _nextOccurrence(DateTime date, DateTime today) { final occurrence = DateTime(today.year, date.month, date.day); return occurrence.isBefore(today) ? DateTime(today.year + 1, date.month, date.day) : occurrence; }
  static String _taskSpokenDetail(LifePilotTask task) => task.dueDateTime == null ? task.title : '${task.title} at ${_formatTime(task.dueDateTime!)}';
  static String _memorySpokenDetail(LifeMemory memory) => memory.dueDate == null && memory.eventDate == null ? memory.title : '${memory.title} on ${_formatDate(memory.dueDate ?? memory.eventDate!)}';
  static String _loanSpokenDetail(LifeMemory memory) => '${memory.currency ?? ''}${_formatAmount(memory.amount)} from ${memory.person ?? memory.title}${memory.dueDate == null ? '' : ', due ${_formatDate(memory.dueDate!)}'}';
  static String _taskCountPhrase(int count, String label) => count == 0 ? 'no $label tasks' : count == 1 ? 'one $label task' : '$count $label tasks';
  static String _scheduledTodayPhrase(int count) => count == 0 ? 'no tasks scheduled for today' : count == 1 ? 'one task scheduled for today' : '$count tasks scheduled for today';
  static String _itemWord(int count) => count == 1 ? 'task' : 'tasks';
  static String _isAre(int count) => count == 1 ? 'is' : 'are';
  static String _join(Iterable<String> items) { final list = items.where((item) => item.trim().isNotEmpty).toList(); if (list.length <= 1) return list.join(); return '${list.take(list.length - 1).join(', ')} and ${list.last}'; }
  static String _formatAmount(double? amount) => amount == null ? '' : amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  static String _formatDate(DateTime date) => '${date.day} ${_month(date.month)}';
  static String _formatTime(DateTime date) { final hour = date.hour % 12 == 0 ? 12 : date.hour % 12; final minute = date.minute == 0 ? '' : ':${date.minute.toString().padLeft(2, '0')}'; final suffix = date.hour >= 12 ? 'PM' : 'AM'; return '$hour$minute $suffix'; }
  static String _month(int month) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month];
}
