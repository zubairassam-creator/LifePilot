import 'lifepilot_core.dart';
import 'conversation_engine.dart';

class DecisionEngine {
  Future<LifePilotResponse> execute({
    required IntentType intent,
    required String originalInput,
  }) async {
    switch (intent) {
      case IntentType.reminder:
        return LifePilotResponse(
          success: true,
          message: "Certainly. I'll help you create that reminder.",
          data: {"action": "reminder", "input": originalInput},
        );

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

      default:
        return LifePilotResponse(
          success: false,
          message: "I'm not sure I understood. Could you say that another way?",
        );
    }
  }
}
