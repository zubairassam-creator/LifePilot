import 'package:flutter/material.dart';
import '../core/lifepilot_core.dart';
import '../core/secretary_intents.dart';
import '../models/chat_message.dart';
import '../services/document_picker_service.dart';
import '../widgets/attachment_source_sheet.dart';
import '../widgets/pending_attachment_preview.dart';
import '../services/secretary_action_handler.dart';
import '../services/secretary_voice_helper.dart';
import '../services/voice_service.dart';
import '../widgets/briefing_dialog.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _hasShownBriefingPopup = false;
  PendingDocumentAttachment? _pendingAttachment;

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

    final response = await LifePilotCore.instance.process(
      trimmedText,
      hasPendingAttachment: _pendingAttachment != null,
    );
    if (!mounted) return;

    final opensBriefing = response.action.type == SecretaryActionType.showBriefing;
    setState(() => _isThinking = false);
    await _addAssistantMessage(response.response, speak: !opensBriefing);

    if (opensBriefing) {
      await _executeSecretaryAction(response.action);
      return;
    }

    await _executeSecretaryAction(response.action);
  }

  Future<void> _executeSecretaryAction(SecretaryAction action) async {
    await SecretaryActionHandler(
      context: context,
      pendingAttachment: () => _pendingAttachment,
      clearPendingAttachment: () => setState(() => _pendingAttachment = null),
      reply: _addAssistantMessage,
    ).execute(action);
  }

  Future<void> _pickAttachment() async {
    final source = await AttachmentSourceSheet.show(context);
    if (source == null) return;
    final result = await DocumentPickerService.instance.pick(source);
    if (!mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    if (result.attachment != null) setState(() => _pendingAttachment = result.attachment);
  }


  Future<void> _addAssistantMessage(String text, {bool speak = true}) async {
    if (!mounted) return;
    await SecretaryVoiceHelper.speakAndDisplay(
      text,
      speak: speak,
      display: (message) async {
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(text: message, sender: MessageSender.assistant));
        });
        _scrollChatToBottom();
      },
      setSpeaking: (isSpeaking) {
        if (!mounted) return;
        setState(() => _isSpeaking = isSpeaking);
      },
    );
  }

  void _setListeningState(bool isListening) {
    if (!mounted || _isListening == isListening) return;
    setState(() {
      _isListening = isListening;
    });
  }

  Future<void> _startListening() async {
    await VoiceService.toggleListening(
      onListeningChanged: _setListeningState,
      onFinalResult: _processUserInput,
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  void dispose() {
    VoiceService.stopListening();
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
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
            },
          ),
        ],
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
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isUser ? Colors.indigo : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(message.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  backgroundColor: hasText ? Colors.indigo : (isListening ? Colors.red : Colors.indigo),
                ),
                onPressed: () => hasText ? onSubmit(textController.text) : onListen(),
                child: Icon(hasText ? Icons.send : Icons.mic, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
