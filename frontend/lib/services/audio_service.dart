/// VisionMate AI - Audio Service
/// ================================
/// Plays base64-encoded MP3 audio from the backend TTS responses.
/// Also handles local TTS fallback via flutter_tts.

import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

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
  Future<void> playBase64Audio(String audioB64) async {
    try {
      final bytes = base64Decode(audioB64);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tts_output.mp3');
      await file.writeAsBytes(bytes);
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      // Fallback to local TTS if audio playback fails
      await speakLocal('Audio playback failed.');
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
