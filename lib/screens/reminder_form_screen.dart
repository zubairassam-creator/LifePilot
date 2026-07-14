import 'package:flutter/material.dart';

import '../models/reminder.dart';

class ReminderFormScreen extends StatefulWidget {
  final Reminder? existingReminder;

  const ReminderFormScreen({super.key, this.existingReminder});

  bool get isEditing => existingReminder != null;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final TextEditingController titleController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedPriority = 'Medium';

  @override
  void initState() {
    super.initState();

    final Reminder? reminder = widget.existingReminder;

    if (reminder != null) {
      titleController.text = reminder.title;
      selectedDate = reminder.date;
      selectedTime = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
      selectedPriority = reminder.priority;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime initialDate =
        selectedDate != null && selectedDate!.isAfter(now)
        ? selectedDate!
        : now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
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

    final DateTime scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (!scheduledDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date and time.')),
      );
      return;
    }

    final Reminder reminder;

    if (widget.existingReminder == null) {
      reminder = Reminder(
        id: DateTime.now().microsecondsSinceEpoch.remainder(2147483647),
        title: title,
        date: selectedDate!,
        hour: selectedTime!.hour,
        minute: selectedTime!.minute,
        priority: selectedPriority,
      );
    } else {
      reminder = widget.existingReminder!.copyWith(
        title: title,
        date: selectedDate,
        hour: selectedTime!.hour,
        minute: selectedTime!.minute,
        priority: selectedPriority,
        isCompleted: false,
      );
    }

    Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Reminder' : 'Create Reminder'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Update your reminder details.'
                    : 'What should I remind you about?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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
                      : '${selectedDate!.day}/'
                            '${selectedDate!.month}/'
                            '${selectedDate!.year}',
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
                  icon: Icon(isEditing ? Icons.update : Icons.save),
                  label: Text(isEditing ? 'Update Reminder' : 'Save Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
