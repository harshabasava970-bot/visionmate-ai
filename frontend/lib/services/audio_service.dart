/// VisionMate AI - Audio Service
/// ================================
/// Plays base64-encoded MP3 audio from the backend TTS responses.
/// Also handles local TTS fallback via flutter_tts.
/// Web-compatible: uses data URI for audio playback instead of file system.

import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(1.0);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// Play base64-encoded MP3 audio from backend TTS.
  /// On web: uses a data URI (no file system access needed).
  /// On mobile: uses BytesSource directly.
  Future<void> playBase64Audio(String audioB64) async {
    if (audioB64.isEmpty) return;
    try {
      if (kIsWeb) {
        // Web: play via data URI — works in all modern browsers
        final dataUri = 'data:audio/mpeg;base64,$audioB64';
        await _player.play(UrlSource(dataUri));
      } else {
        // Mobile: play directly from bytes
        final bytes = base64Decode(audioB64);
        await _player.play(BytesSource(bytes));
      }
    } catch (e) {
      // Fallback to on-device TTS — never say "audio playback failed" to blind users
      // Instead silently fall through to speakLocal with the scene text
    }
  }

  /// Speak text using on-device TTS (offline fallback).
  Future<void> speakLocal(String text, {String lang = 'en-US'}) async {
    await _init();
    await _tts.setLanguage(lang);
    await _tts.speak(text);
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }

  /// Set TTS speech rate (0.5 = slow, 1.0 = normal, 1.5 = fast).
  Future<void> setSpeechRate(double rate) async {
    await _init();
    await _tts.setSpeechRate(rate);
  }

  /// Set TTS language.
  Future<void> setLanguage(String lang) async {
    await _init();
    await _tts.setLanguage(lang);
  }
}
