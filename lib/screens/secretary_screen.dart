import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/lifepilot_core.dart';
import '../models/chat_message.dart';
import '../services/voice_service.dart';
import 'my_tasks_screen.dart';

class SecretaryScreen extends StatefulWidget {
  const SecretaryScreen({super.key});

  @override
  State<SecretaryScreen> createState() => _SecretaryScreenState();
}

class _SecretaryScreenState extends State<SecretaryScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  final ScrollController _scrollController = ScrollController();

  final TextEditingController _textController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "How can I help you today?",
      sender: MessageSender.assistant,
    ),
  ];

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

  static const Set<String> _smartTasksNavigationCommands = {
    'show me the schedule',
    'show my schedule',
    'open schedule',
    'my schedule',
    'todays schedule',
    'what is my schedule',
    'whats my schedule',
    'what do i have today',
    'show tasks',
    'show my tasks',
    'open tasks',
    'my tasks',
    'smart tasks',
    'show reminders',
    'show my reminders',
    'open reminders',
    'my reminders',
  };

  String _normalizeCommandText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[‘’`´]'), "'")
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isSmartTasksNavigationCommand(String text) {
    return _smartTasksNavigationCommands.contains(_normalizeCommandText(text));
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

    if (_isSmartTasksNavigationCommand(trimmedText)) {
      const assistantMessage = 'Opening your Smart Tasks.';

      if (!mounted) return;

      setState(() {
        _isThinking = false;
        _messages.add(
          ChatMessage(
            text: assistantMessage,
            sender: MessageSender.assistant,
          ),
        );
        _isSpeaking = true;
      });

      _scrollToBottom();

      await VoiceService.speak(assistantMessage);

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SmartRemindersScreen()),
      );
      return;
    }

    final response = await LifePilotCore.instance.process(trimmedText);

    if (!mounted) return;

    setState(() {
      _isThinking = false;

      _messages.add(
        ChatMessage(text: response.message, sender: MessageSender.assistant),
      );

      _isSpeaking = true;
    });

    _scrollToBottom();

    await VoiceService.speak(response.message);

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
    });
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
        final isActivelyListening = normalizedStatus == 'listening';

        if (isActivelyListening) {
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
          if (!mounted) return;

          if (!result.finalResult) return;

          _setListeningState(false);
          await processUserInput(result.recognizedWords);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      onSubmitted: (value) async {
                        await processUserInput(value);
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  FloatingActionButton(
                    mini: true,
                    backgroundColor: !hasText && _isListening
                        ? Colors.red
                        : null,
                    foregroundColor: !hasText && _isListening
                        ? Colors.white
                        : null,
                    onPressed: () async {
                      if (_textController.text.trim().isEmpty) {
                        await _startListening();
                      } else {
                        await processUserInput(_textController.text.trim());
                      }
                    },
                    child: Icon(hasText ? Icons.send : Icons.mic),
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
