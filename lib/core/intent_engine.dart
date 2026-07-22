import 'input_normalizer.dart';
import 'secretary_intents.dart';

class IntentEngine {
  const IntentEngine({this._normalizer = const InputNormalizer()});

  final InputNormalizer _normalizer;

  IntentResult recognize(
    String input, {
    bool hasPendingAttachment = false,
  }) {
    final normalized = _normalizer.normalize(input);
    if (normalized.isEmpty) {
      return _result(
        input,
        normalized,
        SecretaryIntent.unknown,
        .0,
        {},
        "I'm here when you're ready.",
        const SecretaryAction(SecretaryActionType.clarify),
      );
    }

    final scheduleScope = _extractScheduleScope(normalized);
    final deletionScope = _extractDeletionScope(normalized);

    final docCommand = _documentCommand(
      normalized,
      hasPendingAttachment: hasPendingAttachment,
    );
    if (docCommand != null) {
      final name = _extractDocumentName(normalized, docCommand);
      final response = switch (docCommand) {
        SecretaryActionType.saveDocument =>
          'I can save that document securely.',
        SecretaryActionType.findDocument =>
          name == null
              ? 'Opening your important documents.'
              : 'Looking for $name.',
        SecretaryActionType.openDocument =>
          name == null ? 'Which document should I open?' : 'Opening $name.',
        SecretaryActionType.shareDocument =>
          name == null
              ? 'Which document should I share?'
              : 'Preparing to share $name.',
        SecretaryActionType.deleteDocument =>
          name == null
              ? 'Which document should I delete?'
              : 'Preparing to delete $name.',
        SecretaryActionType.listDocuments =>
          'Opening your important documents.',
        _ => 'Opening your important documents.',
      };
      final intent = switch (docCommand) {
        SecretaryActionType.saveDocument => SecretaryIntent.saveDocument,
        SecretaryActionType.findDocument => SecretaryIntent.findDocument,
        SecretaryActionType.openDocument => SecretaryIntent.openDocument,
        SecretaryActionType.shareDocument => SecretaryIntent.shareDocument,
        SecretaryActionType.deleteDocument => SecretaryIntent.deleteDocument,
        SecretaryActionType.listDocuments => SecretaryIntent.listDocuments,
        _ => SecretaryIntent.findDocument,
      };
      return _result(
        input,
        normalized,
        intent,
        .86,
        {'name': name},
        response,
        SecretaryAction(docCommand, {'name': name}),
      );
    }

    if (_isDeleteTasks(normalized, deletionScope)) {
      return _result(
        input,
        normalized,
        SecretaryIntent.deleteTasks,
        deletionScope == DeletionScope.unknown ? .62 : .9,
        {'scope': deletionScope.name},
        _deleteResponse(deletionScope),
        SecretaryAction(SecretaryActionType.deleteTasks, {
          'scope': deletionScope.name,
        }),
      );
    }

    if (_isViewSchedule(normalized)) {
      final scope = scheduleScope ?? ScheduleScope.all;
      return _result(
        input,
        normalized,
        SecretaryIntent.viewSchedule,
        .88,
        {'scope': scope.name},
        _scheduleResponse(scope),
        SecretaryAction(
          SecretaryActionType.showBriefing,
          {
            'mode': 'schedule',
            'filter': _filterForScope(scope),
          },
        ),
      );
    }

    if (_isOpenTasks(normalized)) {
      return _result(
        input,
        normalized,
        SecretaryIntent.openTasks,
        .86,
        {'scope': ScheduleScope.all.name},
        'Opening your Smart Tasks.',
        const SecretaryAction(SecretaryActionType.navigateTasks, {
          'filter': 'all',
        }),
      );
    }

    if (_isCreateReminder(normalized)) {
      final entities = _extractReminderEntities(normalized);
      return _result(
        input,
        normalized,
        SecretaryIntent.createReminder,
        .84,
        entities,
        entities['title'] == null
            ? 'Of course. What should I remind you about?'
            : "I've created your reminder.",
        SecretaryAction(SecretaryActionType.createReminder, entities),
      );
    }

    if (_isHelp(normalized)) {
      return _result(
        input,
        normalized,
        SecretaryIntent.help,
        .92,
        {},
        'I can open your schedule, show tasks, create reminders, and manage important documents.',
        const SecretaryAction(SecretaryActionType.showHelp),
      );
    }

    return _result(
      input,
      normalized,
      SecretaryIntent.unknown,
      .25,
      {},
      "I didn't understand that yet. Try asking me to show your schedule or create a reminder.",
      const SecretaryAction(SecretaryActionType.clarify),
    );
  }

  IntentResult _result(
    String original,
    String normalized,
    SecretaryIntent intent,
    double confidence,
    Map<String, Object?> entities,
    String response,
    SecretaryAction action,
  ) => IntentResult(
    intent: intent,
    confidence: confidence,
    entities: entities,
    response: response,
    action: action,
    originalText: original,
    normalizedText: normalized,
  );

  bool _isViewSchedule(String t) =>
      _hasAny(t, [
        'schedule',
        'briefing',
        'what do i have',
        'tell me today',
        'today task',
        'today tasks',
        "today's tasks",
        'am i busy',
        'pending',
        'upcoming',
      ]) &&
      !_hasAny(t, ['set reminder', 'make reminder', 'create reminder']);

  bool _isOpenTasks(String t) =>
      _hasAny(t, ['smart task', 'show reminder', 'my reminder', 'task list']) ||
      t == 'task' ||
      t == 'todo';

