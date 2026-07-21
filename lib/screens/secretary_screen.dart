import 'package:flutter/material.dart';
import '../core/lifepilot_core.dart';
import '../core/secretary_intents.dart';
import '../models/chat_message.dart';
import '../models/lifepilot_document.dart';
import '../services/document_picker_service.dart';
import '../widgets/attachment_source_sheet.dart';
import '../widgets/pending_attachment_preview.dart';
import '../services/secretary_action_handler.dart';
import '../services/secretary_voice_helper.dart';
import '../services/voice_service.dart';
import 'my_tasks_screen.dart';

class SecretaryScreen extends StatefulWidget {
  const SecretaryScreen({super.key});

  @override
  State<SecretaryScreen> createState() => _SecretaryScreenState();
}

class _SecretaryScreenState extends State<SecretaryScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _textController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _welcomeDelivered = false;
  PendingDocumentAttachment? _pendingAttachment;

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _deliverWelcome();
    });
  }

  Future<void> _deliverWelcome() async {
    if (_welcomeDelivered || !mounted) return;

    _welcomeDelivered = true;

    await _addAssistantMessageAndSpeak(
      'I am your personal assistant. How may I help you?',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> processUserInput(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: trimmedText, sender: MessageSender.user));
      _isThinking = true;
    });

    _scrollToBottom();

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

  Future<void> _addAssistantMessageAndSpeak(String text) async {
    await _addAssistantMessage(text, speak: true);
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
        _scrollToBottom();
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
      onFinalResult: processUserInput,
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  void dispose() {
    VoiceService.stopListening();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _statusText {
    if (_isListening) {
      return "🎤 Listening...";
    }

    if (_isThinking) {
      return "🧠 Thinking...";
    }

    if (_isSpeaking) {
      return "🔊 Speaking...";
    }

    return "Ready";
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("LifePilot AI"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Open Smart Tasks',
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.checklist, size: 20),
                label: const Text(
                  'Smart Tasks',
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartRemindersScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Text(
              "Your Personal Secretary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: _startListening,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : Colors.blue,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 70,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _statusText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            if (_pendingAttachment != null)
              PendingAttachmentPreview(
                attachment: _pendingAttachment!,
                onRemove: () => setState(() => _pendingAttachment = null),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  final isUser = message.sender == MessageSender.user;

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUser ? "You" : "LifePilot",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 16,
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AssistantInputBar(
        textController: _textController,
        focusNode: _focusNode,
        isListening: _isListening,
        hasText: hasText,
        onAttach: _pickAttachment,
        onListen: _startListening,
        onSubmit: processUserInput,
        onTextChanged: () => setState(() {}),
      ),
    );
  }
}

class _AssistantInputBar extends StatelessWidget {
  const _AssistantInputBar({
    required this.textController,
    required this.focusNode,
    required this.isListening,
    required this.hasText,
    required this.onAttach,
    required this.onListen,
    required this.onSubmit,
    required this.onTextChanged,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isListening;
  final bool hasText;
  final VoidCallback onAttach;
  final VoidCallback onListen;
  final ValueChanged<String> onSubmit;
  final VoidCallback onTextChanged;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding =
        bottomInset > 0 ? bottomInset : mediaQuery.viewPadding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => onTextChanged(),
                  onSubmitted: onSubmit,
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                mini: true,
                backgroundColor: !hasText && isListening ? Colors.red : null,
                foregroundColor: !hasText && isListening ? Colors.white : null,
                onPressed: () =>
                    hasText ? onSubmit(textController.text.trim()) : onListen(),
                child: Icon(hasText ? Icons.send : Icons.mic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
