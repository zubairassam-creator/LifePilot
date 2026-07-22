import 'dart:convert';

class SecureMemoryAttachment {
  final String id;
  final String fileName;
  final String encryptedPath;
  final String mimeType;
  final int fileSizeBytes;

  const SecureMemoryAttachment({
    required this.id,
    required this.fileName,
    required this.encryptedPath,
    required this.mimeType,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'encryptedPath': encryptedPath,
    'mimeType': mimeType,
    'fileSizeBytes': fileSizeBytes,
  };

  factory SecureMemoryAttachment.fromJson(Map<String, dynamic> json) =>
      SecureMemoryAttachment(
        id: json['id'] as String,
        fileName: json['fileName'] as String? ?? 'Attachment',
        encryptedPath: json['encryptedPath'] as String,
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      );
}

class SecureMemoryNote {
  final String id;
  final String title;
  final String body;
  final DateTime noteDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SecureMemoryAttachment> attachments;

  const SecureMemoryNote({
    required this.id,
    required this.title,
    required this.body,
    required this.noteDate,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  SecureMemoryNote copyWith({
    String? title,
    String? body,
    DateTime? noteDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SecureMemoryAttachment>? attachments,
  }) => SecureMemoryNote(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    noteDate: noteDate ?? this.noteDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    attachments: attachments ?? this.attachments,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'noteDate': noteDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory SecureMemoryNote.decode(String value) =>
      SecureMemoryNote.fromJson(jsonDecode(value) as Map<String, dynamic>);

  factory SecureMemoryNote.fromJson(Map<String, dynamic> json) =>
      SecureMemoryNote(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        noteDate:
            DateTime.tryParse(json['noteDate'] as String? ?? '') ??
            DateTime.now(),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        attachments: ((json['attachments'] as List<dynamic>?) ?? const [])
            .map(
              (item) => SecureMemoryAttachment.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
}
