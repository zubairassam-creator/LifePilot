class TaskClassifier {
  static String classify(String text) {
    final input = text.toLowerCase();

    // =========================
    // FAMILY
    // =========================

    if (input.contains('birthday') ||
        input.contains("b'day") ||
        input.contains('birth day')) {
      return 'Birthday';
    }

    if (input.contains('anniversary') ||
        input.contains('marriage anniversary') ||
        input.contains('wedding anniversary')) {
      return 'Anniversary';
    }

    // =========================
    // HEALTH
    // =========================

    if (input.contains('medicine') ||
        input.contains('tablet') ||
        input.contains('capsule') ||
        input.contains('take medicine') ||
        input.contains('medication')) {
      return 'Medicine';
    }

    if (input.contains('doctor') || input.contains('appointment')) {
      return 'Appointment';
    }

    if (input.contains('hospital')) {
      return 'Hospital';
    }

    if (input.contains('test') ||
        input.contains('blood test') ||
        input.contains('x-ray') ||
        input.contains('scan')) {
      return 'Medical Test';
    }

    // =========================
    // DOCUMENTS
    // =========================

    if (input.contains('passport')) {
      return 'Passport';
    }

    if (input.contains('driving licence') ||
        input.contains('driving license') ||
        input.contains('licence renewal') ||
        input.contains('license renewal')) {
      return 'Driving Licence';
    }

    if (input.contains('pollution')) {
      return 'Pollution Certificate';
    }

    if (input.contains('aadhaar') || input.contains('aadhar')) {
      return 'Aadhaar';
    }

    if (input.contains('pan card') || input.contains('pan')) {
      return 'PAN';
    }

    // =========================
    // FINANCE
    // =========================

    if (input.contains('bill') ||
        input.contains('electricity') ||
        input.contains('water bill') ||
        input.contains('mobile recharge') ||
        input.contains('internet bill')) {
      return 'Bill';
    }

    if (input.contains('insurance')) {
      return 'Insurance';
    }

    if (input.contains('salary')) {
      return 'Salary';
    }

    if (input.contains('fees') ||
        input.contains('school fees') ||
        input.contains('college fees')) {
      return 'Fees';
    }

    if (input.contains('rent')) {
      return 'Rent';
    }

    if (input.contains('emi')) {
      return 'EMI';
    }

    // =========================
    // HOME
    // =========================

    if (input.contains('shopping') || input.contains('buy')) {
      return 'Shopping';
    }

    if (input.contains('grocery') || input.contains('groceries')) {
      return 'Grocery';
    }

    if (input.contains('gas') || input.contains('gas cylinder')) {
      return 'Gas';
    }

    // =========================
    // TRAVEL
    // =========================

    if (input.contains('train')) {
      return 'Train';
    }

    if (input.contains('flight') || input.contains('air ticket')) {
      return 'Flight';
    }

    if (input.contains('hotel')) {
      return 'Hotel';
    }

    // =========================
    // WORK
    // =========================

    if (input.contains('meeting')) {
      return 'Meeting';
    }

    if (input.contains('call') || input.contains('phone')) {
      return 'Call';
    }

    if (input.contains('email') || input.contains('mail')) {
      return 'Email';
    }

    if (input.contains('deadline')) {
      return 'Deadline';
    }

    return 'General';
  }
}
