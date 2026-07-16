import '../models/reminder.dart';

class SecretaryVoiceEngine {
  static String buildSpeech(Reminder reminder) {
    final now = DateTime.now();

    String greeting;

    if (now.hour < 12) {
      greeting = "Good morning";
    } else if (now.hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }

    switch (reminder.notificationMode) {
      case NotificationMode.silent:
        return "";

      case NotificationMode.normal:
        return reminder.title;

      case NotificationMode.speak:
        return "$greeting. This is your LifePilot secretary. "
            "It is time to ${reminder.title}.";

      case NotificationMode.repeatSpeak:
        return "$greeting. This is your LifePilot secretary. "
            "This is an important reminder. "
            "It is now time to ${reminder.title}.";
    }
  }
}
