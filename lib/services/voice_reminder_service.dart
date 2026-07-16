import 'voice_service.dart';

class VoiceReminderService {
  static Future<void> speakReminder(String title) async {
    await VoiceService.speak("This is your LifePilot reminder. $title");
  }
}
