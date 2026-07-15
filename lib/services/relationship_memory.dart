class RelationshipMemory {
  static final Map<String, String> _relationships = {};

  static void remember(String name, String relationship) {
    _relationships[name.toLowerCase()] = relationship;
  }

  static String? getRelationship(String name) {
    return _relationships[name.toLowerCase()];
  }

  static Map<String, String> getAll() {
    return Map.from(_relationships);
  }
}
