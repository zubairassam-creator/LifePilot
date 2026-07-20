import 'package:flutter/material.dart';

import '../models/life_memory.dart';
import '../models/lifepilot_task.dart';
import '../services/briefing_service.dart';
import '../services/voice_service.dart';

enum BriefingDialogMode { dailyBriefing, schedule }

bool _isBriefingDialogOpen = false;

Future<void> showBriefingDialog(
  BuildContext context, {
  BriefingDialogMode mode = BriefingDialogMode.dailyBriefing,
  bool speakAutomatically = true,
}) async {
  if (_isBriefingDialogOpen) return;

  _isBriefingDialogOpen = true;
  try {
    await VoiceService.stop();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _BriefingDialog(
        mode: mode,
        speakAutomatically: speakAutomatically,
      ),
    );
  } finally {
    _isBriefingDialogOpen = false;
    await VoiceService.stop();
  }
}

class _BriefingDialog extends StatefulWidget {
  const _BriefingDialog({required this.mode, required this.speakAutomatically});

  final BriefingDialogMode mode;
  final bool speakAutomatically;

  @override
  State<_BriefingDialog> createState() => _BriefingDialogState();
}

class _BriefingDialogState extends State<_BriefingDialog> {
  late Future<BriefingData> _future;
  BriefingData? _data;
  bool _isSpeaking = false;
  bool _autoSpeechStarted = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<BriefingData> _load() async {
    final data = await BriefingService.loadTodayBriefing();
    if (mounted) {
      setState(() => _data = data);
      if (widget.speakAutomatically && !_autoSpeechStarted) {
        _autoSpeechStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _speak(data));
      }
    }
    return data;
  }

  Future<void> _speak(BriefingData data) async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    try {
      await VoiceService.stop();
      await VoiceService.speak(BriefingService.buildSpokenBriefing(data));
    } catch (_) {
      // The visual briefing should remain available even if TTS is unavailable.
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await VoiceService.stop();
    } catch (_) {
      // Ignore platform TTS failures while stopping.
    }
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _close() async {
    await _stopSpeech();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _retry() async {
    await _stopSpeech();
    setState(() {
      _data = null;
      _autoSpeechStarted = false;
      _future = _load();
    });
  }

  @override
  void dispose() {
    VoiceService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final title = widget.mode == BriefingDialogMode.schedule ? 'Today’s Schedule' : 'Today’s Briefing';

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _stopSpeech();
      },
      child: Dialog(
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: size.height * 0.88),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_headerGreeting(), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(_formatFullDate(DateTime.now()), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Close', onPressed: _close, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: FutureBuilder<BriefingData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const _LoadingBriefing();
                      final data = snapshot.data ?? _data;
                      if (data == null || data.allFailed) return _ErrorBriefing(onRetry: _retry);
                      return SingleChildScrollView(child: _BriefingContent(data: data));
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _data == null || _isSpeaking ? null : () => _speak(_data!),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Read Aloud'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isSpeaking ? _stopSpeech : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _close, child: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _headerGreeting() {
    final greeting = BriefingService.greetingFor(DateTime.now());
    return greeting.replaceFirst(greeting[0], greeting[0].toUpperCase());
  }
}

class _LoadingBriefing extends StatelessWidget {
  const _LoadingBriefing();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Preparing your briefing...')],
        ),
      );
}

class _ErrorBriefing extends StatelessWidget {
  const _ErrorBriefing({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            const Text('I could not load your briefing right now.\nPlease try again.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      );
}

class _BriefingContent extends StatelessWidget {
  const _BriefingContent({required this.data});
  final BriefingData data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('You’re all caught up today! 🎉')));
    return Column(
      children: [
        if (data.hasFailures) const _PartialWarning(),
        _TaskSection(icon: Icons.warning_amber_rounded, title: 'Overdue', tasks: data.overdue),
        _TaskSection(icon: Icons.today_outlined, title: 'Today', tasks: data.today),
        _TaskSection(icon: Icons.upcoming_outlined, title: 'Upcoming', tasks: data.upcoming),
        _MemorySection(
          icon: Icons.event_busy_outlined,
          title: 'Expiries',
          memories: data.expiringSoon,
        ),
        _MemorySection(icon: Icons.celebration_outlined, title: 'Birthdays and Events', memories: data.birthdaysAndEvents),
        _MemorySection(icon: Icons.account_balance_wallet_outlined, title: 'Open Loans', memories: data.openLoans, isLoan: true),
      ],
    );
  }
}

class _PartialWarning extends StatelessWidget {
  const _PartialWarning();
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(padding: EdgeInsets.all(10), child: Text('Some briefing details could not be refreshed. Showing what is available.')),
      );
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({required this.icon, required this.title, required this.tasks});
  final IconData icon;
  final String title;
  final List<LifePilotTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return _SectionShell(icon: icon, title: title, count: tasks.length, children: tasks.map((task) => _BulletText('${task.title}${task.dueDateTime == null ? '' : ' at ${_formatTime(task.dueDateTime!)}'}')).toList());
  }
}

class _MemorySection extends StatelessWidget {
  const _MemorySection({required this.icon, required this.title, required this.memories, this.isLoan = false});
  final IconData icon;
  final String title;
  final List<LifeMemory> memories;
  final bool isLoan;

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();
    return _SectionShell(icon: icon, title: title, count: memories.length, children: memories.map((memory) => _BulletText(isLoan ? _loanText(memory) : _memoryText(memory))).toList());
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.icon, required this.title, required this.count, required this.children});
  final IconData icon;
  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text('$title — $count', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('• $text'));
}

String _memoryText(LifeMemory memory) => '${memory.title}${memory.dueDate == null && memory.eventDate == null ? '' : ' — ${_formatDate(memory.dueDate ?? memory.eventDate!)}'}';
String _loanText(LifeMemory memory) => '${memory.person ?? memory.title}${memory.amount == null ? '' : ' — ${memory.currency ?? ''}${memory.amount!.toStringAsFixed(memory.amount!.truncateToDouble() == memory.amount ? 0 : 2)}'}${memory.dueDate == null ? '' : ' due ${_formatDate(memory.dueDate!)}'}';
String _formatFullDate(DateTime date) => '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';
String _formatDate(DateTime date) => '${date.day} ${_month(date.month)}';
String _formatTime(DateTime date) { final hour = date.hour % 12 == 0 ? 12 : date.hour % 12; final minute = date.minute.toString().padLeft(2, '0'); final suffix = date.hour >= 12 ? 'PM' : 'AM'; return '$hour:$minute $suffix'; }
String _weekday(int weekday) => const ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday];
String _month(int month) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month];