  bool _isCreateReminder(String t) => _hasAny(t, [
    'remind me',
    'do not let me forget',
    'remember this',
    'make reminder',
    'set reminder',
    'schedule this',
    'create reminder',
  ]);

  bool _isDeleteTasks(String t, DeletionScope scope) =>
      _hasAny(t, ['delete', 'clear', 'remove']) &&
      (_hasAny(t, ['task', 'reminder', 'completed', 'missed']) ||
          scope != DeletionScope.unknown);

  bool _isHelp(String t) =>
      _hasAny(t, ['what can you do', 'help', 'commands', 'assist me']);

  ScheduleScope? _extractScheduleScope(String t) {
    if (_hasAny(t, ['today', 'pending today'])) {
      return ScheduleScope.today;
    }
    if (t.contains('tomorrow')) {
      return ScheduleScope.tomorrow;
    }
    if (_hasAny(t, ['this week', 'week schedule'])) {
      return ScheduleScope.thisWeek;
    }
    if (t.contains('completed')) {
      return ScheduleScope.completed;
    }
    if (t.contains('missed')) {
      return ScheduleScope.missed;
    }
    if (t.contains('upcoming')) {
      return ScheduleScope.upcoming;
    }
    if (t.contains('all')) {
      return ScheduleScope.all;
    }
    return null;
  }

  DeletionScope _extractDeletionScope(String t) {
    if (t.contains('completed')) {
      return DeletionScope.completed;
    }
    if (t.contains('missed')) {
      return DeletionScope.missed;
    }
    if (t.contains('all') || t.contains('clear reminder')) {
      return DeletionScope.all;
    }
    return DeletionScope.unknown;
  }

  Map<String, Object?> _extractReminderEntities(String t) {
    var title = t
        .replaceFirst(
          RegExp(
            r'^(please )?(remind me to|remind me|do not let me forget to|do not let me forget|remember this|make a? reminder|set a? reminder|schedule this|create a? reminder)\s*',
          ),
          '',
        )
        .trim();
    final scope = _extractScheduleScope(t);
    String? time;
    final match = RegExp(
      r'\b(at|by)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
    ).firstMatch(t);
    if (match != null) {
      time = match.group(0);
    }
    if (title.isEmpty) {
      title = '';
    }
    return {
      'title': title.isEmpty ? null : title,
      'date': scope?.name,
      'time': time,
      'priority': null,
    };
  }

  String _filterForScope(ScheduleScope scope) => switch (scope) {
    ScheduleScope.today => 'today',
    ScheduleScope.tomorrow => 'tomorrow',
    ScheduleScope.thisWeek => 'upcoming',
    ScheduleScope.upcoming => 'upcoming',
    ScheduleScope.completed => 'completed',
    ScheduleScope.missed => 'missed',
    ScheduleScope.all => 'all',
  };

  String _scheduleResponse(ScheduleScope scope) => switch (scope) {
    ScheduleScope.today => "Opening today's schedule.",
    ScheduleScope.tomorrow => "Opening tomorrow's schedule.",
    ScheduleScope.thisWeek => "Opening this week's schedule.",
    ScheduleScope.upcoming => 'Opening your upcoming tasks.',
    ScheduleScope.completed => 'Opening your completed tasks.',
    ScheduleScope.missed => 'Opening your missed tasks.',
    ScheduleScope.all => 'Opening your full schedule.',
  };

  String _deleteResponse(DeletionScope scope) => switch (scope) {
    DeletionScope.completed => 'Clearing completed tasks.',
    DeletionScope.missed => 'Clearing missed tasks.',
    DeletionScope.all => 'Clearing all tasks.',
    DeletionScope.unknown => 'Which tasks should I delete?',
  };

  SecretaryActionType? _documentCommand(
    String t, {
    required bool hasPendingAttachment,
  }) {
    final mentionsDocument = _hasAny(t, [
      'document',
      'aadhaar',
      'aadhar',
      'uid',
      'pan',
      'driving licence',
      'driving license',
      'dl',
      'voter id',
      'voter card',
      'certificate',
      'insurance',
      'medical record',
    ]);
    if (_hasAny(t, [
      'list my documents',
      'show documents',
      'important documents',
    ]))
      return SecretaryActionType.listDocuments;
    final saveLanguage = _hasAny(t, [
      'save',
      'store',
      'keep',
      'remember this as',
    ]) ||
        t.startsWith('this is my');

    if (hasPendingAttachment &&
        (saveLanguage ||
            _hasAny(t, ['save it', 'save this', 'keep it', 'keep this']))) {
      return SecretaryActionType.saveDocument;
    }

    if (!mentionsDocument) return null;
    if (saveLanguage) {
      return SecretaryActionType.saveDocument;
    }
    if (_hasAny(t, ['share', 'send'])) return SecretaryActionType.shareDocument;
    if (_hasAny(t, ['delete', 'remove']))
      return SecretaryActionType.deleteDocument;
    if (_hasAny(t, ['open', 'show', 'view']))
      return SecretaryActionType.openDocument;
    if (_hasAny(t, ['find', 'search'])) return SecretaryActionType.findDocument;
    return null;
  }

  String? _extractDocumentName(String t, SecretaryActionType command) {
    var value = t
        .replaceAll(RegExp(r'\b(please|document|file|old)\b'), ' ')
        .replaceAll(
          RegExp(
            r'\b(save|store|keep|show|open|view|find|search|share|send|delete|remove|this is|as|it as|this as|my|the|it|this)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (command == SecretaryActionType.listDocuments) return null;
    if (value.isEmpty) return null;
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  bool _hasAny(String text, List<String> patterns) =>
      patterns.any(text.contains);
}
