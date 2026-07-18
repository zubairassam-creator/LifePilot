import '../models/life_memory.dart';
import '../models/lifepilot_task.dart';
import '../services/life_memory_repository.dart';
import '../services/notification_service.dart';
import '../services/task_storage_service.dart';
import 'date_time_interpreter.dart';
import 'input_normalizer.dart';
import 'secretary_intents.dart';

class SecretaryBrain {
  SecretaryBrain({DateTimeInterpreter interpreter = const DateTimeInterpreter()})
      : _dates = interpreter;

  final DateTimeInterpreter _dates;
  final InputNormalizer _normalizer = const InputNormalizer();
  String? _lastPerson;

  Future<IntentResult> processUserInput(String input) async {
    final normalized = _normalizer.normalize(input);
    final now = DateTime.now();

    IntentResult result(String response, SecretaryIntent intent, double confidence,
            Map<String, Object?> entities, SecretaryAction action) =>
        IntentResult(intent: intent, confidence: confidence, entities: entities,
            response: response, action: action, originalText: input, normalizedText: normalized);

    if (normalized.isEmpty) {
      return result("I'm here when you're ready.", SecretaryIntent.unknown, 0, {},
          const SecretaryAction(SecretaryActionType.clarify));
    }

    if (_isLocationRecall(normalized)) {
      final item = normalized.replaceAll(RegExp(r'where (is|did i keep|have i kept)|my|\?'), '').trim();
      final match = LifeMemoryRepository.search(item).where((m) => m.type == LifeMemoryType.documentLocation).cast<LifeMemory?>().firstWhere((m) => m != null, orElse: () => null);
      if (match != null) {
        return result('Your ${match.subject ?? match.title} is in ${match.location}.',
            SecretaryIntent.retrieveMemory, .92, {'memoryId': match.id}, const SecretaryAction(SecretaryActionType.showHelp));
      }
      return result("I couldn't find where that is saved yet.", SecretaryIntent.retrieveMemory, .6, {}, const SecretaryAction(SecretaryActionType.showHelp));
    }

    if (normalized.contains('how much do i owe') || normalized.contains('when do i need to repay') || normalized.contains('unpaid loans')) {
      final person = _personAfter(normalized, 'owe') ?? _personAfter(normalized, 'repay') ?? (normalized.contains('him') ? _lastPerson : null);
      final loans = LifeMemoryRepository.getAll().where((m) => m.type == LifeMemoryType.loanTaken && m.status == LifeMemoryStatus.open && (person == null || _sameName(m.person, person))).toList();
      if (loans.isEmpty) {
        return result('I do not see an open loan${person == null ? '' : ' for $person'}.', SecretaryIntent.retrieveFinancialObligation, .82, {}, const SecretaryAction(SecretaryActionType.showHelp));
      }
      final loan = loans.first;
      _lastPerson = loan.person;
      final due = loan.dueDate == null ? '' : ' due on ${_formatDate(loan.dueDate!)}';
      return result('You owe ${loan.currency ?? ''}${_formatAmount(loan.amount)} to ${loan.person}$due.', SecretaryIntent.retrieveFinancialObligation, .9, {'memoryId': loan.id}, const SecretaryAction(SecretaryActionType.showHelp));
    }

    if (_isSchedule(normalized)) {
      final scope = normalized.contains('tomorrow') ? ScheduleScope.tomorrow : normalized.contains('missed') ? ScheduleScope.missed : normalized.contains('completed') ? ScheduleScope.completed : ScheduleScope.today;
      final count = _taskCount(scope);
      final label = scope == ScheduleScope.tomorrow ? 'Tomorrow' : scope == ScheduleScope.today ? 'Today' : scope.name;
      return result(count == 0 ? '$label is currently free.' : 'You have $count task(s) for ${label.toLowerCase()}. Opening ${label.toLowerCase()} schedule.', SecretaryIntent.retrieveSchedule, .9, {'scope': scope.name}, SecretaryAction(SecretaryActionType.navigateTasks, {'filter': _filter(scope)}));
    }

    if (normalized.startsWith('remind me')) {
      final due = _dates.dateTimeFromText(normalized);
      final action = normalized.replaceFirst(RegExp(r'^remind me\s+'), '').replaceAll(RegExp(r'\b(today|tomorrow|at \d{1,2}(:\d{2})?\s*(am|pm)?)\b'), '').trim();
      if (due == null) return result('When should I remind you?', SecretaryIntent.createReminder, .62, {}, const SecretaryAction(SecretaryActionType.clarify));
      await _saveTask(action.replaceFirst(RegExp(r'^to\s+'), ''), due, ReminderMode.normal);
      return result("I've created your reminder for ${_formatDateTime(due)}.", SecretaryIntent.createReminder, .9, {'dueDate': due.toIso8601String()}, const SecretaryAction(SecretaryActionType.createReminder));
    }

    if (normalized.contains('birth certificate') && RegExp(r'\b(in|inside|blue file|kept)\b').hasMatch(normalized)) {
      final location = RegExp(r'\bin (?:the )?(.+)$').firstMatch(normalized)?.group(1) ?? 'the saved location';
      await LifeMemoryRepository.save(_memory(now, input, 'Original birth certificate location', LifeMemoryType.documentLocation, subject: 'original birth certificate', location: location));
      return result('Your original birth certificate is in $location.', SecretaryIntent.storeLocation, .9, {'location': location}, const SecretaryAction(SecretaryActionType.showHelp));
    }

    if (normalized.contains('birthday')) {
      final person = RegExp(r'^([a-z ]+?)(?:s|\'s)? birthday').firstMatch(normalized)?.group(1)?.trim();
      final date = _dates.dateFromText(normalized);
      if (person == null || date == null) return result('Whose birthday and date should I save?', SecretaryIntent.storeEvent, .5, {}, const SecretaryAction(SecretaryActionType.clarify));
      _lastPerson = _titleCase(person);
      await LifeMemoryRepository.save(_memory(now, input, '${_titleCase(person)} birthday', LifeMemoryType.birthday, person: _titleCase(person), eventDate: date, recurrence: 'yearly'));
      await _saveTask('${_titleCase(person)} birthday', date.subtract(const Duration(days: 7)), ReminderMode.normal, RepeatType.yearly);
      return result("I've saved ${_titleCase(person)}'s birthday as ${_formatMonthDay(date)} and will remind you in advance every year.", SecretaryIntent.storeEvent, .92, {}, const SecretaryAction(SecretaryActionType.showHelp));
    }

    if (normalized.contains('loan') || normalized.contains('borrowed')) {
      final amount = RegExp(r'(?:₹|rs\.?\s*)\s?([\d,]+)').firstMatch(input.toLowerCase())?.group(1)?.replaceAll(',', '');
      final person = RegExp(r'from ([a-z ]+?)(?: and|$)').firstMatch(normalized)?.group(1)?.trim();
      final due = _dates.dateFromText(normalized);
      if (person == null || amount == null) return result('Who is the loan with, and how much is it?', SecretaryIntent.storeFinancialObligation, .55, {}, const SecretaryAction(SecretaryActionType.clarify));
      _lastPerson = _titleCase(person);
      await LifeMemoryRepository.save(_memory(now, input, 'Loan from ${_titleCase(person)}', LifeMemoryType.loanTaken, person: _titleCase(person), amount: double.parse(amount), currency: '₹', dueDate: due));
      if (due != null) await _saveTask('Repay ₹${_formatAmount(double.parse(amount))} to ${_titleCase(person)}', due.subtract(const Duration(days: 7)), ReminderMode.normal);
      return result('You borrowed ₹${_formatAmount(double.parse(amount))} from ${_titleCase(person)}. I’ve recorded the repayment${due == null ? '' : ' due ${_formatDate(due)}'} and will remind you beforehand.', SecretaryIntent.storeFinancialObligation, .92, {}, const SecretaryAction(SecretaryActionType.showHelp));
    }

    if (normalized.contains('expir')) {
      final date = _dates.dateFromText(normalized);
      if (date == null) return result('Which month and date does it expire?', SecretaryIntent.storeExpiry, .55, {}, const SecretaryAction(SecretaryActionType.clarify));
      final subject = normalized.replaceAll(RegExp(r'\b(my|is|expiring|expires|on|certificate)\b'), '').replaceAll(RegExp(r'\b\d{1,2}(st|nd|rd|th)?\b|november|january|february|march|april|may|june|july|august|september|october|december'), '').trim();
      await LifeMemoryRepository.save(_memory(now, input, '$subject expiry', LifeMemoryType.expiry, subject: '$subject certificate', dueDate: date));
      for (final days in [30, 7, 0]) { final reminder = date.subtract(Duration(days: days)); if (reminder.isAfter(now)) await _saveTask('Renew $subject certificate', reminder, ReminderMode.normal); }
      return result('Your $subject certificate expires on ${_formatMonthDay(date)}. I’ve saved it and will remind you before it expires.', SecretaryIntent.storeExpiry, .9, {}, const SecretaryAction(SecretaryActionType.showHelp));
    }

    return result("I’m not fully sure how to save that. Could you say if it is a reminder, memory, date, or question?", SecretaryIntent.unknown, .3, {}, const SecretaryAction(SecretaryActionType.clarify));
  }

