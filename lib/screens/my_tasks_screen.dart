import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lifepilot_task.dart';
import '../services/notification_service.dart';
import '../services/task_storage_service.dart';
import '../services/voice_service.dart';
import 'reminder_form_screen.dart';

enum ReminderFilter { all, today, upcoming, missed, completed }

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  final List<LifePilotTask> tasks = [];
  ReminderFilter selectedFilter = ReminderFilter.all;
  bool isLoading = true;
  StreamSubscription<void>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    loadSavedTasks();
    _taskSubscription = TaskStorageService.watchTasks().listen((_) {
      loadSavedTasks();
    });
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadSavedTasks() async {
    final savedTasks = TaskStorageService.getAllTasks();

    if (!mounted) return;

    setState(() {
      tasks
        ..clear()
        ..addAll(savedTasks);
      isLoading = false;
    });
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool isMissed(LifePilotTask task) {
    return task.status != TaskStatus.completed &&
        task.dueDateTime != null &&
        task.dueDateTime!.isBefore(DateTime.now());
  }

  List<LifePilotTask> get filteredTasks {
    final now = DateTime.now();
    final List<LifePilotTask> result;

    switch (selectedFilter) {
      case ReminderFilter.all:
        result = List<LifePilotTask>.from(tasks);
      case ReminderFilter.today:
        result = tasks.where((task) {
          final due = task.dueDateTime;
          return task.status == TaskStatus.pending &&
              due != null &&
              !isMissed(task) &&
              isSameDay(due, now);
        }).toList();
      case ReminderFilter.upcoming:
        result = tasks.where((task) {
          final due = task.dueDateTime;
          return task.status == TaskStatus.pending &&
              due != null &&
              due.isAfter(now);
        }).toList();
      case ReminderFilter.missed:
        result = tasks.where(isMissed).toList();
      case ReminderFilter.completed:
        result = tasks
            .where((task) => task.status == TaskStatus.completed)
            .toList();
    }

    result.sort((first, second) {
      final firstDue = first.dueDateTime ?? first.createdAt;
      final secondDue = second.dueDateTime ?? second.createdAt;
      return firstDue.compareTo(secondDue);
    });

    return result;
  }

  Future<void> createTask() async {
    await VoiceService.speak('Please tell me the reminder');

    if (!mounted) return;

    final newTask = await Navigator.push<LifePilotTask>(
      context,
      MaterialPageRoute(
        builder: (context) => const ReminderFormScreen(voiceMode: true),
      ),
    );

    if (newTask == null) return;

    try {
      await TaskStorageService.addTask(newTask);
      if (newTask.reminderEnabled && newTask.dueDateTime != null) {
        await NotificationService.scheduleTask(newTask);
      }
      await loadSavedTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder saved and notification scheduled.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not schedule notification. Please check permissions and choose a future time.',
          ),
        ),
      );
    }
  }

  Future<void> editTask(LifePilotTask oldTask) async {
    final updatedTask = await Navigator.push<LifePilotTask>(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderFormScreen(existingTask: oldTask),
      ),
    );

    if (updatedTask == null) return;

    try {
      await NotificationService.cancelTask(oldTask);
      if (updatedTask.reminderEnabled && updatedTask.dueDateTime != null) {
        await NotificationService.scheduleTask(updatedTask);
      }
      await TaskStorageService.updateTask(updatedTask);
      await loadSavedTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder updated successfully.')),
      );
    } catch (_) {
      try {
        if (!isMissed(oldTask) && oldTask.status != TaskStatus.completed) {
          await NotificationService.scheduleTask(oldTask);
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update reminder notification.')),
      );
    }
  }

  Future<void> toggleCompleted(LifePilotTask task) async {
    final now = DateTime.now();
    final completed = task.status != TaskStatus.completed;
    final updatedTask = task.copyWith(
      status: completed ? TaskStatus.completed : TaskStatus.pending,
      updatedAt: now,
      completedAt: completed ? now : null,
    );

    await TaskStorageService.updateTask(updatedTask);

    if (completed) {
      await NotificationService.cancelTask(updatedTask);
    } else {
      try {
        await NotificationService.scheduleTask(updatedTask);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This reminder time has already passed. Please reschedule it.'),
            ),
          );
        }
      }
    }

    await loadSavedTasks();
  }

  Future<bool> confirmDelete(LifePilotTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reminder?'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return shouldDelete ?? false;
  }

  Future<void> deleteTask(LifePilotTask task) async {
    if (!await confirmDelete(task)) return;

    await NotificationService.cancelTask(task);
    await TaskStorageService.deleteTask(task.id);
    await loadSavedTasks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await TaskStorageService.addTask(task);
            if (!isMissed(task) && task.status != TaskStatus.completed) {
              try {
                await NotificationService.scheduleTask(task);
              } catch (_) {}
            }
            await loadSavedTasks();
          },
        ),
      ),
    );
  }

  String formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  String getFilterName(ReminderFilter filter) {
    switch (filter) {
      case ReminderFilter.all:
        return 'All';

      case ReminderFilter.today:
        return 'Today';

      case ReminderFilter.upcoming:
        return 'Upcoming';

      case ReminderFilter.missed:
        return 'Missed';

      case ReminderFilter.completed:
        return 'Completed';
    }
  }

  String getEmptyMessage() {
    switch (selectedFilter) {
      case ReminderFilter.all:
        return 'No reminders yet.';

      case ReminderFilter.today:
        return 'No reminders for today.';

      case ReminderFilter.upcoming:
        return 'No upcoming reminders.';

      case ReminderFilter.missed:
        return 'No missed reminders.';

      case ReminderFilter.completed:
        return 'No completed reminders.';
    }
  }

  Widget buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: ReminderFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(getFilterName(filter)),
              selected: selectedFilter == filter,
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildTaskCard(LifePilotTask task) {
    final bool missed = isMissed(task);

    return Card(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: task.status == TaskStatus.completed,
            onChanged: (_) {
              toggleCompleted(task);
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: task.status == TaskStatus.completed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                task.dueDateTime == null
                    ? '${getPriorityName(task.priority)} Priority'
                    : '${formatDate(task.dueDateTime!)} • '
                          '${TimeOfDay.fromDateTime(task.dueDateTime!).format(context)} • '
                          '${getPriorityName(task.priority)} Priority',
              ),
              if (missed)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Missed',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  editTask(task);

                case 'reschedule':
                  editTask(task);

                case 'delete':
                  deleteTask(task);
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (missed)
                  const PopupMenuItem<String>(
                    value: 'reschedule',
                    child: Row(
                      children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 10),
                        Text('Reschedule'),
                      ],
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<LifePilotTask> visibleTasks = filteredTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('LifePilot Smart Tasks')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildFilterBar(),
                const Divider(),
                Expanded(
                  child: visibleTasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 90,
                                  color: Colors.indigo.shade300,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No LifePilot Smart Tasks Yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'LifePilot AI helps you organize, remember, and complete what matters most.\nTap the + New Task button to create your first task.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: visibleTasks.length,
                          itemBuilder: (context, index) {
                            return buildTaskCard(visibleTasks[index]);
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 16),
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: createTask,
                    icon: const Icon(Icons.mic, size: 28),
                    label: const Text(
                      '+ New Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
