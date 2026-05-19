/// VisionMate AI - Voice Command Button
/// ========================================
/// Hold to talk. Recognizes commands in English, Hindi, Telugu.
/// Handles intents locally — no backend round-trip for commands.

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/audio_service.dart';
import '../services/language_service.dart';

/// Callback type for recognized intents
typedef IntentCallback = Future<void> Function(String intent, String spokenText);

class VoiceCommandButton extends StatefulWidget {
  final bool isListening;
  final ValueChanged<bool> onListeningChanged;
  final IntentCallback? onIntent; // called when a command is recognized

  const VoiceCommandButton({
    super.key,
    required this.isListening,
    required this.onListeningChanged,
    this.onIntent,
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
    _speechAvailable = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await AudioService.instance.speakLocal(
        'Speech recognition not available.',
        lang: LanguageService.instance.current.ttsLocale,
      );
      return;
    }
    widget.onListeningChanged(true);
    final lang = LanguageService.instance.current;
    await AudioService.instance.speakLocal(
      lang.listening,
      lang: lang.ttsLocale,
    );

    await _speech.listen(
      localeId: lang.speechLocale,
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

  Future<void> _handleCommand(String spoken) async {
    debugPrint('Voice command: "$spoken"');
    final intent = LanguageService.instance.matchIntent(spoken);

    if (intent != null && widget.onIntent != null) {
      await widget.onIntent!(intent, spoken);
    } else {
      // Unknown command
      final lang = LanguageService.instance.current;
      await AudioService.instance.speakLocal(
        lang.code == 'hi'
            ? 'समझ नहीं आया। फिर से बोलें।'
            : lang.code == 'te'
                ? 'అర్థం కాలేదు. మళ్ళీ చెప్పండి.'
                : 'Sorry, I did not understand. Please try again.',
        lang: lang.ttsLocale,
      );
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
    return Semantics(
      label: 'Hold to give voice command',
      button: true,
      child: GestureDetector(
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
                    ? [BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )]
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
      ),
    );
  }
}