  LifeMemory _memory(DateTime now, String original, String title, LifeMemoryType type, {String? person, String? subject, String? location, DateTime? eventDate, DateTime? dueDate, String? recurrence, double? amount, String? currency}) => LifeMemory(id: now.microsecondsSinceEpoch.toString(), originalStatement: original, title: title.trim(), type: type, person: person, subject: subject, location: location, eventDate: eventDate, dueDate: dueDate, recurrence: recurrence, amount: amount, currency: currency, createdAt: now, updatedAt: now);

  Future<void> _saveTask(String title, DateTime due, ReminderMode mode, [RepeatType repeat = RepeatType.none]) async { final now = DateTime.now(); final task = LifePilotTask(id: now.microsecondsSinceEpoch.toString(), title: title, dueDateTime: due, reminderEnabled: true, reminderMode: mode, repeatType: repeat, isAiGenerated: true, createdAt: now, updatedAt: now); await TaskStorageService.addTask(task); try { if (due.isAfter(now)) await NotificationService.scheduleTask(task); } catch (_) {} }
  bool _isLocationRecall(String t) => t.startsWith('where is') || t.startsWith('where did i keep');
  bool _isSchedule(String t) => t.contains('schedule') || t.contains('what do i have') || t.contains('am i busy') || t.contains('tomorrow work') || t.contains('did i miss');
  int _taskCount(ScheduleScope s) { final tasks = TaskStorageService.getAllTasks(); final now = DateTime.now(); return tasks.where((t) { final due = t.dueDateTime; if (s == ScheduleScope.completed) return t.status == TaskStatus.completed; if (s == ScheduleScope.missed) return t.status != TaskStatus.completed && due != null && due.isBefore(now); if (due == null || t.status != TaskStatus.pending) return false; final target = s == ScheduleScope.tomorrow ? DateTime(now.year, now.month, now.day + 1) : DateTime(now.year, now.month, now.day); return due.year == target.year && due.month == target.month && due.day == target.day; }).length; }
  String _filter(ScheduleScope s) => s == ScheduleScope.tomorrow ? 'tomorrow' : s == ScheduleScope.completed ? 'completed' : s == ScheduleScope.missed ? 'missed' : 'today';
  String? _personAfter(String t, String word) => RegExp('$word ([a-z ]+)\$').firstMatch(t)?.group(1)?.trim();
  bool _sameName(String? a, String b) => a?.toLowerCase().replaceAll(' ', '') == b.toLowerCase().replaceAll(' ', '');
  String _titleCase(String s) => s.split(' ').where((p) => p.isNotEmpty).map((p) => '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _formatMonthDay(DateTime d) => '${d.day} ${['','January','February','March','April','May','June','July','August','September','October','November','December'][d.month]}';
  String _formatDateTime(DateTime d) => '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _formatAmount(double? a) => a == null ? '' : a.toStringAsFixed(a.truncateToDouble() == a ? 0 : 2);
}
