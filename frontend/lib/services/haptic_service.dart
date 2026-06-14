/// VisionMate AI - Haptic Feedback Service
/// ==========================================
/// Provides vibration patterns based on object proximity.
/// NOTE: No flash or torch is used — vibration ONLY.

import 'package:vibration/vibration.dart';

class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  /// Short single pulse — object nearby (~50 cm).
  Future<void> pulseClose() async {
    if (!_enabled) return;
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Single short pulse: [delay, duration]
      Vibration.vibrate(pattern: [0, 200]);
    }
  }

  /// Urgent triple pulse — object very close (~20 cm). No flash/torch.
  Future<void> pulseVeryClose() async {
    if (!_enabled) return;
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Triple urgent pulse: [delay, on, off, on, off, on]
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    }
  }

  /// SOS pattern — three short, three long, three short.
  Future<void> sosPulse() async {
    if (!_enabled) return;
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(
        pattern: [0, 100, 100, 100, 100, 100, 200, 300, 200, 300, 200, 300, 200, 100, 100, 100, 100, 100],
      );
    }
  }

  /// Cancel vibration.
  void cancel() => Vibration.cancel();
}
