class EntityExtractor {
  static Map<String, String> extract(String text) {
    final input = text.toLowerCase();

    final Map<String, String> entities = {};

    // -------- Event --------

    if (input.contains('birthday') || input.contains("b'day")) {
      entities['event'] = 'Birthday';
    }

    if (input.contains('bill')) {
      entities['event'] = 'Bill';
    }

    if (input.contains('appointment')) {
      entities['event'] = 'Appointment';
    }

    if (input.contains('meeting')) {
      entities['event'] = 'Meeting';
    }

    // -------- Documents --------

    if (input.contains('pollution')) {
      entities['document'] = 'Pollution Certificate';
    }

    if (input.contains('passport')) {
      entities['document'] = 'Passport';
    }

    if (input.contains('driving licence') ||
        input.contains('driving license')) {
      entities['document'] = 'Driving Licence';
    }

    if (input.contains('aadhaar')) {
      entities['document'] = 'Aadhaar';
    }

    if (input.contains('pan')) {
      entities['document'] = 'PAN';
    }

    return entities;
  }
}
