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

  test('recognizes document commands with pending attachments', () {
  const engine = IntentEngine();

  final card = engine.recognize('This is my card, save it', hasPendingAttachment: true);
  expect(card.intent, SecretaryIntent.saveDocument);
  expect(card.action.type, SecretaryActionType.saveDocument);
  expect(card.action.payload['name'], 'Card');

  final aadhaar = engine.recognize('This is my Aadhaar card', hasPendingAttachment: true);
  expect(aadhaar.intent, SecretaryIntent.saveDocument);
  expect(aadhaar.action.payload['name'], 'Aadhaar Card');

  expect(engine.recognize('Save it', hasPendingAttachment: true).intent, SecretaryIntent.saveDocument);
});

test('recognizes document save request without attachment so UI can prompt', () {
  const engine = IntentEngine();

  final result = engine.recognize('Save it');

  expect(result.intent, SecretaryIntent.saveDocument);
  expect(result.response, 'Please attach or capture the document you want me to save.');
});

test('recognizes document retrieval transcript variants', () {
  const engine = IntentEngine();

  final showAadhaar = engine.recognize('Show my Aadhaar card');
  expect(showAadhaar.intent, SecretaryIntent.findDocument);
  expect(showAadhaar.action.payload['name'], 'Aadhaar Card');

  final showAadhar = engine.recognize('Show my aadhar');
  expect(showAadhar.intent, SecretaryIntent.findDocument);
  expect(showAadhar.action.payload['name'], 'Aadhaar');

  final passport = engine.recognize('Give me my passport');
  expect(passport.intent, SecretaryIntent.findDocument);
  expect(passport.action.payload['name'], 'Passport');
});

test('recognizes document share delete and list commands', () {
  const engine = IntentEngine();

  final share = engine.recognize('Share my PAN card');
  expect(share.intent, SecretaryIntent.shareDocument);
  expect(share.action.payload['name'], 'PAN Card');

  final delete = engine.recognize('Delete my old insurance paper');
  expect(delete.intent, SecretaryIntent.deleteDocument);
  expect(delete.action.payload['name'], 'Insurance Paper');

  expect(engine.recognize('Show all my documents').intent, SecretaryIntent.listDocuments);
});
}
