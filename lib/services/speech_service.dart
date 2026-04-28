import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    _isInit = await _stt.initialize(
      onError: (e) {},
      onStatus: (s) {},
    );
    await _tts.setLanguage('en-IN');
    await _tts.setPitch(0.9);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onComplete,
  }) async {
    await init();
    if (!_isInit) {
      // Fallback for platforms without mic (like web/edge)
      await Future.delayed(const Duration(seconds: 2));
      onResult('Where are you going at this hour?');
      await Future.delayed(const Duration(seconds: 1));
      onComplete('Where are you going at this hour?');
      return;
    }
    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onComplete(result.recognizedWords);
        } else {
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopListening() => _stt.stop();

  Future<void> speak(String text) async {
    await init();
    await _tts.speak(text);
    // Wait roughly for TTS to finish
    await Future.delayed(Duration(milliseconds: text.length * 60));
  }

  Future<void> stopSpeaking() async => await _tts.stop();

  void dispose() {
    _stt.cancel();
    _tts.stop();
  }
}
