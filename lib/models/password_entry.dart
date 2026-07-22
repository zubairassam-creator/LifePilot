import 'package:flutter/foundation.dart';

enum PasswordCategory {
  social,
  banking,
  government,
  education,
  shopping,
  office,
  personal,
  other;

  String get label => switch (this) {
        PasswordCategory.social => 'Social',
        PasswordCategory.banking => 'Banking',
        PasswordCategory.government => 'Government',
        PasswordCategory.education => 'Education',
        PasswordCategory.shopping => 'Shopping',
        PasswordCategory.office => 'Office',
        PasswordCategory.personal => 'Personal',
        PasswordCategory.other => 'Other',
      };

  static PasswordCategory fromLabel(String value) => PasswordCategory.values.firstWhere(
        (category) => category.label.toLowerCase() == value.toLowerCase(),
        orElse: () => PasswordCategory.other,
      );
}

@immutable
class PasswordEntry {
  final String id;
  final String serviceName;
  final String username;
  final String encryptedPassword;
  final String website;
  final PasswordCategory category;
  final String notes;
  final DateTime dateCreated;
  final DateTime lastModified;
  final bool favourite;

  const PasswordEntry({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.encryptedPassword,
    required this.website,
    required this.category,
    required this.notes,
    required this.dateCreated,
    required this.lastModified,
    required this.favourite,
  });

  PasswordEntry copyWith({
    String? serviceName,
    String? username,
    String? encryptedPassword,
    String? website,
    PasswordCategory? category,
    String? notes,
    DateTime? lastModified,
    bool? favourite,
  }) => PasswordEntry(
        id: id,
        serviceName: serviceName ?? this.serviceName,
        username: username ?? this.username,
        encryptedPassword: encryptedPassword ?? this.encryptedPassword,
        website: website ?? this.website,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        dateCreated: dateCreated,
        lastModified: lastModified ?? this.lastModified,
        favourite: favourite ?? this.favourite,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'encryptedPassword': encryptedPassword,
        'website': website,
        'category': category.label,
        'notes': notes,
        'dateCreated': dateCreated.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'favourite': favourite,
      };

  factory PasswordEntry.fromMap(Map<dynamic, dynamic> map) => PasswordEntry(
        id: map['id'] as String,
        serviceName: map['serviceName'] as String? ?? '',
        username: map['username'] as String? ?? '',
        encryptedPassword: map['encryptedPassword'] as String? ?? '',
        website: map['website'] as String? ?? '',
        category: PasswordCategory.fromLabel(map['category'] as String? ?? 'Other'),
        notes: map['notes'] as String? ?? '',
        dateCreated: DateTime.tryParse(map['dateCreated'] as String? ?? '') ?? DateTime.now(),
        lastModified: DateTime.tryParse(map['lastModified'] as String? ?? '') ?? DateTime.now(),
        favourite: map['favourite'] as bool? ?? false,
      );
}
