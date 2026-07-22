enum LifeMemoryType {
  task,
  reminder,
  event,
  birthday,
  documentLocation,
  personalFact,
  financialObligation,
  loanGiven,
  loanTaken,
  expiry,
  followUp,
  person,
  relationship,
  note,
}

enum LifeMemoryStatus { open, completed, archived, deleted }

enum SyncStatus { pendingCreate, pendingUpdate, pendingDelete, synced, failed }

class LifeMemory {
  final String id;
  final String? cloudId;
  final String originalStatement;
  final String title;
  final LifeMemoryType type;
  final String? person;
  final String? subject;
  final String? description;
  final DateTime? eventDate;
  final DateTime? dueDate;
  final DateTime? reminderDateTime;
  final String? recurrence;
  final double? amount;
  final String? currency;
  final String? location;
  final LifeMemoryStatus status;
  final int priority;
  final String? relatedPersonId;
  final List<String> relatedMemoryIds;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final int retryCount;

  const LifeMemory({
    required this.id,
    this.cloudId,
    required this.originalStatement,
    required this.title,
    required this.type,
    this.person,
    this.subject,
    this.description,
    this.eventDate,
    this.dueDate,
    this.reminderDateTime,
    this.recurrence,
    this.amount,
    this.currency,
    this.location,
    this.status = LifeMemoryStatus.open,
    this.priority = 0,
    this.relatedPersonId,
    this.relatedMemoryIds = const [],
    this.confidence = 1,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pendingCreate,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cloudId': cloudId,
    'originalStatement': originalStatement,
    'title': title,
    'type': type.name,
    'person': person,
    'subject': subject,
    'description': description,
    'eventDate': eventDate?.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'reminderDateTime': reminderDateTime?.toIso8601String(),
    'recurrence': recurrence,
    'amount': amount,
    'currency': currency,
    'location': location,
    'status': status.name,
    'priority': priority,
    'relatedPersonId': relatedPersonId,
    'relatedMemoryIds': relatedMemoryIds,
    'confidence': confidence,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
    'syncStatus': syncStatus.name,
    'retryCount': retryCount,
  };

  factory LifeMemory.fromJson(Map<dynamic, dynamic> json) => LifeMemory(
    id: json['id'] as String,
    cloudId: json['cloudId'] as String?,
    originalStatement: json['originalStatement'] as String? ?? '',
    title: json['title'] as String? ?? '',
    type: LifeMemoryType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => LifeMemoryType.note,
    ),
    person: json['person'] as String?,
    subject: json['subject'] as String?,
    description: json['description'] as String?,
    eventDate: _date(json['eventDate']),
    dueDate: _date(json['dueDate']),
    reminderDateTime: _date(json['reminderDateTime']),
    recurrence: json['recurrence'] as String?,
    amount: (json['amount'] as num?)?.toDouble(),
    currency: json['currency'] as String?,
    location: json['location'] as String?,
    status: LifeMemoryStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => LifeMemoryStatus.open,
    ),
    priority: json['priority'] as int? ?? 0,
    relatedPersonId: json['relatedPersonId'] as String?,
    relatedMemoryIds: List<String>.from(json['relatedMemoryIds'] ?? const []),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
    createdAt: _date(json['createdAt']) ?? DateTime.now(),
    updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    isDeleted: json['isDeleted'] as bool? ?? false,
    syncStatus: SyncStatus.values.firstWhere(
      (e) => e.name == json['syncStatus'],
      orElse: () => SyncStatus.pendingCreate,
    ),
    retryCount: json['retryCount'] as int? ?? 0,
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
