import '../services/secretary_engine.dart';
import '../widgets/lifepilot_understanding_dialog.dart';
import '../services/brain_engine.dart';
import '../services/voice_task_parser.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/lifepilot_task.dart';


enum ReminderModeOption { normal, speak, repeatSpeak, silent }

class ReminderFormScreen extends StatefulWidget {
  final LifePilotTask? existingTask;
  final String? initialTitle;
  final bool voiceMode;

  const ReminderFormScreen({
    super.key,
    this.existingTask,
    this.initialTitle,
    this.voiceMode = false,
  });

  bool get isEditing => existingTask != null;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final TextEditingController titleController = TextEditingController();

  final stt.SpeechToText speech = stt.SpeechToText();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedPriority = 'Medium';
  ReminderModeOption selectedNotificationMode = ReminderModeOption.normal;

  bool isListening = false;


  String _priorityName(TaskPriority priority) {
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

  TaskPriority _taskPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'critical':
        return TaskPriority.critical;
      default:
        return TaskPriority.normal;
    }
  }

  ReminderMode _reminderMode(ReminderModeOption mode) {
    switch (mode) {
      case ReminderModeOption.silent:
        return ReminderMode.silent;
      case ReminderModeOption.speak:
      case ReminderModeOption.repeatSpeak:
        return ReminderMode.speakAloud;
      case ReminderModeOption.normal:
        return ReminderMode.normal;
    }
  }

  ReminderModeOption _notificationMode(ReminderMode mode) {
    switch (mode) {
      case ReminderMode.silent:
        return ReminderModeOption.silent;
      case ReminderMode.speakAloud:
        return ReminderModeOption.speak;
      case ReminderMode.normal:
        return ReminderModeOption.normal;
    }
  }

  @override
  void initState() {
    super.initState();

    final LifePilotTask? task = widget.existingTask;

    if (task != null) {
      titleController.text = task.title;
      if (task.dueDateTime != null) {
        selectedDate = task.dueDateTime;
        selectedTime = TimeOfDay.fromDateTime(task.dueDateTime!);
      }
      selectedPriority = _priorityName(task.priority);
      selectedNotificationMode = _notificationMode(task.reminderMode);
    } else if (widget.initialTitle != null) {
      titleController.text = widget.initialTitle!;
    }

    if (widget.existingTask == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          startListening();
        }
      });
    }
  }

  @override
  void dispose() {
    speech.stop();
    titleController.dispose();
    super.dispose();
  }

  Future<void> startListening() async {
    final bool available = await speech.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }

        setState(() {
          isListening = status == 'listening';
        });

        debugPrint('Speech status: $status');
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');

        if (!mounted) {
          return;
        }

        setState(() {
          isListening = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: ${error.errorMsg}')),
        );
      },
    );

    if (!available) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available.')),
      );

      return;
    }

    await speech.listen(
      onResult: (result) {
        debugPrint('Recognized speech: ${result.recognizedWords}');

        if (!mounted) {
          return;
        }
        final ParsedVoiceTask parsedTask = VoiceTaskParser.parse(
          result.recognizedWords,
        );

        setState(() {
          titleController.text = parsedTask.title;

          if (parsedTask.eventDate != null) {
            selectedDate = parsedTask.eventDate;
          }

          if (parsedTask.eventTime != null) {
            selectedTime = parsedTask.eventTime;
          }

          titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: titleController.text.length),
          );
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await speech.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      isListening = false;
    });
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

  Future<void> saveReminder() async {
    final String title = titleController.text.trim();

    final analysis = BrainEngine.analyze(title);

    debugPrint('==============================');
    debugPrint('LifePilot Brain Analysis');
    debugPrint('Task Type : ${analysis.taskType}');
    debugPrint('Category  : ${analysis.category}');
    debugPrint('Priority  : ${analysis.priority}');
    debugPrint('Person    : ${analysis.person}');
    debugPrint('Document  : ${analysis.document}');
    debugPrint('Confidence: ${analysis.confidence}');
    debugPrint('==============================');

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

    /*if (widget.voiceMode) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Confirm Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task: $title'),
                const SizedBox(height: 10),
                Text(
                  'Date: ${selectedDate!.day}/'
                  '${selectedDate!.month}/'
                  '${selectedDate!.year}',
                ),
                const SizedBox(height: 10),
                Text('Time: ${selectedTime!.format(context)}'),
                const SizedBox(height: 16),
                const Text(
                  'Is this correct?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Edit'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Confirm & Save'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      if (!mounted) {
        return;
      }
    } */

    final confirmed = await LifePilotUnderstandingDialog.show(
      context,
      analysis,
    );

    if (!confirmed) {
      return;
    }
    // Secretary Brain

    final secretary = SecretaryEngine.process(title);

    debugPrint('==============================');
    debugPrint('SECRETARY ANALYSIS');
    debugPrint('Task Type: ${secretary.analysis.taskType}');
    debugPrint('Category: ${secretary.analysis.category}');
    debugPrint('Priority: ${secretary.analysis.priority}');
    debugPrint('Responsibility Score: ${secretary.responsibilityScore}');
    debugPrint('Reminder Plan: ${secretary.reminderPlan}');
    debugPrint('Requires Follow Up: ${secretary.requiresFollowUp}');
    debugPrint('Morning Brief: ${secretary.showInMorningBrief}');
    debugPrint('Speak Aloud: ${secretary.shouldSpeakAloud}');
    debugPrint('==============================');
    final now = DateTime.now();
    final existingTask = widget.existingTask;
    final LifePilotTask task;

    if (existingTask == null) {
      task = LifePilotTask(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        description: '',
        category: analysis.category,
        priority: _taskPriority(selectedPriority),
        status: TaskStatus.pending,
        dueDateTime: scheduledDateTime,
        reminderEnabled: true,
        reminderMode: _reminderMode(selectedNotificationMode),
        repeatType: RepeatType.none,
        isAiGenerated: false,
        aiConfidence: analysis.confidence,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      task = existingTask.copyWith(
        title: title,
        category: analysis.category,
        priority: _taskPriority(selectedPriority),
        status: TaskStatus.pending,
        dueDateTime: scheduledDateTime,
        reminderEnabled: true,
        reminderMode: _reminderMode(selectedNotificationMode),
        aiConfidence: analysis.confidence,
        updatedAt: now,
        completedAt: null,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(context, task);
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
                decoration: InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: 'Type or speak your reminder',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: isListening ? stopListening : startListening,
                    icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                    tooltip: isListening ? 'Stop Listening' : 'Speak Reminder',
                  ),
                ),
              ),

              if (isListening)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Listening... Speak now',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

              const SizedBox(height: 16),

              DropdownButtonFormField<ReminderModeOption>(
                initialValue: selectedNotificationMode,
                decoration: const InputDecoration(
                  labelText: 'Notification Mode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ReminderModeOption.normal,
                    child: Text('🔔 Normal'),
                  ),
                  DropdownMenuItem(
                    value: ReminderModeOption.speak,
                    child: Text('🗣 Speak Once'),
                  ),
                  DropdownMenuItem(
                    value: ReminderModeOption.repeatSpeak,
                    child: Text('📢 Speak Repeatedly'),
                  ),
                  DropdownMenuItem(
                    value: ReminderModeOption.silent,
                    child: Text('🔕 Silent'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedNotificationMode = value;
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
                  label: Text(
                    isEditing
                        ? 'Update Task'
                        : widget.voiceMode
                        ? 'Confirm & Save'
                        : 'Save Task',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
