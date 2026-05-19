/// VisionMate AI - Battery Service
/// ==================================
/// Monitors battery level and speaks alerts for blind users.
/// Alerts at 30%, 20%, and 10%.

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'audio_service.dart';

class BatteryService {
  BatteryService._();
  static final BatteryService instance = BatteryService._();

  final Battery _battery = Battery();
  Timer? _monitorTimer;
  int _lastAlertLevel = 100;
  String _lang = 'en';

  // Alert thresholds
  static const _thresholds = [30, 20, 10];

  static const _messages = {
    'en': {
      30: 'Battery is at 30 percent. Please connect to a power bank soon.',
      20: 'Warning! Battery is at 20 percent. Connect to charger immediately.',
      10: 'Critical! Battery is at 10 percent. App may stop soon. Connect charger now.',
      'charging': 'Battery is charging.',
      'full': 'Battery is fully charged.',
    },
    'hi': {
      30: 'बैटरी 30 प्रतिशत है। कृपया जल्द पावर बैंक से कनेक्ट करें।',
      20: 'चेतावनी! बैटरी 20 प्रतिशत है। तुरंत चार्जर से कनेक्ट करें।',
      10: 'खतरा! बैटरी 10 प्रतिशत है। ऐप जल्द बंद हो सकता है। अभी चार्जर लगाएं।',
      'charging': 'बैटरी चार्ज हो रही है।',
      'full': 'बैटरी पूरी तरह चार्ज है।',
    },
    'te': {
      30: 'బ్యాటరీ 30 శాతం ఉంది. దయచేసి త్వరలో పవర్ బ్యాంక్‌కు కనెక్ట్ చేయండి.',
      20: 'హెచ్చరిక! బ్యాటరీ 20 శాతం ఉంది. వెంటనే చార్జర్‌కు కనెక్ట్ చేయండి.',
      10: 'ప్రమాదం! బ్యాటరీ 10 శాతం ఉంది. యాప్ త్వరలో ఆగవచ్చు. ఇప్పుడే చార్జర్ పెట్టండి.',
      'charging': 'బ్యాటరీ చార్జ్ అవుతోంది.',
      'full': 'బ్యాటరీ పూర్తిగా చార్జ్ అయింది.',
    },
  };

  void setLanguage(String lang) => _lang = lang;

  /// Start monitoring battery every 60 seconds
  void startMonitoring({String lang = 'en'}) {
    _lang = lang;
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkBattery(),
    );
    // Check immediately on start
    _checkBattery();
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      // Don't alert if charging
      if (state == BatteryState.charging || state == BatteryState.full) return;

      // Check thresholds — only alert once per threshold crossing
      for (final threshold in _thresholds) {
        if (level <= threshold && _lastAlertLevel > threshold) {
          _lastAlertLevel = threshold;
          final msgs = _messages[_lang] ?? _messages['en']!;
          final msg = msgs[threshold] as String;
          await AudioService.instance.speakLocal(msg, lang: _langToTts(_lang));
          break;
        }
      }
    } catch (_) {
      // Battery API not available on all platforms — fail silently
    }
  }

  /// Speak current battery level on demand (e.g. voice command "battery status")
  Future<void> speakBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final msgs = _messages[_lang] ?? _messages['en']!;

      String msg;
      if (state == BatteryState.charging) {
        msg = '${msgs['charging']} $level percent.';
      } else if (state == BatteryState.full) {
        msg = msgs['full'] as String;
      } else {
        msg = _lang == 'hi'
            ? 'बैटरी $level प्रतिशत बची है।'
            : _lang == 'te'
            ? 'బ్యాటరీ $level శాతం మిగిలి ఉంది.'
            : 'Battery is at $level percent.';
      }
      await AudioService.instance.speakLocal(msg, lang: _langToTts(_lang));
    } catch (_) {
      await AudioService.instance.speakLocal(
        'Battery status not available.',
        lang: _langToTts(_lang),
      );
    }
  }

  String _langToTts(String lang) {
    const map = {'en': 'en-US', 'hi': 'hi-IN', 'te': 'te-IN'};
    return map[lang] ?? 'en-US';
  }
}
