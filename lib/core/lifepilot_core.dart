import 'secretary_brain.dart';
import 'memory_engine.dart';
import 'secretary_intents.dart';

class LifePilotCore {
  static final LifePilotCore instance = LifePilotCore._internal();

  factory LifePilotCore() => instance;

  LifePilotCore._internal();

  final SecretaryBrain brain = SecretaryBrain();
  final MemoryEngine memory = MemoryEngine();

  Future<IntentResult> process(String input, {bool hasPendingAttachment = false}) async {
    memory.addUserMessage(input);
    final result = await brain.processUserInput(input, hasPendingAttachment: hasPendingAttachment);
    memory.addAssistantMessage(result.response);
    return result;
  }
}
