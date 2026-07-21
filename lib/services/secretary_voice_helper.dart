import 'voice_service.dart';

typedef AssistantMessageDisplay = Future<void> Function(String message);
typedef SpeakingStateSetter = void Function(bool isSpeaking);

class SecretaryVoiceHelper {
  const SecretaryVoiceHelper._();

  static Future<void> speakAndDisplay(
    String message, {
    required AssistantMessageDisplay display,
    SpeakingStateSetter? setSpeaking,
    bool speak = true,
  }) async {
    await display(message);
    if (!speak) return;
    setSpeaking?.call(true);
    await VoiceService.speak(message);
    setSpeaking?.call(false);
  }

  static Future<void> speakOnly(String message) async {
    await VoiceService.speak(message);
  }
}
