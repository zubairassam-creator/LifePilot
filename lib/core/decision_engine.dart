import '../services/ai_task_service.dart';
import 'conversation_engine.dart';
import 'lifepilot_core.dart';

class DecisionEngine {
  Future<LifePilotResponse> execute({
    required IntentType intent,
    required String originalInput,
  }) async {
    switch (intent) {
      case IntentType.reminder:
        try {
          final task = await AITaskService.createTask(title: originalInput);

          return LifePilotResponse(
            success: true,
            message: "Reminder saved successfully.",
            data: {
              "action": "reminder",
              "taskId": task.id,
              "title": task.title,
            },
          );
        } catch (e) {
          return LifePilotResponse(
            success: false,
            message: "Failed to save reminder.",
            data: {"error": e.toString()},
          );
        }

      case IntentType.document:
        return LifePilotResponse(
          success: true,
          message: "Certainly. Let's save that document.",
          data: {"action": "document", "input": originalInput},
        );

      case IntentType.note:
        return LifePilotResponse(
          success: true,
          message: "I'll remember that.",
          data: {"action": "note", "input": originalInput},
        );

      case IntentType.contact:
        return LifePilotResponse(
          success: true,
          message: "I'll help you save that contact.",
          data: {"action": "contact", "input": originalInput},
        );

      case IntentType.question:
        return LifePilotResponse(
          success: true,
          message: "Let me think about that.",
          data: {"action": "question", "input": originalInput},
        );

      case IntentType.unknown:
        return LifePilotResponse(
          success: false,
          message: "I'm not sure I understood. Could you say that another way?",
        );
    }
  }
}
