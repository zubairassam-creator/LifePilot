import 'dart:convert';

enum DocumentCategory {
  identity,
  education,
  medical,
  vehicle,
  insurance,
  property,
  banking,
  billsAndReceipts,
  government,
  other,
}

extension DocumentCategoryLabel on DocumentCategory {
  String get label => switch (this) {
    DocumentCategory.identity => 'Identity',
    DocumentCategory.education => 'Education',
    DocumentCategory.medical => 'Medical',
    DocumentCategory.vehicle => 'Vehicle',
    DocumentCategory.insurance => 'Insurance',
    DocumentCategory.property => 'Property',
    DocumentCategory.banking => 'Banking',
    DocumentCategory.billsAndReceipts => 'Bills and Receipts',
    DocumentCategory.government => 'Government',
    DocumentCategory.other => 'Other',
  };

  bool get defaultsSensitive => switch (this) {
    DocumentCategory.identity ||
    DocumentCategory.medical ||
    DocumentCategory.insurance ||
    DocumentCategory.property ||
    DocumentCategory.banking ||
    DocumentCategory.government => true,
    _ => false,
  };
}

class PendingDocumentAttachment {
  final String path;
  final String fileName;
  final String mimeType;
  final String extension;
  final int fileSizeBytes;

  const PendingDocumentAttachment({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.extension,
    required this.fileSizeBytes,
  });

  bool get isImage => mimeType.startsWith('image/');
}

class LifePilotDocument {
  final String id;
  final String displayName;
  final String originalFileName;
  final String encryptedFilePath;
  final String mimeType;
  final String extension;
  final int fileSizeBytes;
  final DocumentCategory category;
  final bool isSensitive;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LifePilotDocument({
    required this.id,
    required this.displayName,
    required this.originalFileName,
    required this.encryptedFilePath,
    required this.mimeType,
    required this.extension,
    required this.fileSizeBytes,
    required this.category,
    required this.isSensitive,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  LifePilotDocument copyWith({
    String? displayName,
    DocumentCategory? category,
    bool? isSensitive,
    String? description,
    DateTime? updatedAt,
  }) => LifePilotDocument(
    id: id,
    displayName: displayName ?? this.displayName,
    originalFileName: originalFileName,
    encryptedFilePath: encryptedFilePath,
    mimeType: mimeType,
    extension: extension,
    fileSizeBytes: fileSizeBytes,
    category: category ?? this.category,
    isSensitive: isSensitive ?? this.isSensitive,
    description: description ?? this.description,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'originalFileName': originalFileName,
    'encryptedFilePath': encryptedFilePath,
    'mimeType': mimeType,
    'extension': extension,
    'fileSizeBytes': fileSizeBytes,
    'category': category.name,
    'isSensitive': isSensitive,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LifePilotDocument.fromJson(Map<String, Object?> json) =>
      LifePilotDocument(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        originalFileName: json['originalFileName'] as String,
        encryptedFilePath: json['encryptedFilePath'] as String,
        mimeType: json['mimeType'] as String,
        extension: json['extension'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        category: DocumentCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => DocumentCategory.other,
        ),
        isSensitive: json['isSensitive'] as bool,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  String encode() => jsonEncode(toJson());
  factory LifePilotDocument.decode(String value) =>
      LifePilotDocument.fromJson(jsonDecode(value) as Map<String, Object?>);
}
