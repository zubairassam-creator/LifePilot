import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final stt.SpeechToText _speech = stt.SpeechToText();

  static bool _isListening = false;

  static bool get isListening => _isListening;

  static Future<void> initialize() async {
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

  static Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  static Future<void> toggleListening({
    required void Function(bool isListening) onListeningChanged,
    required Future<void> Function(String text) onFinalResult,
    required void Function(String message) onError,
  }) async {
    if (_isListening) {
      await stopListening();
      onListeningChanged(false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        final normalizedStatus = status.toLowerCase();
        if (normalizedStatus == 'listening') {
          _isListening = true;
          onListeningChanged(true);
        } else if (normalizedStatus == 'notlistening' || normalizedStatus == 'done') {
          _isListening = false;
          onListeningChanged(false);
        }
      },
      onError: (error) {
        _isListening = false;
        onListeningChanged(false);
        onError(error.errorMsg);
      },
    );

    if (!available) {
      _isListening = false;
      onListeningChanged(false);
      onError('Speech recognition is not available.');
      return;
    }

    _isListening = true;
    onListeningChanged(true);

    try {
      await _speech.listen(
        onResult: (result) async {
          if (!result.finalResult) return;
          _isListening = false;
          onListeningChanged(false);
          await onFinalResult(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
        ),
      );
    } catch (_) {
      _isListening = false;
      onListeningChanged(false);
      onError('Could not start speech recognition.');
    }
  }
}
