import '../models/task_analysis.dart';

class ResponsibilityEngine {
  static int calculateScore(TaskAnalysis task) {
    switch (task.taskType) {
      // =====================
      // CRITICAL
      // =====================

      case 'Medicine':
      case 'Hospital':
      case 'Passport':
      case 'Driving Licence':
      case 'Pollution Certificate':
        return 10;

      // =====================
      // VERY IMPORTANT
      // =====================

      case 'Birthday':
      case 'Anniversary':
      case 'Appointment':
      case 'Insurance':
      case 'Fees':
        return 9;

      // =====================
      // IMPORTANT
      // =====================

      case 'Bill':
      case 'Meeting':
      case 'Deadline':
      case 'Train':
      case 'Flight':
        return 8;

      // =====================
      // NORMAL
      // =====================

      case 'Call':
      case 'Email':
      case 'Shopping':
      case 'Grocery':
      case 'Gas':
        return 6;

      default:
        return 5;
    }
  }

  static bool requiresFollowUp(TaskAnalysis task) {
    return calculateScore(task) >= 8;
  }

  static bool showInMorningBrief(TaskAnalysis task) {
    return calculateScore(task) >= 7;
  }

  static bool shouldSpeakAloud(TaskAnalysis task) {
    return calculateScore(task) >= 9;
  }
}
