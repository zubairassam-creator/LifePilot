import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/lifepilot_core.dart';
import '../core/secretary_intents.dart';
import '../models/chat_message.dart';
import '../services/task_storage_service.dart';
import '../services/voice_service.dart';
import '../widgets/briefing_dialog.dart';
import 'dashboard_screen.dart';
import 'my_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _hasShownBriefingPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_hasShownBriefingPopup) return;
      _hasShownBriefingPopup = true;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await showBriefingDialog(context);
    });
  }

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Good day. I’m your Personal Secretary. Tell me what to remember, ask about your schedule, or create a task.",
      sender: MessageSender.assistant,
    ),
  ];

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processUserInput(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(ChatMessage(text: trimmedText, sender: MessageSender.user));
      _isThinking = true;
    });
    _scrollChatToBottom();

    final response = await LifePilotCore.instance.process(trimmedText);
    if (!mounted) return;

    final opensBriefing = response.action.type == SecretaryActionType.showBriefing;
    setState(() {
      _isThinking = false;
      _messages.add(ChatMessage(text: response.response, sender: MessageSender.assistant));
      _isSpeaking = !opensBriefing;
    });
    _scrollChatToBottom();

    if (opensBriefing) {
      await _executeSecretaryAction(response.action);
      return;
    }

    await VoiceService.speak(response.response);
    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
    });

    await _executeSecretaryAction(response.action);
  }

  Future<void> _executeSecretaryAction(SecretaryAction action) async {
    if (!mounted) return;

    switch (action.type) {
      case SecretaryActionType.navigateTasks:
        final filter = _taskFilter(action.payload['filter'] as String?);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SmartRemindersScreen(initialFilter: filter)),
        );
        return;
      case SecretaryActionType.showBriefing:
        await showBriefingDialog(
          context,
          mode: BriefingDialogMode.schedule,
          speakAutomatically: true,
        );
        return;
      case SecretaryActionType.createReminder:
        return;
      case SecretaryActionType.deleteTasks:
        await _deleteTasks(action.payload['scope'] as String?);
        return;
      case SecretaryActionType.showHelp:
      case SecretaryActionType.clarify:
        return;
    }
  }

  Future<void> _deleteTasks(String? scope) async {
    if (scope == null || scope == 'unknown') return;
    final tasks = TaskStorageService.getAllTasks();
    final now = DateTime.now();
    final deletable = tasks.where((task) {
      final missed = task.status != TaskStatus.completed && task.dueDateTime != null && task.dueDateTime!.isBefore(now);
      switch (scope) {
        case 'completed':
          return task.status == TaskStatus.completed;
        case 'missed':
          return missed;
        case 'all':
          return true;
        default:
          return false;
      }
    }).toList();
    for (final task in deletable) {
      await TaskStorageService.deleteTask(task.id);
    }
  }

  ReminderFilter _taskFilter(String? value) {
    switch (value) {
      case 'today':
        return ReminderFilter.today;
      case 'tomorrow':
        return ReminderFilter.tomorrow;
      case 'upcoming':
        return ReminderFilter.upcoming;
      case 'completed':
        return ReminderFilter.completed;
      case 'missed':
        return ReminderFilter.missed;
      default:
        return ReminderFilter.all;
    }
  }

  void _setListeningState(bool isListening) {
    if (!mounted || _isListening == isListening) return;
    setState(() {
      _isListening = isListening;
    });
  }

  Future<void> _startListening() async {
    if (_isListening) {
      await _speech.stop();
      _setListeningState(false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        final normalizedStatus = status.toLowerCase();
        if (normalizedStatus == 'listening') {
          _setListeningState(true);
        } else if (normalizedStatus == 'notlistening' || normalizedStatus == 'done') {
          _setListeningState(false);
        }
      },
      onError: (error) {
        _setListeningState(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.errorMsg)));
      },
    );

    if (!available) {
      _setListeningState(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available.')),
      );
      return;
    }

    _setListeningState(true);
    try {
      await _speech.listen(
        onResult: (result) async {
          if (!mounted || !result.finalResult) return;
          _setListeningState(false);
          await _processUserInput(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
        ),
      );
    } catch (_) {
      _setListeningState(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start speech recognition.')),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _chatScrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _statusText {
    if (_isListening) return 'Listening...';
    if (_isThinking) return 'Thinking...';
    if (_isSpeaking) return 'Speaking...';
    return 'Ready for voice or typing';
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifePilot AI'),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
            },
            icon: const Icon(Icons.dashboard),
            label: const Text('Dashboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SecretaryPanel(
                  messages: _messages,
                  scrollController: _chatScrollController,
                  textController: _textController,
                  focusNode: _focusNode,
                  isListening: _isListening,
                  statusText: _statusText,
                  hasText: hasText,
                  onListen: _startListening,
                  onSubmit: _processUserInput,
                  onTextChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecretaryPanel extends StatelessWidget {
  const _SecretaryPanel({
    required this.messages,
    required this.scrollController,
    required this.textController,
    required this.focusNode,
    required this.isListening,
    required this.statusText,
    required this.hasText,
    required this.onListen,
    required this.onSubmit,
    required this.onTextChanged,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isListening;
  final String statusText;
  final bool hasText;
  final VoidCallback onListen;
  final ValueChanged<String> onSubmit;
  final VoidCallback onTextChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Your Personal Secretary', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: InkResponse(
                onTap: onListen,
                radius: 58,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? Colors.red : Colors.indigo,
                    boxShadow: [BoxShadow(color: (isListening ? Colors.red : Colors.indigo).withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 3)],
                  ),
                  child: Icon(isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 56),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(statusText, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message.sender == MessageSender.user;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.indigo : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(message.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(hintText: 'Type to your secretary...', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => onTextChanged(),
                    onSubmitted: onSubmit,
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(52, 52), shape: const CircleBorder(), padding: EdgeInsets.zero, backgroundColor: hasText ? Colors.indigo : (isListening ? Colors.red : Colors.indigo)),
                  onPressed: () => hasText ? onSubmit(textController.text) : onListen(),
                  child: Icon(hasText ? Icons.send : Icons.mic, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
