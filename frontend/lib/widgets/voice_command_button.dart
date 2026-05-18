/// VisionMate AI - Voice Command Button
/// Hold to record, release to send to speech API.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class VoiceCommandButton extends StatefulWidget {
  final bool isListening;
  final ValueChanged<bool> onListeningChanged;

  const VoiceCommandButton({
    super.key,
    required this.isListening,
    required this.onListeningChanged,
  });

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton> {
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await AudioService.instance.speakLocal('Speech recognition not available.');
      return;
    }
    widget.onListeningChanged(true);
    await AudioService.instance.speakLocal('Listening.');
    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          await _handleCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    widget.onListeningChanged(false);
  }

  Future<void> _handleCommand(String command) async {
    try {
      // Send recognized text as a text command to backend
      final result = await ApiService.instance.sendSpeechCommand(
        audioBytes: Uint8List.fromList(command.codeUnits),
        language: 'en',
      );
      final audioB64 = result['audio_b64'] as String?;
      if (audioB64 != null) {
        await AudioService.instance.playBase64Audio(audioB64);
      }
    } catch (e) {
      await AudioService.instance.speakLocal('Command failed. Please try again.');
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isListening ? Colors.red : const Color(0xFF00BCD4);
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: () => _stopListening(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: widget.isListening
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 20, spreadRadius: 4)]
                  : [],
            ),
            child: Icon(
              widget.isListening ? Icons.mic : Icons.mic_none,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isListening ? 'Listening…' : 'Hold to Talk',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
