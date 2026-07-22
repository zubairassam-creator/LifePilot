import 'intent_engine.dart';
import 'memory_engine.dart';
import 'secretary_brain.dart';
import 'secretary_intents.dart';

class LifePilotCore {
  static final LifePilotCore instance = LifePilotCore._internal();

  factory LifePilotCore() => instance;

  LifePilotCore._internal();

  final SecretaryBrain brain = SecretaryBrain();
  final MemoryEngine memory = MemoryEngine();
  final IntentEngine _intentEngine = const IntentEngine();

  Future<IntentResult> process(
    String input, {
    bool hasPendingAttachment = false,
  }) async {
    memory.addUserMessage(input);

    final localIntent = _intentEngine.recognize(
      input,
      hasPendingAttachment: hasPendingAttachment,
    );

    final result = _shouldUseLocalIntent(localIntent.intent)
        ? localIntent
        : await brain.processUserInput(input);

    memory.addAssistantMessage(result.response);
    return result;
  }

  bool _shouldUseLocalIntent(SecretaryIntent intent) {
    return {
      SecretaryIntent.viewSchedule,
      SecretaryIntent.openTasks,
      SecretaryIntent.deleteTasks,
      SecretaryIntent.saveDocument,
      SecretaryIntent.findDocument,
      SecretaryIntent.openDocument,
      SecretaryIntent.shareDocument,
      SecretaryIntent.deleteDocument,
      SecretaryIntent.listDocuments,
      SecretaryIntent.help,
    }.contains(intent);
  }
}
