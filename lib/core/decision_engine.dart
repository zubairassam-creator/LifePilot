import '../services/ai_task_service.dart';
import 'secretary_intents.dart';

class DecisionEngine {
  const DecisionEngine();

  Future<IntentResult> decide(IntentResult recognized) async {
    if (recognized.intent != SecretaryIntent.createReminder) {
      return recognized;
    }

    final title = recognized.entities['title'] as String?;
    if (title == null || title.trim().isEmpty) return recognized;

    final task = await AITaskService.createTask(title: title.trim());
    return IntentResult(
      intent: recognized.intent,
      confidence: recognized.confidence,
      entities: {...recognized.entities, 'taskId': task.id},
      response: "I've created your reminder.",
      action: recognized.action,
      originalText: recognized.originalText,
      normalizedText: recognized.normalizedText,
    );
  }
}
