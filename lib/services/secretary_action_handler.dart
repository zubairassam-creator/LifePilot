import 'package:flutter/material.dart';

import '../core/secretary_intents.dart';
import '../models/lifepilot_document.dart';
import '../models/lifepilot_task.dart';
import '../screens/document_details_screen.dart';
import '../screens/important_documents_screen.dart';
import '../screens/my_tasks_screen.dart';
import '../widgets/briefing_dialog.dart';
import '../widgets/document_save_sheet.dart';
import 'document_auth_service.dart';
import 'document_share_service.dart';
import 'document_storage_service.dart';
import 'task_storage_service.dart';

typedef AssistantReply = Future<void> Function(String message, {bool speak});
typedef PendingAttachmentReader = PendingDocumentAttachment? Function();
typedef PendingAttachmentClearer = void Function();

class SecretaryActionHandler {
  SecretaryActionHandler({
    required this.context,
    required this.reply,
    this.pendingAttachment,
    this.clearPendingAttachment,
  });

  final BuildContext context;
  final AssistantReply reply;
  final PendingAttachmentReader? pendingAttachment;
  final PendingAttachmentClearer? clearPendingAttachment;

  bool get _mounted => context.mounted;

  Future<void> execute(SecretaryAction action) async {
    if (!_mounted) return;

    switch (action.type) {
      case SecretaryActionType.navigateTasks:
        final filter = _taskFilter(action.payload['filter'] as String?);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SmartRemindersScreen(initialFilter: filter)),
        );
        return;
      case SecretaryActionType.showBriefing:
        await showBriefingDialog(context, mode: BriefingDialogMode.schedule, speakAutomatically: true);
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
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportantDocumentsScreen()));
        return;
      case SecretaryActionType.openContacts:
        await reply('Contacts are available from the dashboard.', speak: true);
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
        case 'completed': return task.status == TaskStatus.completed;
        case 'missed': return missed;
        case 'all': return true;
        default: return false;
      }
    }).toList();
    for (final task in deletable) { await TaskStorageService.deleteTask(task.id); }
  }

  Future<void> _savePendingDocument(String? name) async {
    final attachment = pendingAttachment?.call();
    if (attachment == null) { await reply('Please attach or capture the document you want me to save.', speak: true); return; }
    final data = await DocumentSaveSheet.show(context, attachment, name ?? _titleFromFile(attachment.fileName));
    if (data == null) return;
    if (data.sensitive) {
      final auth = await DocumentAuthService.instance.authenticate('Authenticate to save this sensitive document');
      if (!auth.success) { await reply(auth.message ?? 'Authentication failed.', speak: true); return; }
    }
    try {
      await DocumentStorageService.instance.save(attachment: attachment, displayName: data.name, category: data.category, isSensitive: data.sensitive, description: data.description);
      clearPendingAttachment?.call();
      await reply('Your ${data.name} has been saved securely.', speak: true);
    } catch (_) {
      await reply('Could not save this document securely.', speak: true);
    }
  }

  Future<void> _openDocumentCommand(String? name) async {
    if (name == null) { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportantDocumentsScreen())); return; }
    final matches = DocumentStorageService.instance.findMatches(name);
    if (matches.isEmpty) { await reply(_documentNotFoundMessage(name), speak: true); return; }
    if (matches.length > 1) { await reply('I found several matching documents. Please choose one.', speak: true); await Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportantDocumentsScreen())); return; }
    final doc = matches.single;
    await reply('I found your ${doc.displayName}.', speak: true);
    if (doc.isSensitive) { final auth = await DocumentAuthService.instance.authenticate('Authenticate to open this document'); if (!auth.success) return; }
    if (!_mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailsScreen(document: doc)));
  }

  Future<void> _shareDocumentCommand(String? name) async {
    final matches = name == null ? <LifePilotDocument>[] : DocumentStorageService.instance.findMatches(name);
    if (matches.length > 1) { await reply('I found several matching documents. Please choose one.', speak: true); return; }
    final doc = matches.isEmpty ? null : matches.single;
    if (doc == null) { await reply(name == null ? 'Which document should I share?' : _documentNotFoundMessage(name), speak: true); return; }
    final auth = await DocumentAuthService.instance.authenticate('Authenticate to share this document');
    if (!auth.success) return;
    try { await DocumentShareService.instance.share(doc); await reply('Your ${doc.displayName} is ready to share.', speak: true); } catch (_) { await reply('Could not share this document.', speak: true); }
  }

  Future<void> _deleteDocumentCommand(String? name) async {
    final matches = name == null ? <LifePilotDocument>[] : DocumentStorageService.instance.findMatches(name);
    if (matches.length > 1) { await reply('I found several matching documents. Please choose one.', speak: true); return; }
    final doc = matches.isEmpty ? null : matches.single;
    if (doc == null) { await reply(name == null ? 'Which document should I delete?' : _documentNotFoundMessage(name), speak: true); return; }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailsScreen(document: doc)));
  }

  ReminderFilter _taskFilter(String? value) => switch (value) {
    'today' => ReminderFilter.today, 'tomorrow' => ReminderFilter.tomorrow, 'upcoming' => ReminderFilter.upcoming,
    'completed' => ReminderFilter.completed, 'missed' => ReminderFilter.missed, _ => ReminderFilter.all,
  };

  String _documentNotFoundMessage(String name) => "I couldn't find a document named $name. You can save it first if you haven't already.";
  String _titleFromFile(String f) { final base = f.replaceFirst(RegExp(r'\.[^.]+$'), '').replaceAll(RegExp(r'[_-]+'), ' '); return base.split(' ').where((w) => w.isNotEmpty).map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' '); }
}
