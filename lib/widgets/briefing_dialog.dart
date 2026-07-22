import 'package:flutter/material.dart';

import '../models/lifepilot_task.dart';
import '../services/task_storage_service.dart';
import '../services/voice_service.dart';

enum BriefingDialogMode { daily, schedule }

Future<void> showBriefingDialog(
  BuildContext context, {
  BriefingDialogMode mode = BriefingDialogMode.daily,
  bool speakAutomatically = false,
}) async {
  final briefing = _TodayBriefing.fromTasks(TaskStorageService.getAllTasks());
  final spokenBriefing = _buildSpokenBriefing(briefing, mode);

  if (speakAutomatically) {
    await VoiceService.speak(spokenBriefing);
  }

  try {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Today's Briefing"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatFullDate(briefing.now),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(_introText(briefing, mode)),
              const SizedBox(height: 16),
              _BriefingMetricRow(
                icon: Icons.today_outlined,
                label: 'Tasks due today',
                value: briefing.dueToday.length.toString(),
              ),
              _BriefingMetricRow(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: briefing.completedToday.length.toString(),
              ),
              _BriefingMetricRow(
                icon: Icons.pending_actions_outlined,
                label: 'Pending',
                value: briefing.pendingToday.length.toString(),
              ),
              _BriefingMetricRow(
                icon: Icons.warning_amber_outlined,
                label: 'Missed',
                value: briefing.missed.length.toString(),
              ),
              if (briefing.dueToday.isEmpty && briefing.missed.isEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'No tasks exist for today. You are clear to plan your next priority.',
                ),
              ] else ...[
                const SizedBox(height: 16),
                _TaskSection(
                  title: 'Pending today',
                  tasks: briefing.pendingToday,
                ),
                _TaskSection(
                  title: 'Completed today',
                  tasks: briefing.completedToday,
                ),
                _TaskSection(title: 'Missed tasks', tasks: briefing.missed),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } finally {
    await VoiceService.stop();
  }
}

class _TodayBriefing {
  _TodayBriefing({
    required this.now,
    required this.dueToday,
    required this.completedToday,
    required this.pendingToday,
    required this.missed,
  });

  final DateTime now;
  final List<LifePilotTask> dueToday;
  final List<LifePilotTask> completedToday;
  final List<LifePilotTask> pendingToday;
  final List<LifePilotTask> missed;

  factory _TodayBriefing.fromTasks(List<LifePilotTask> tasks) {
    final now = DateTime.now();
    final dueToday = tasks.where((task) => _isDueToday(task, now)).toList()
      ..sort(_compareTasks);
    final completedToday = dueToday
        .where((task) => task.status == TaskStatus.completed)
        .toList();
    final pendingToday = dueToday
        .where((task) => task.status == TaskStatus.pending)
        .toList();
    final missed =
        tasks
            .where(
              (task) =>
                  task.status != TaskStatus.completed &&
                  task.dueDateTime != null &&
                  task.dueDateTime!.isBefore(now),
            )
            .toList()
          ..sort(_compareTasks);

    return _TodayBriefing(
      now: now,
      dueToday: dueToday,
      completedToday: completedToday,
      pendingToday: pendingToday,
      missed: missed,
    );
  }
}

class _BriefingMetricRow extends StatelessWidget {
  const _BriefingMetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({required this.title, required this.tasks});

  final String title;
  final List<LifePilotTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${_taskSummary(task)}'),
            ),
          ),
        ],
      ),
    );
  }
}

String _introText(_TodayBriefing briefing, BriefingDialogMode mode) {
  if (mode == BriefingDialogMode.schedule) {
    if (briefing.pendingToday.isEmpty && briefing.missed.isEmpty) {
      return 'Your schedule is clear for today.';
    }
    return 'Here is your schedule-focused briefing for today.';
  }

  return 'Here is a concise overview of your day.';
}

String _buildSpokenBriefing(_TodayBriefing briefing, BriefingDialogMode mode) {
  final parts = <String>[
    mode == BriefingDialogMode.schedule
        ? 'Here is your schedule-focused briefing for today.'
        : "Here is today's briefing.",
    'Today is ${_formatFullDate(briefing.now)}.',
    'You have ${briefing.dueToday.length} tasks due today, '
        '${briefing.completedToday.length} completed, '
        '${briefing.pendingToday.length} pending, and '
        '${briefing.missed.length} missed.',
  ];

  if (briefing.dueToday.isEmpty && briefing.missed.isEmpty) {
    parts.add(
      'No tasks exist for today. You are clear to plan your next priority.',
    );
  } else if (mode == BriefingDialogMode.schedule &&
      briefing.pendingToday.isNotEmpty) {
    parts.add(
      'Your pending schedule is ${_join(briefing.pendingToday.map(_taskSummary))}.',
    );
  }

  return parts.join(' ');
}

String _taskSummary(LifePilotTask task) {
  final dueDateTime = task.dueDateTime;
  if (dueDateTime == null) return task.title;
  return '${task.title} at ${_formatTime(dueDateTime)}';
}

bool _isDueToday(LifePilotTask task, DateTime now) {
  final dueDateTime = task.dueDateTime;
  if (dueDateTime == null) return false;
  return dueDateTime.year == now.year &&
      dueDateTime.month == now.month &&
      dueDateTime.day == now.day;
}

int _compareTasks(LifePilotTask a, LifePilotTask b) {
  return (a.dueDateTime ?? a.createdAt).compareTo(b.dueDateTime ?? b.createdAt);
}

String _formatFullDate(DateTime date) {
  return '${_weekday(date.weekday)}, ${_month(date.month)} ${date.day}, ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _join(Iterable<String> items) {
  final list = items.where((item) => item.trim().isNotEmpty).toList();
  if (list.length <= 1) return list.join();
  return '${list.take(list.length - 1).join(', ')} and ${list.last}';
}

String _weekday(int weekday) {
  return const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
}

String _month(int month) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
