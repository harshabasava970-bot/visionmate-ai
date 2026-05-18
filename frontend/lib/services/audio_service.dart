/// VisionMate AI - Audio Service
/// ================================
/// Plays base64-encoded MP3 audio from the backend TTS responses.
/// On web: uses browser's native speechSynthesis API (works without autoplay restrictions).
/// On mobile: uses flutter_tts + audioplayers.

import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

// Web-only import
import 'audio_service_web.dart' if (dart.library.io) 'audio_service_stub.dart'
    as web_tts;

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    if (!kIsWeb) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(1.0);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    }
    _initialized = true;
  }

  /// Play base64-encoded MP3 audio from backend TTS.
  Future<void> playBase64Audio(String audioB64) async {
    if (audioB64.isEmpty) return;
    try {
      if (kIsWeb) {
        final dataUri = 'data:audio/mpeg;base64,$audioB64';
        await _player.play(UrlSource(dataUri));
      } else {
        final bytes = base64Decode(audioB64);
        await _player.play(BytesSource(bytes));
      }
    } catch (_) {
      // Silent fail — caller handles fallback
    }
  }

  /// Speak text using TTS.
  /// On web: uses browser speechSynthesis (no autoplay restriction).
  /// On mobile: uses flutter_tts.
  Future<void> speakLocal(String text, {String lang = 'en-US'}) async {
    await _init();
    if (kIsWeb) {
      web_tts.speakWeb(text, lang);
    } else {
      await _tts.setLanguage(lang);
      await _tts.speak(text);
    }
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    await _player.stop();
    if (kIsWeb) {
      web_tts.stopWeb();
    } else {
      await _tts.stop();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    await _init();
    if (!kIsWeb) await _tts.setSpeechRate(rate);
  }

  Future<void> setLanguage(String lang) async {
    await _init();
    if (!kIsWeb) await _tts.setLanguage(lang);
  }
}
