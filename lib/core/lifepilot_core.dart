import 'conversation_engine.dart';
import 'decision_engine.dart';
import 'memory_engine.dart';

class LifePilotCore {
  static final LifePilotCore instance = LifePilotCore._internal();

  factory LifePilotCore() => instance;

  LifePilotCore._internal();

  final ConversationEngine conversation = ConversationEngine();
  final DecisionEngine decision = DecisionEngine();
  final MemoryEngine memory = MemoryEngine();

  Future<LifePilotResponse> process(String input) async {
    // Store user input for future conversation context
    memory.addUserMessage(input);

    final intent = conversation.detectIntent(input);

    final response = await decision.execute(
      intent: intent,
      originalInput: input,
    );

    // Store assistant response
    memory.addAssistantMessage(response.message);

    return response;
  }
}

class LifePilotResponse {
  final bool success;
  final String message;
  final dynamic data;

  const LifePilotResponse({
    required this.success,
    required this.message,
    this.data,
  });
}
