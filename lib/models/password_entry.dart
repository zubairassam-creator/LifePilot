class PasswordEntry {
  final String id;
  final String serviceName;
  final String username;
  final String password;
  final String website;
  final String category;
  final String notes;
  final bool favourite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PasswordEntry({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.password,
    this.website = '',
    this.category = 'Other',
    this.notes = '',
    this.favourite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  PasswordEntry copyWith({
    String? serviceName,
    String? username,
    String? password,
    String? website,
    String? category,
    String? notes,
    bool? favourite,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id,
      serviceName: serviceName ?? this.serviceName,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      favourite: favourite ?? this.favourite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'password': password,
        'website': website,
        'category': category,
        'notes': notes,
        'favourite': favourite,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      website: json['website'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      notes: json['notes'] as String? ?? '',
      favourite: json['favourite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
