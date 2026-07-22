import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/lifepilot_core.dart';
import '../core/secretary_intents.dart';
import '../models/chat_message.dart';
import '../models/lifepilot_document.dart';
import '../models/lifepilot_task.dart';
import '../services/document_auth_service.dart';
import '../services/document_picker_service.dart';
import '../services/document_share_service.dart';
import '../services/document_storage_service.dart';
import '../widgets/attachment_source_sheet.dart';
import '../widgets/document_save_sheet.dart';
import '../widgets/pending_attachment_preview.dart';
import '../services/task_storage_service.dart';
import '../services/voice_service.dart';
import '../widgets/briefing_dialog.dart';
import 'document_details_screen.dart';
import 'important_documents_screen.dart';
import 'my_tasks_screen.dart';

class SecretaryScreen extends StatefulWidget {
  const SecretaryScreen({super.key});

  @override
  State<SecretaryScreen> createState() => _SecretaryScreenState();
}

class _SecretaryScreenState extends State<SecretaryScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _welcomeDelivered = false;
  PendingDocumentAttachment? _pendingAttachment;

  static const String _welcomeMessage =
      'Hello! I am your AI Digital Personal Assistant. How may I help you today?';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_welcomeDelivered || !mounted) return;
      _welcomeDelivered = true;
      setState(() => _isSpeaking = true);
      try {
        await VoiceService.speak(_welcomeMessage);
      } finally {
        if (mounted) setState(() => _isSpeaking = false);
      }
    });
  }

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: _welcomeMessage,
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

    final response = await LifePilotCore.instance.process(
      trimmedText,
      hasPendingAttachment: _pendingAttachment != null,
    );
    if (!mounted) return;

    final opensBriefing =
        response.action.type == SecretaryActionType.showBriefing;
    setState(() {
      _isThinking = false;
      _messages.add(
        ChatMessage(text: response.response, sender: MessageSender.assistant),
      );
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
          MaterialPageRoute(
            builder: (context) => SmartRemindersScreen(initialFilter: filter),
          ),
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
      case SecretaryActionType.saveDocument:
        await _savePendingDocument(action.payload['name'] as String?);
        return;
      case SecretaryActionType.findDocument:
      case SecretaryActionType.openDocument:
        await _openDocumentCommand(action.payload['name'] as String?);
        return;
      case SecretaryActionType.shareDocument:
        await _shareDocumentCommand(action.payload['name'] as String?);
        return;
      case SecretaryActionType.deleteDocument:
        await _deleteDocumentCommand(action.payload['name'] as String?);
        return;
      case SecretaryActionType.listDocuments:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportantDocumentsScreen()),
        );
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
      final missed =
          task.status != TaskStatus.completed &&
          task.dueDateTime != null &&
          task.dueDateTime!.isBefore(now);
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

  Future<void> _pickAttachment() async {
    final source = await AttachmentSourceSheet.show(context);
    if (source == null) return;
    final result = await DocumentPickerService.instance.pick(source);
    if (!mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    if (result.attachment != null)
      setState(() => _pendingAttachment = result.attachment);
  }

  Future<void> _savePendingDocument(String? name) async {
    final attachment = _pendingAttachment;
    if (attachment == null) {
      await _addAssistantMessageAndSpeak(
        'Please attach or capture the document you want me to save.',
      );
      return;
    }
    final data = await DocumentSaveSheet.show(
      context,
      attachment,
      name ?? _titleFromFile(attachment.fileName),
    );
    if (data == null) return;
    if (data.sensitive) {
      final auth = await DocumentAuthService.instance.authenticate(
        'Authenticate to save this sensitive document',
      );
      if (!auth.success) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.message ?? 'Authentication failed.')),
          );
        return;
      }
    }
    try {
      await DocumentStorageService.instance.save(
        attachment: attachment,
        displayName: data.name,
        category: data.category,
        isSensitive: data.sensitive,
        description: data.description,
      );
      setState(() => _pendingAttachment = null);
      await _addAssistantMessageAndSpeak(
        'Saved ${data.name} securely in Important Documents.',
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this document securely.'),
          ),
        );
    }
  }

  Future<void> _openDocumentCommand(String? name) async {
    if (name == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImportantDocumentsScreen()),
      );
      return;
    }
    final doc = DocumentStorageService.instance.findBest(name);
    if (doc == null) {
      await _addAssistantMessageAndSpeak(
        'I couldn’t find a document named $name.',
      );
      return;
    }
    if (doc.isSensitive) {
      final auth = await DocumentAuthService.instance.authenticate(
        'Authenticate to open this document',
      );
      if (!auth.success) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentDetailsScreen(document: doc)),
    );
  }

  Future<void> _shareDocumentCommand(String? name) async {
    final doc = name == null
        ? null
        : DocumentStorageService.instance.findBest(name);
    if (doc == null) {
      await _addAssistantMessageAndSpeak(
        name == null
            ? 'Which document should I share?'
            : 'I couldn’t find a document named $name.',
      );
      return;
    }
    final auth = await DocumentAuthService.instance.authenticate(
      'Authenticate to share this document',
    );
    if (!auth.success) return;
    try {
      await DocumentShareService.instance.share(doc);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share this document.')),
        );
    }
  }

  Future<void> _deleteDocumentCommand(String? name) async {
    final doc = name == null
        ? null
        : DocumentStorageService.instance.findBest(name);
    if (doc == null) {
      await _addAssistantMessageAndSpeak(
        name == null
            ? 'Which document should I delete?'
            : 'I couldn’t find a document named $name.',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentDetailsScreen(document: doc)),
    );
  }

  void _addAssistantMessage(String text) {
    if (!mounted) return;
    setState(
      () => _messages.add(
        ChatMessage(text: text, sender: MessageSender.assistant),
      ),
    );
    _scrollChatToBottom();
  }

  Future<void> _addAssistantMessageAndSpeak(String text) async {
    _addAssistantMessage(text);
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    try {
      await VoiceService.speak(text);
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  String _titleFromFile(String f) {
    final base = f
        .replaceFirst(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ');
    return base
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
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
        } else if (normalizedStatus == 'notlistening' ||
            normalizedStatus == 'done') {
          _setListeningState(false);
        }
      },
      onError: (error) {
        _setListeningState(false);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.errorMsg)));
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
        title: const Text('AI Assistant'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SecretaryPanel(
                isListening: _isListening,
                statusText: _statusText,
                onListen: _startListening,
              ),
            ),
            if (_pendingAttachment != null)
              PendingAttachmentPreview(
                attachment: _pendingAttachment!,
                onRemove: () => setState(() => _pendingAttachment = null),
              ),
            Expanded(
              child: _ConversationList(
                messages: _messages,
                scrollController: _chatScrollController,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SecretaryInputBar(
        textController: _textController,
        focusNode: _focusNode,
        isListening: _isListening,
        hasText: hasText,
        onListen: _startListening,
        onSubmit: _processUserInput,
        onAttach: _pickAttachment,
        onTextChanged: () => setState(() {}),
      ),
    );
  }
}

class _SecretaryPanel extends StatelessWidget {
  const _SecretaryPanel({
    required this.isListening,
    required this.statusText,
    required this.onListen,
  });

  final bool isListening;
  final String statusText;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your AI Digital Personal Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
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
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.red : Colors.indigo)
                            .withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.messages,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.sender == MessageSender.user;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isUser ? Colors.indigo : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        );
      },
    );
  }
}

class _SecretaryInputBar extends StatelessWidget {
  const _SecretaryInputBar({
    required this.textController,
    required this.focusNode,
    required this.isListening,
    required this.hasText,
    required this.onListen,
    required this.onSubmit,
    required this.onAttach,
    required this.onTextChanged,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isListening;
  final bool hasText;
  final VoidCallback onListen;
  final ValueChanged<String> onSubmit;
  final VoidCallback onAttach;
  final VoidCallback onTextChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Add document',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onAttach,
              ),
              Expanded(
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Type to your secretary...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => onTextChanged(),
                  onSubmitted: onSubmit,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: hasText
                      ? Colors.indigo
                      : (isListening ? Colors.red : Colors.indigo),
                ),
                onPressed: () =>
                    hasText ? onSubmit(textController.text) : onListen(),
                child: Icon(
                  hasText ? Icons.send : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
