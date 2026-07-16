import '../models/task_analysis.dart';

class PlanningEngine {
  static List<String> generateReminderPlan(TaskAnalysis task) {
    switch (task.taskType) {
      // =========================
      // FAMILY
      // =========================

      case 'Birthday':
      case 'Anniversary':
        return [
          '30 Days Before',
          '7 Days Before',
          '1 Day Before',
          'Event Morning',
        ];

      // =========================
      // HEALTH
      // =========================

      case 'Medicine':
        return ['Today', 'Repeat Daily'];

      case 'Appointment':
        return ['Previous Evening', '2 Hours Before', '30 Minutes Before'];

      case 'Hospital':
        return ['Previous Evening', '3 Hours Before', '1 Hour Before'];

      case 'Medical Test':
        return ['Previous Evening', '12 Hours Before', '2 Hours Before'];

      // =========================
      // DOCUMENTS
      // =========================

      case 'Passport':
      case 'Driving Licence':
      case 'Pollution Certificate':
      case 'Aadhaar':
      case 'PAN':
        return [
          '60 Days Before',
          '30 Days Before',
          '7 Days Before',
          'Expiry Day',
        ];

      // =========================
      // FINANCE
      // =========================

      case 'Bill':
      case 'Insurance':
      case 'EMI':
      case 'Rent':
      case 'Fees':
        return ['5 Days Before', '1 Day Before', 'Due Day Morning'];

      case 'Salary':
        return ['Salary Day Morning'];

      // =========================
      // HOME
      // =========================

      case 'Shopping':
      case 'Grocery':
        return ['Today'];

      case 'Gas':
        return ['Book Today', 'Follow Up Tomorrow'];

      // =========================
      // TRAVEL
      // =========================

      case 'Train':
      case 'Flight':
        return ['1 Week Before', 'Previous Evening', '3 Hours Before'];

      case 'Hotel':
        return ['3 Days Before', 'Check-in Morning'];

      // =========================
      // WORK
      // =========================

      case 'Meeting':
        return ['1 Day Before', '1 Hour Before'];

      case 'Call':
        return ['At Scheduled Time'];

      case 'Email':
        return ['Today'];

      case 'Deadline':
        return ['7 Days Before', '3 Days Before', '1 Day Before'];

      default:
        return ['On Time'];
    }
  }
}
