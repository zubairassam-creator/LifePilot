import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> initialize() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage('en-IN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  static Future<void> speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}
