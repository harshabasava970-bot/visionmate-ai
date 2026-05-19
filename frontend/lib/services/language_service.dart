/// VisionMate AI - Language Service
/// ====================================
/// Manages selected language for TTS and voice commands.
/// Supports English, Hindi, Telugu.

import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _key = 'selected_language';

  // Supported languages
  static const Map<String, LanguageConfig> languages = {
    'en': LanguageConfig(
      code: 'en',
      ttsLocale: 'en-US',
      speechLocale: 'en-US',
      name: 'English',
      nativeName: 'English',
      greetings: 'Welcome to VisionMate AI. Camera is starting.',
      scanning: 'Scanning your surroundings.',
      warning: 'Warning! Object very close. Stop immediately.',
      noObjects: 'No objects detected.',
      sosTriggered: 'Emergency SOS triggered. Sending your location.',
      listening: 'Listening.',
      commands: {
        'start scanning': 'start_scan',
        'start scan': 'start_scan',
        'scan': 'start_scan',
        'stop scanning': 'stop_scan',
        'stop': 'stop_scan',
        'which rupee note': 'currency',
        'what note': 'currency',
        'currency': 'currency',
        'read text': 'ocr',
        'read': 'ocr',
        'can i turn left': 'nav_left',
        'turn left': 'nav_left',
        'can i turn right': 'nav_right',
        'turn right': 'nav_right',
        'navigate to': 'navigate',
        'go to': 'navigate',
        'activate sos': 'sos',
        'emergency': 'sos',
        'help': 'sos',
        'what time': 'time',
        'time': 'time',
        'repeat': 'repeat',
      },
    ),
    'hi': LanguageConfig(
      code: 'hi',
      ttsLocale: 'hi-IN',
      speechLocale: 'hi-IN',
      name: 'Hindi',
      nativeName: 'हिंदी',
      greetings: 'VisionMate AI में आपका स्वागत है। कैमरा शुरू हो रहा है।',
      scanning: 'आपके आसपास स्कैन हो रहा है।',
      warning: 'चेतावनी! वस्तु बहुत करीब है। तुरंत रुकें।',
      noObjects: 'कोई वस्तु नहीं मिली।',
      sosTriggered: 'आपातकालीन SOS भेजा जा रहा है।',
      listening: 'सुन रहा हूं।',
      commands: {
        'स्कैन शुरू करो': 'start_scan',
        'स्कैन करो': 'start_scan',
        'स्कैन बंद करो': 'stop_scan',
        'रुको': 'stop_scan',
        'कौन सा नोट है': 'currency',
        'नोट': 'currency',
        'टेक्स्ट पढ़ो': 'ocr',
        'पढ़ो': 'ocr',
        'बाएं मुड़ सकता हूं': 'nav_left',
        'दाएं मुड़ सकता हूं': 'nav_right',
        'sos चालू करो': 'sos',
        'मदद': 'sos',
        'समय': 'time',
        'दोहराओ': 'repeat',
      },
    ),
    'te': LanguageConfig(
      code: 'te',
      ttsLocale: 'te-IN',
      speechLocale: 'te-IN',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      greetings: 'VisionMate AI కి స్వాగతం. కెమెరా మొదలవుతోంది.',
      scanning: 'మీ చుట్టూ స్కాన్ చేస్తున్నాను.',
      warning: 'హెచ్చరిక! వస్తువు చాలా దగ్గరగా ఉంది. వెంటనే ఆగండి.',
      noObjects: 'ఏ వస్తువూ కనుగొనబడలేదు.',
      sosTriggered: 'అత్యవసర SOS పంపబడుతోంది.',
      listening: 'వింటున్నాను.',
      commands: {
        'స్కాన్ మొదలుపెట్టు': 'start_scan',
        'స్కాన్ చేయి': 'start_scan',
        'స్కాన్ ఆపు': 'stop_scan',
        'ఆపు': 'stop_scan',
        'ఏ నోటు': 'currency',
        'నోటు': 'currency',
        'టెక్స్ట్ చదువు': 'ocr',
        'చదువు': 'ocr',
        'ఎడమకు తిరగవచ్చా': 'nav_left',
        'కుడికి తిరగవచ్చా': 'nav_right',
        'sos పెట్టు': 'sos',
        'సహాయం': 'sos',
        'సమయం': 'time',
        'మళ్ళీ చెప్పు': 'repeat',
      },
    ),
  };

  String _currentCode = 'en';

  LanguageConfig get current => languages[_currentCode] ?? languages['en']!;
  String get currentCode => _currentCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCode = prefs.getString(_key) ?? 'en';
  }

  Future<void> setLanguage(String code) async {
    if (!languages.containsKey(code)) return;
    _currentCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  /// Match a spoken phrase to an intent
  String? matchIntent(String spoken) {
    final lower = spoken.toLowerCase().trim();
    for (final entry in current.commands.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }
}

class LanguageConfig {
  final String code;
  final String ttsLocale;
  final String speechLocale;
  final String name;
  final String nativeName;
  final String greetings;
  final String scanning;
  final String warning;
  final String noObjects;
  final String sosTriggered;
  final String listening;
  final Map<String, String> commands;

  const LanguageConfig({
    required this.code,
    required this.ttsLocale,
    required this.speechLocale,
    required this.name,
    required this.nativeName,
    required this.greetings,
    required this.scanning,
    required this.warning,
    required this.noObjects,
    required this.sosTriggered,
    required this.listening,
    required this.commands,
  });
}
