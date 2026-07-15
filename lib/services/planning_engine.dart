import '../models/task_analysis.dart';

class PlanningEngine {
  static List<String> generateReminderPlan(TaskAnalysis task) {
    switch (task.taskType) {
      case 'Birthday':
        return [
          '30 Days Before',
          '7 Days Before',
          '1 Day Before',
          'Birthday Morning',
        ];

      case 'Expiry':
        return [
          '30 Days Before',
          '7 Days Before',
          '1 Day Before',
          'Expiry Day',
        ];

      case 'Bill':
        return ['3 Days Before', '1 Day Before', 'Due Time'];

      case 'Appointment':
        return ['Previous Evening', '2 Hours Before', '30 Minutes Before'];

      case 'Meeting':
        return ['1 Day Before', '1 Hour Before'];

      default:
        return ['On Time'];
    }
  }
}
