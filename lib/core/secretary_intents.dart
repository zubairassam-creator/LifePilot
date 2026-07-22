enum SecretaryIntent {
  viewSchedule,
  retrieveSchedule,
  createReminder,
  storeMemory,
  storeLocation,
  storeEvent,
  storeExpiry,
  storeFinancialObligation,
  retrieveMemory,
  retrieveFinancialObligation,
  openTasks,
  deleteTasks,
  saveDocument,
  findDocument,
  openDocument,
  shareDocument,
  deleteDocument,
  listDocuments,
  help,
  unknown,
}

enum ScheduleScope {
  today,
  tomorrow,
  thisWeek,
  upcoming,
  completed,
  missed,
  all,
}

enum DeletionScope { completed, missed, all, unknown }

enum SecretaryActionType {
  navigateTasks,
  showBriefing,
  createReminder,
  deleteTasks,
  saveDocument,
  findDocument,
  openDocument,
  shareDocument,
  deleteDocument,
  listDocuments,
  showHelp,
  clarify,
}

class IntentResult {
  final SecretaryIntent intent;
  final double confidence;
  final Map<String, Object?> entities;
  final String response;
  final SecretaryAction action;
  final String originalText;
  final String normalizedText;

  const IntentResult({
    required this.intent,
    required this.confidence,
    required this.entities,
    required this.response,
    required this.action,
    required this.originalText,
    required this.normalizedText,
  });
}

class SecretaryAction {
  final SecretaryActionType type;
  final Map<String, Object?> payload;

  const SecretaryAction(this.type, [this.payload = const {}]);
}
