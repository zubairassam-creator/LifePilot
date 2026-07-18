import 'decision_engine.dart';
import 'intent_engine.dart';
import 'memory_engine.dart';
import 'secretary_intents.dart';

class LifePilotCore {
  static final LifePilotCore instance = LifePilotCore._internal();

  factory LifePilotCore() => instance;

  LifePilotCore._internal();

  final IntentEngine intents = const IntentEngine();
  final DecisionEngine decision = const DecisionEngine();
  final MemoryEngine memory = MemoryEngine();

  Future<IntentResult> process(String input) async {
    memory.addUserMessage(input);
    final recognized = intents.recognize(input);
    final result = await decision.decide(recognized);
    memory.addAssistantMessage(result.response);
    return result;
  }
}
