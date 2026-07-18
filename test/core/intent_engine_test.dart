import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/input_normalizer.dart';
import 'package:lifepilot/core/intent_engine.dart';
import 'package:lifepilot/core/secretary_intents.dart';

void main() {
  test('voice and typed schedule inputs normalize into the same pipeline', () {
    const normalizer = InputNormalizer();

    expect(
      normalizer.normalize("Show today's schedule!!!"),
      normalizer.normalize('show todays schedule'),
    );
  });

  test('recognizes schedule requests with scopes', () {
    const engine = IntentEngine();

    final today = engine.recognize('What do I have today?');
    final tomorrow = engine.recognize("show tomorrow's schedule");

    expect(today.intent, SecretaryIntent.viewSchedule);
    expect(today.action.payload['filter'], 'today');
    expect(tomorrow.intent, SecretaryIntent.viewSchedule);
    expect(tomorrow.action.payload['filter'], 'tomorrow');
  });

  test('recognizes task management and reminder intents', () {
    const engine = IntentEngine();

    expect(engine.recognize('tasks').intent, SecretaryIntent.openTasks);
    expect(engine.recognize('clear completed').intent, SecretaryIntent.deleteTasks);
    expect(engine.recognize('remind me to call Sam tomorrow').intent,
        SecretaryIntent.createReminder);
    expect(engine.recognize('what can you do').intent, SecretaryIntent.help);
  });
}
