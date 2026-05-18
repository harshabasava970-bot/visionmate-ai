/// VisionMate AI - Haptic Feedback Service
/// ==========================================
/// Provides vibration patterns based on object proximity.

import 'package:vibration/vibration.dart';

class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  /// Short pulse — object nearby (~50 cm).
  Future<void> pulseClose() async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 150);
    }
  }

  /// Strong double pulse — object very close (~20 cm).
  Future<void> pulseVeryClose() async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 300, 100, 300]);
    }
  }

  /// SOS pattern — three short, three long, three short.
  Future<void> sosPulse() async {
    if (!_enabled) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [0, 100, 100, 100, 100, 100, 200, 300, 200, 300, 200, 300, 200, 100, 100, 100, 100, 100],
      );
    }
  }

  /// Cancel vibration.
  void cancel() => Vibration.cancel();
}
