import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../services/reminder_storage.dart';
import 'reminder_form_screen.dart';

enum ReminderFilter { all, today, upcoming, missed, completed }

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  final List<Reminder> reminders = [];

  ReminderFilter selectedFilter = ReminderFilter.all;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavedReminders();
  }

  Future<void> loadSavedReminders() async {
    final List<Reminder> savedReminders = await ReminderStorage.loadReminders();

    if (!mounted) {
      return;
    }

    setState(() {
      reminders
        ..clear()
        ..addAll(savedReminders);

      isLoading = false;
    });
  }

  Future<void> saveReminderList() async {
    await ReminderStorage.saveReminders(reminders);
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<Reminder> get filteredReminders {
    final DateTime now = DateTime.now();

    final List<Reminder> result;

    switch (selectedFilter) {
      case ReminderFilter.all:
        result = List<Reminder>.from(reminders);

      case ReminderFilter.today:
        result = reminders.where((reminder) {
          return !reminder.isCompleted &&
              !reminder.isMissed &&
              isSameDay(reminder.scheduledDateTime, now);
        }).toList();

      case ReminderFilter.upcoming:
        result = reminders.where((reminder) {
          return !reminder.isCompleted &&
              reminder.scheduledDateTime.isAfter(now);
        }).toList();

      case ReminderFilter.missed:
        result = reminders.where((reminder) {
          return reminder.isMissed;
        }).toList();

      case ReminderFilter.completed:
        result = reminders.where((reminder) {
          return reminder.isCompleted;
        }).toList();
    }

    result.sort(
      (first, second) =>
          first.scheduledDateTime.compareTo(second.scheduledDateTime),
    );

    return result;
  }

  Future<void> createReminder() async {
    final Reminder? newReminder = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(builder: (context) => const ReminderFormScreen()),
    );

    if (newReminder == null) {
      return;
    }

    try {
      await NotificationService.scheduleReminder(newReminder);

      setState(() {
        reminders.add(newReminder);
      });

      await saveReminderList();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder saved and notification scheduled.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not schedule notification. Please check permissions and choose a future time.',
          ),
        ),
      );
    }
  }

  Future<void> editReminder(Reminder oldReminder) async {
    final Reminder? updatedReminder = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderFormScreen(existingReminder: oldReminder),
      ),
    );

    if (updatedReminder == null) {
      return;
    }

    try {
      await NotificationService.cancelReminder(oldReminder.id);

      await NotificationService.scheduleReminder(updatedReminder);

      final int index = reminders.indexWhere(
        (reminder) => reminder.id == oldReminder.id,
      );

      if (index == -1) {
        return;
      }

      setState(() {
        reminders[index] = updatedReminder;
      });

      await saveReminderList();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder updated successfully.')),
      );
    } catch (_) {
      try {
        if (!oldReminder.isCompleted && !oldReminder.isMissed) {
          await NotificationService.scheduleReminder(oldReminder);
        }
      } catch (_) {
        // Ignore restoration failure.
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update reminder notification.'),
        ),
      );
    }
  }

  Future<void> rescheduleReminder(Reminder reminder) async {
    await editReminder(reminder);
  }

  Future<void> toggleCompleted(Reminder reminder) async {
    final int index = reminders.indexWhere((item) => item.id == reminder.id);

    if (index == -1) {
      return;
    }

    setState(() {
      reminders[index].isCompleted = !reminders[index].isCompleted;
    });

    if (reminders[index].isCompleted) {
      await NotificationService.cancelReminder(reminders[index].id);
    } else {
      try {
        await NotificationService.scheduleReminder(reminders[index]);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This reminder time has already passed. Please reschedule it.',
              ),
            ),
          );
        }
      }
    }

    await saveReminderList();
  }

  Future<bool> confirmDelete(Reminder reminder) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reminder?'),
          content: Text('Are you sure you want to delete "${reminder.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return shouldDelete ?? false;
  }

  Future<void> deleteReminder(Reminder reminder) async {
    final bool shouldDelete = await confirmDelete(reminder);

    if (!shouldDelete) {
      return;
    }

    final int index = reminders.indexWhere((item) => item.id == reminder.id);

    if (index == -1) {
      return;
    }

    final Reminder deletedReminder = reminders[index];

    setState(() {
      reminders.removeAt(index);
    });

    await NotificationService.cancelReminder(deletedReminder.id);

    await saveReminderList();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final int safeIndex = index <= reminders.length
                ? index
                : reminders.length;

            setState(() {
              reminders.insert(safeIndex, deletedReminder);
            });

            if (!deletedReminder.isCompleted && !deletedReminder.isMissed) {
              try {
                await NotificationService.scheduleReminder(deletedReminder);
              } catch (_) {
                // Ignore rescheduling failure.
              }
            }

            await saveReminderList();
          },
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Widget buildReminderCard(Reminder reminder) {
    final bool missed = reminder.isMissed;

    return Card(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: reminder.isCompleted,
            onChanged: (_) {
              toggleCompleted(reminder);
            },
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: reminder.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${formatDate(reminder.date)} • '
                '${reminder.time.format(context)} • '
                '${reminder.priority} Priority',
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
                  editReminder(reminder);

                case 'reschedule':
                  rescheduleReminder(reminder);

                case 'delete':
                  deleteReminder(reminder);
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
    final List<Reminder> visibleReminders = filteredReminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Reminders')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildFilterBar(),
                const Divider(),
                Expanded(
                  child: visibleReminders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              getEmptyMessage(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: visibleReminders.length,
                          itemBuilder: (context, index) {
                            return buildReminderCard(visibleReminders[index]);
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
                    onPressed: createReminder,
                    icon: const Icon(Icons.mic, size: 28),
                    label: const Text(
                      'Create Reminder',
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
