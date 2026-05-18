/// VisionMate AI - App-wide Constants

class AppConstants {
  AppConstants._();

  // ── Hive Boxes ──────────────────────────────────────────────────────────────
  static const String settingsBox  = 'settings';
  static const String contactsBox  = 'contacts';

  // ── Settings Keys ───────────────────────────────────────────────────────────
  static const String keyApiBaseUrl      = 'api_base_url';
  static const String keyLanguage        = 'language';
  static const String keyVoiceSpeed      = 'voice_speed';
  static const String keyHapticEnabled   = 'haptic_enabled';
  static const String keyOfflineMode     = 'offline_mode';
  static const String keyEmergencyContact = 'emergency_contact';

  // ── Default Values ──────────────────────────────────────────────────────────
  static const String defaultApiUrl  = 'http://10.0.2.2:8000'; // Android emulator
  static const String defaultLang    = 'en';
  static const double defaultVoiceSpeed = 1.0;

  // ── Detection ───────────────────────────────────────────────────────────────
  /// How many milliseconds between frame captures
  static const int frameIntervalMs = 500;

  // ── Haptic Patterns ─────────────────────────────────────────────────────────
  static const int hapticShortMs  = 100;
  static const int hapticLongMs   = 500;
}
