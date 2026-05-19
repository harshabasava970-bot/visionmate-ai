/// VisionMate AI - Voice Command Service
/// ========================================
/// Listens for voice commands in English, Hindi, and Telugu.
/// Maps spoken phrases to app actions.

import 'package:speech_to_text/speech_to_text.dart';
import 'audio_service.dart';

enum VoiceCommand {
  startScanning,
  stopScanning,
  scanNow,
  readText,
  whichNote,
  canITurnLeft,
  canITurnRight,
  activateSOS,
  whatTimeIsIt,
  batteryStatus,
  unknown,
}

class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _isListening = false;

  String _currentLang = 'en'; // en | hi | te

  // Locale codes for speech_to_text
  static const _localeMap = {
    'en': 'en_US',
    'hi': 'hi_IN',
    'te': 'te_IN',
  };

  // Command phrases per language
  static const _commands = {
    'en': {
      VoiceCommand.startScanning:  ['start scanning', 'start scan', 'begin scanning', 'scan surroundings'],
      VoiceCommand.stopScanning:   ['stop scanning', 'stop', 'pause'],
      VoiceCommand.scanNow:        ['scan now', 'what is ahead', "what's ahead", 'scan'],
      VoiceCommand.readText:       ['read text', 'read this', 'what does it say'],
      VoiceCommand.whichNote:      ['which note', 'which rupee', 'how much money', 'identify note', 'currency'],
      VoiceCommand.canITurnLeft:   ['can i turn left', 'turn left', 'go left', 'is it safe to turn left'],
      VoiceCommand.canITurnRight:  ['can i turn right', 'turn right', 'go right', 'is it safe to turn right'],
      VoiceCommand.activateSOS:    ['activate sos', 'emergency', 'help me', 'call for help', 'sos'],
      VoiceCommand.whatTimeIsIt:   ['what time is it', 'time please', 'tell me the time'],
      VoiceCommand.batteryStatus:  ['battery status', 'battery level', 'how much battery', 'battery'],
    },
    'hi': {
      VoiceCommand.startScanning:  ['स्कैन शुरू करो', 'स्कैनिंग शुरू करो', 'देखना शुरू करो'],
      VoiceCommand.stopScanning:   ['रुको', 'बंद करो', 'स्कैन बंद करो'],
      VoiceCommand.scanNow:        ['अभी स्कैन करो', 'आगे क्या है', 'स्कैन करो'],
      VoiceCommand.readText:       ['टेक्स्ट पढ़ो', 'यह पढ़ो', 'क्या लिखा है'],
      VoiceCommand.whichNote:      ['कौन सा नोट है', 'कितने रुपये', 'नोट पहचानो'],
      VoiceCommand.canITurnLeft:   ['क्या बाईं ओर मुड़ सकता हूं', 'बाईं ओर जाएं', 'बाएं मुड़ो'],
      VoiceCommand.canITurnRight:  ['क्या दाईं ओर मुड़ सकता हूं', 'दाईं ओर जाएं', 'दाएं मुड़ो'],
      VoiceCommand.activateSOS:    ['एसओएस', 'मदद करो', 'आपातकाल', 'खतरा'],
      VoiceCommand.whatTimeIsIt:   ['क्या समय है', 'समय बताओ'],
      VoiceCommand.batteryStatus:  ['बैटरी कितनी है', 'बैटरी स्तर', 'बैटरी बताओ'],
    },
    'te': {
      VoiceCommand.startScanning:  ['స్కాన్ ప్రారంభించు', 'చూడడం మొదలుపెట్టు', 'స్కాన్ చేయి'],
      VoiceCommand.stopScanning:   ['ఆపు', 'స్కాన్ ఆపు', 'నిలిపివేయి'],
      VoiceCommand.scanNow:        ['ఇప్పుడు స్కాన్ చేయి', 'ముందు ఏముంది', 'స్కాన్'],
      VoiceCommand.readText:       ['టెక్స్ట్ చదువు', 'ఏమి రాసింది', 'చదువు'],
      VoiceCommand.whichNote:      ['ఏ నోటు', 'ఎంత డబ్బు', 'నోటు గుర్తించు'],
      VoiceCommand.canITurnLeft:   ['ఎడమవైపు తిరగవచ్చా', 'ఎడమకు వెళ్ళు', 'ఎడమ'],
      VoiceCommand.canITurnRight:  ['కుడివైపు తిరగవచ్చా', 'కుడికి వెళ్ళు', 'కుడి'],
      VoiceCommand.activateSOS:    ['ఎస్ఓఎస్', 'సహాయం', 'అత్యవసరం', 'ప్రమాదం'],
      VoiceCommand.whatTimeIsIt:   ['సమయం చెప్పు', 'ఇప్పుడు సమయం ఎంత'],
      VoiceCommand.batteryStatus:  ['బ్యాటరీ ఎంత ఉంది', 'బ్యాటరీ స్థాయి', 'బ్యాటరీ'],
    },
  };

  // Confirmation messages per language
  static const _confirmations = {
    'en': {
      VoiceCommand.startScanning:  'Starting scan.',
      VoiceCommand.stopScanning:   'Scanning stopped.',
      VoiceCommand.scanNow:        'Scanning now.',
      VoiceCommand.readText:       'Reading text.',
      VoiceCommand.whichNote:      'Identifying currency note.',
      VoiceCommand.canITurnLeft:   'Checking left side.',
      VoiceCommand.canITurnRight:  'Checking right side.',
      VoiceCommand.activateSOS:    'Activating SOS. Sending emergency alert.',
      VoiceCommand.whatTimeIsIt:   '',
      VoiceCommand.batteryStatus:  '',
      VoiceCommand.unknown:        'Sorry, I did not understand. Please try again.',
    },
    'hi': {
      VoiceCommand.startScanning:  'स्कैनिंग शुरू हो रही है।',
      VoiceCommand.stopScanning:   'स्कैनिंग रोकी गई।',
      VoiceCommand.scanNow:        'अभी स्कैन हो रहा है।',
      VoiceCommand.readText:       'टेक्स्ट पढ़ा जा रहा है।',
      VoiceCommand.whichNote:      'नोट पहचाना जा रहा है।',
      VoiceCommand.canITurnLeft:   'बाईं ओर जाँच हो रही है।',
      VoiceCommand.canITurnRight:  'दाईं ओर जाँच हो रही है।',
      VoiceCommand.activateSOS:    'एसओएस सक्रिय हो रहा है।',
      VoiceCommand.whatTimeIsIt:   '',
      VoiceCommand.batteryStatus:  '',
      VoiceCommand.unknown:        'माफ करें, समझ नहीं आया। फिर से कोशिश करें।',
    },
    'te': {
      VoiceCommand.startScanning:  'స్కాన్ ప్రారంభమవుతోంది.',
      VoiceCommand.stopScanning:   'స్కాన్ ఆపబడింది.',
      VoiceCommand.scanNow:        'ఇప్పుడు స్కాన్ అవుతోంది.',
      VoiceCommand.readText:       'టెక్స్ట్ చదువుతోంది.',
      VoiceCommand.whichNote:      'నోటు గుర్తిస్తోంది.',
      VoiceCommand.canITurnLeft:   'ఎడమవైపు తనిఖీ చేస్తోంది.',
      VoiceCommand.canITurnRight:  'కుడివైపు తనిఖీ చేస్తోంది.',
      VoiceCommand.activateSOS:    'ఎస్ఓఎస్ సక్రియమవుతోంది.',
      VoiceCommand.whatTimeIsIt:   '',
      VoiceCommand.batteryStatus:  '',
      VoiceCommand.unknown:        'క్షమించండి, అర్థం కాలేదు. మళ్ళీ ప్రయత్నించండి.',
    },
  };

  void setLanguage(String lang) {
    _currentLang = lang;
  }

  Future<bool> initialize() async {
    _available = await _speech.initialize();
    return _available;
  }

  bool get isListening => _isListening;
  bool get isAvailable => _available;

  /// Start listening for a voice command.
  /// Calls [onCommand] with the recognized command.
  Future<void> listen({
    required void Function(VoiceCommand command, String transcript) onCommand,
  }) async {
    if (!_available || _isListening) return;
    _isListening = true;

    final locale = _localeMap[_currentLang] ?? 'en_US';

    await _speech.listen(
      localeId: locale,
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          final transcript = result.recognizedWords.toLowerCase().trim();
          final command = _matchCommand(transcript);
          onCommand(command, transcript);
        }
      },
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
  }

  /// Match transcript to a command
  VoiceCommand _matchCommand(String transcript) {
    final langCommands = _commands[_currentLang] ?? _commands['en']!;
    for (final entry in langCommands.entries) {
      for (final phrase in entry.value) {
        if (transcript.contains(phrase.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return VoiceCommand.unknown;
  }

  /// Get confirmation message for a command
  String getConfirmation(VoiceCommand command) {
    final langConf = _confirmations[_currentLang] ?? _confirmations['en']!;
    return langConf[command] ?? '';
  }
}
