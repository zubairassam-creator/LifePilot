import '../models/task_analysis.dart';
import 'entity_extractor.dart';
import 'planning_engine.dart';
import 'task_classifier.dart';

class BrainEngine {
  static TaskAnalysis analyze(String text) {
    final taskType = TaskClassifier.classify(text);
    final entities = EntityExtractor.extract(text);

    String category = 'General';
    String priority = 'Medium';
    bool repeatYearly = false;

    switch (taskType) {
      case 'Birthday':
      case 'Anniversary':
        category = 'Family';
        priority = 'High';
        repeatYearly = true;
        break;

      case 'Medicine':
      case 'Appointment':
      case 'Hospital':
        category = 'Health';
        priority = 'High';
        break;

      case 'Meeting':
      case 'Call':
      case 'Email':
      case 'Deadline':
        category = 'Work';
        priority = 'Medium';
        break;

      case 'Bill':
      case 'Salary':
      case 'Fees':
      case 'Insurance':
        category = 'Finance';
        priority = 'High';
        break;

      case 'Passport':
      case 'Driving Licence':
      case 'Aadhaar':
      case 'PAN':
      case 'Pollution Certificate':
        category = 'Documents';
        priority = 'High';
        break;

      case 'Shopping':
      case 'Grocery':
      case 'Gas':
        category = 'Home';
        priority = 'Medium';
        break;

      case 'Travel':
      case 'Train':
      case 'Flight':
        category = 'Travel';
        priority = 'Medium';
        break;

      default:
        category = 'General';
        priority = 'Medium';
    }

    final analysis = TaskAnalysis(
      originalText: text,
      taskType: taskType,
      category: category,
      priority: priority,
      person: entities['person'],
      relationship: entities['relationship'],
      document: entities['document'],
      eventDate: null,
      repeatYearly: repeatYearly,
      confidence: 0.95,
      needsConfirmation: true,
    );

    PlanningEngine.generateReminderPlan(analysis);

    return analysis;
  }
}
