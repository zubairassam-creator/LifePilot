class SmartContact {
  final String id;
  final String displayName;
  final List<String> phones;
  final List<String> emails;

  const SmartContact({
    required this.id,
    required this.displayName,
    required this.phones,
    required this.emails,
  });

  factory SmartContact.fromMap(Map<dynamic, dynamic> map) {
    return SmartContact(
      id: '${map['id'] ?? ''}',
      displayName: '${map['displayName'] ?? 'Unnamed contact'}',
      phones: (map['phones'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => '$value')
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
      emails: (map['emails'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => '$value')
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
    );
  }
}
