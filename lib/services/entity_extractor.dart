class EntityExtractor {
  static Map<String, String> extract(String text) {
    final input = text.toLowerCase();

    final Map<String, String> entities = {};

    // =========================
    // EVENTS
    // =========================

    if (input.contains('birthday') || input.contains("b'day")) {
      entities['event'] = 'Birthday';
    }

    if (input.contains('anniversary')) {
      entities['event'] = 'Anniversary';
    }

    if (input.contains('meeting')) {
      entities['event'] = 'Meeting';
    }

    if (input.contains('appointment')) {
      entities['event'] = 'Appointment';
    }

    if (input.contains('call')) {
      entities['event'] = 'Call';
    }

    if (input.contains('email') || input.contains('mail')) {
      entities['event'] = 'Email';
    }

    if (input.contains('shopping')) {
      entities['event'] = 'Shopping';
    }

    // =========================
    // DOCUMENTS
    // =========================

    if (input.contains('passport')) {
      entities['document'] = 'Passport';
    }

    if (input.contains('driving licence') ||
        input.contains('driving license')) {
      entities['document'] = 'Driving Licence';
    }

    if (input.contains('pollution')) {
      entities['document'] = 'Pollution Certificate';
    }

    if (input.contains('aadhaar') || input.contains('aadhar')) {
      entities['document'] = 'Aadhaar';
    }

    if (input.contains('pan')) {
      entities['document'] = 'PAN';
    }

    // =========================
    // HEALTH
    // =========================

    if (input.contains('medicine') ||
        input.contains('tablet') ||
        input.contains('capsule')) {
      entities['health'] = 'Medicine';
    }

    if (input.contains('doctor')) {
      entities['health'] = 'Doctor';
    }

    if (input.contains('hospital')) {
      entities['health'] = 'Hospital';
    }

    // =========================
    // RELATIONSHIPS
    // =========================

    if (input.contains('mother') || input.contains('mom')) {
      entities['relationship'] = 'Mother';
    }

    if (input.contains('father') || input.contains('dad')) {
      entities['relationship'] = 'Father';
    }

    if (input.contains('wife')) {
      entities['relationship'] = 'Wife';
    }

    if (input.contains('husband')) {
      entities['relationship'] = 'Husband';
    }

    if (input.contains('son')) {
      entities['relationship'] = 'Son';
    }

    if (input.contains('daughter')) {
      entities['relationship'] = 'Daughter';
    }

    if (input.contains('brother')) {
      entities['relationship'] = 'Brother';
    }

    if (input.contains('sister')) {
      entities['relationship'] = 'Sister';
    }

    if (input.contains('friend')) {
      entities['relationship'] = 'Friend';
    }

    // =========================
    // COMMON NAMES (Starter Set)
    // =========================

    final names = [
      'nazrana',
      'rifa',
      'maruf',
      'abdul',
      'siraj',
      'ayesha',
      'basit',
      'jubair',
      'zubair',
    ];

    for (final name in names) {
      if (input.contains(name)) {
        entities['person'] = _capitalize(name);
        break;
      }
    }

    return entities;
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1);
  }
}
