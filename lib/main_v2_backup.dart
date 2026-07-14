import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LifePilotApp());
}

class LifePilotApp extends StatelessWidget {
  const LifePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifePilot AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Reminder {
  final String title;
  final DateTime date;
  final int hour;
  final int minute;
  final String priority;
  bool isCompleted;

  Reminder({
    required this.title,
    required this.date,
    required this.hour,
    required this.minute,
    required this.priority,
    this.isCompleted = false,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'hour': hour,
      'minute': minute,
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      priority: json['priority'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class ReminderStorage {
  static const String storageKey = 'lifepilot_reminders_v1';

  static Future<List<Reminder>> loadReminders() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? savedData = preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);

      return decodedData
          .map(
            (item) => Reminder.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveReminders(List<Reminder> reminders) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String encodedData = jsonEncode(
      reminders.map((reminder) => reminder.toJson()).toList(),
    );

    await preferences.setString(storageKey, encodedData);
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LifePilot AI'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Day 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'What would you like me to help you with?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: [
                  FeatureCard(
                    icon: Icons.notifications_active,
                    title: 'Smart Reminders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SmartRemindersScreen(),
                        ),
                      );
                    },
                  ),
                  const FeatureCard(
                    icon: Icons.note_alt,
                    title: 'Memory Notes',
                  ),
                  const FeatureCard(
                    icon: Icons.folder,
                    title: 'Important Documents',
                  ),
                  const FeatureCard(icon: Icons.contacts, title: 'Contacts'),
                  const FeatureCard(
                    icon: Icons.wb_sunny,
                    title: 'Daily Briefing',
                  ),
                  const FeatureCard(
                    icon: Icons.auto_awesome,
                    title: 'AI Assistant',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.indigo),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  final List<Reminder> reminders = [];
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

  Future<void> createReminder() async {
    final Reminder? newReminder = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(builder: (context) => const CreateReminderScreen()),
    );

    if (newReminder != null) {
      setState(() {
        reminders.add(newReminder);
      });

      await saveReminderList();
    }
  }

  Future<void> toggleCompleted(int index) async {
    setState(() {
      reminders[index].isCompleted = !reminders[index].isCompleted;
    });

    await saveReminderList();
  }

  Future<void> deleteReminder(int index) async {
    final Reminder deletedReminder = reminders[index];

    setState(() {
      reminders.removeAt(index);
    });

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
            setState(() {
              final int safeIndex = index <= reminders.length
                  ? index
                  : reminders.length;

              reminders.insert(safeIndex, deletedReminder);
            });

            await saveReminderList();
          },
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Reminders')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No reminders yet.',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first reminder.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: createReminder,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Reminder'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final Reminder reminder = reminders[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Checkbox(
                      value: reminder.isCompleted,
                      onChanged: (_) {
                        toggleCompleted(index);
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
                    subtitle: Text(
                      '${formatDate(reminder.date)} • '
                      '${reminder.time.format(context)} • '
                      '${reminder.priority} Priority',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        deleteReminder(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isLoading || reminders.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: createReminder,
              child: const Icon(Icons.add),
            ),
    );
  }
}

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final TextEditingController titleController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedPriority = 'Medium';

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void saveReminder() {
    final String title = titleController.text.trim();

    if (title.isEmpty || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title, date, and time.')),
      );
      return;
    }

    final Reminder reminder = Reminder(
      title: title,
      date: selectedDate!,
      hour: selectedTime!.hour,
      minute: selectedTime!.minute,
      priority: selectedPriority,
    );

    Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Reminder')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What should I remind you about?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: 'Example: Call the electricity office',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Select Date'),
                subtitle: Text(
                  selectedDate == null
                      ? 'No date selected'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: selectDate,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Select Time'),
                subtitle: Text(
                  selectedTime == null
                      ? 'No time selected'
                      : selectedTime!.format(context),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: selectTime,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPriority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveReminder,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
