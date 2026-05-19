/// VisionMate AI - Camera Detection Screen
/// ==========================================
/// Full voice-controlled experience for blind users.
///
/// GESTURES:
///   Single tap   → repeat last result
///   Double tap   → scan now
///   Long press   → speak current time
///
/// VOICE COMMANDS (English / Hindi / Telugu):
///   "Start scanning"        → begins auto-scan
///   "Stop scanning"         → pauses auto-scan
///   "Scan now"              → immediate scan
///   "Read text"             → OCR mode scan
///   "Which rupee note"      → currency detection
///   "Can I turn left/right" → directional check
///   "Activate SOS"          → emergency alert
///   "What time is it"       → speaks time
///
/// COLLISION ALERT:
///   If any object is very close → immediate voice warning + vibration

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/battery_service.dart';
import '../services/camera_service.dart';
import '../services/haptic_service.dart';
import '../services/location_service.dart';
import '../services/voice_command_service.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';
import '../widgets/detection_overlay.dart';

export 'camera_detection_screen.dart';

enum DetectionMode { objects, ocr }

class CameraDetectionScreen extends StatefulWidget {
  final DetectionMode mode;
  final bool autoStart;

  const CameraDetectionScreen({
    super.key,
    this.mode = DetectionMode.objects,
    this.autoStart = false,
  });

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  final _cam     = CameraService.instance;
  final _api     = ApiService.instance;
  final _audio   = AudioService.instance;
  final _haptic  = HapticService.instance;
  final _voice   = VoiceCommandService.instance;
  final _battery = BatteryService.instance;

  Timer? _scanTimer;
  Timer? _alertTimer;

  List<DetectionResult> _detections = [];
  String _statusText  = 'Starting…';
  String _lastResult  = '';
  bool _isProcessing  = false;
  bool _isListening   = false;
  bool _scanningActive = true;
  String _lang        = 'en';

  // Proximity alert throttle
  DateTime? _lastAlertAt;
  DateTime? _lastSpokenAt;
  static const _scanSec  = 3;
  static const _alertSec = 2;

  // Shake → SOS
  StreamSubscription? _accelSub;
  DateTime? _lastShake;

  // Language display names
  static const _langNames = {'en': 'English', 'hi': 'हिंदी', 'te': 'తెలుగు'};

  // Welcome messages per language
  static const _welcomeMsg = {
    'en': 'Camera ready. Scanning your surroundings. Say a command anytime.',
    'hi': 'कैमरा तैयार है। आसपास स्कैन हो रहा है। कभी भी कमांड बोलें।',
    'te': 'కెమెరా సిద్ధంగా ఉంది. చుట్టుపక్కల స్కాన్ అవుతోంది. ఎప్పుడైనా కమాండ్ చెప్పండి.',
  };

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _setupShakeDetection();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'en';
    setState(() => _lang = lang);
    _voice.setLanguage(lang);
    await _voice.initialize();
    await _initCamera();
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      await _cam.initialize();
      setState(() => _statusText = _welcomeMsg[_lang] ?? _welcomeMsg['en']!);
      await _audio.speakLocal(_statusText, lang: _langToTts(_lang));
      _battery.startMonitoring(lang: _lang);
      _startScanLoop();
      _startAlertLoop();
    } catch (e) {
      setState(() => _statusText = 'Camera error. Please allow camera access.');
      await _audio.speakLocal(_statusText);
    }
  }

  String _langToTts(String lang) {
    const map = {'en': 'en-US', 'hi': 'hi-IN', 'te': 'te-IN'};
    return map[lang] ?? 'en-US';
  }

  // ── Scan loops ─────────────────────────────────────────────────────────────

  void _startScanLoop() {
    _scanTimer = Timer.periodic(
      const Duration(seconds: _scanSec),
      (_) { if (_scanningActive) _runFullScan(); },
    );
  }

  void _startAlertLoop() {
    _alertTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _runProximityCheck(),
    );
  }

  Future<void> _runFullScan() async {
    if (_isProcessing || !_cam.isInitialized) return;
    _isProcessing = true;
    try {
      final b64 = await _cam.captureFrameBase64();
      if (b64 == null) return;
      if (widget.mode == DetectionMode.ocr) {
        await _runOCR(b64);
      } else {
        await _runDetection(b64, speak: true);
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _runProximityCheck() async {
    if (_isProcessing || !_cam.isInitialized) return;
    try {
      final b64 = await _cam.captureFrameBase64();
      if (b64 == null) return;
      await _runDetection(b64, speak: false, proximityOnly: true);
    } catch (_) {}
  }

  Future<void> _runDetection(
    String b64, {
    required bool speak,
    bool proximityOnly = false,
  }) async {
    final result = await _api.detectObjects(imageB64: b64, lang: _lang);
    if (!mounted) return;

    final summary = result.sceneSummary.isNotEmpty
        ? result.sceneSummary
        : (_lang == 'hi' ? 'आगे का रास्ता साफ है।'
           : _lang == 'te' ? 'ముందు దారి స్పష్టంగా ఉంది.'
           : 'The path ahead appears clear.');

    if (!proximityOnly) {
      setState(() {
        _detections  = result.detections;
        _statusText  = summary;
        _lastResult  = summary;
      });
    }

    // ── COLLISION ALERT ──────────────────────────────────────────────────────
    final veryClose = result.detections.where((d) => d.isVeryClose).toList();
    if (veryClose.isNotEmpty) {
      final now = DateTime.now();
      if (_lastAlertAt == null ||
          now.difference(_lastAlertAt!).inSeconds >= _alertSec) {
        _lastAlertAt = now;
        await _haptic.pulseVeryClose();

        final labels = veryClose.map((d) => d.label).toSet().join(' and ');
        final alertMsg = _lang == 'hi'
            ? 'चेतावनी! $labels बहुत पास है। तुरंत रुकें।'
            : _lang == 'te'
            ? 'హెచ్చరిక! $labels చాలా దగ్గరగా ఉంది. వెంటనే ఆగండి.'
            : 'Warning! $labels very close. Stop immediately.';

        await _audio.speakLocal(alertMsg, lang: _langToTts(_lang));
        return;
      }
    }

    // ── Close object haptic ──────────────────────────────────────────────────
    if (result.detections.any((d) => d.isClose) && !proximityOnly) {
      await _haptic.pulseClose();
    }

    // ── Regular scene description ────────────────────────────────────────────
    if (speak && !proximityOnly) {
      final now = DateTime.now();
      if (_lastSpokenAt == null ||
          now.difference(_lastSpokenAt!).inSeconds >= _scanSec) {
        _lastSpokenAt = now;
        await _audio.speakLocal(summary, lang: _langToTts(_lang));
      }
    }
  }

  Future<void> _runOCR(String b64) async {
    final result = await _api.readText(imageB64: b64, lang: _lang);
    if (!mounted) return;
    final text = result['text'] as String? ?? 'No text found.';
    setState(() { _statusText = text; _lastResult = text; });
    final now = DateTime.now();
    if (_lastSpokenAt == null ||
        now.difference(_lastSpokenAt!).inSeconds >= _scanSec) {
      _lastSpokenAt = now;
      await _audio.speakLocal(text, lang: _langToTts(_lang));
    }
  }

  Future<void> _runCurrencyDetection() async {
    if (!_cam.isInitialized) return;
    final b64 = await _cam.captureFrameBase64();
    if (b64 == null) return;
    try {
      final result = await _api.detectCurrency(imageB64: b64, lang: _lang);
      final msg = result['message'] as String? ?? 'Could not identify note.';
      setState(() { _statusText = msg; _lastResult = msg; });
      await _audio.speakLocal(msg, lang: _langToTts(_lang));
    } catch (e) {
      await _audio.speakLocal('Currency detection failed.', lang: _langToTts(_lang));
    }
  }

  // ── Voice command handler ──────────────────────────────────────────────────

  Future<void> _startVoiceListening() async {
    if (_isListening) return;
    setState(() => _isListening = true);

    final listeningMsg = _lang == 'hi' ? 'सुन रहा हूं।'
        : _lang == 'te' ? 'వింటున్నాను.'
        : 'Listening.';
    await _audio.speakLocal(listeningMsg, lang: _langToTts(_lang));

    await _voice.listen(
      onCommand: (command, transcript) async {
        setState(() => _isListening = false);
        await _handleVoiceCommand(command, transcript);
      },
    );
  }

  Future<void> _handleVoiceCommand(
      VoiceCommand command, String transcript) async {
    final confirmation = _voice.getConfirmation(command);
    if (confirmation.isNotEmpty) {
      await _audio.speakLocal(confirmation, lang: _langToTts(_lang));
    }

    switch (command) {
      case VoiceCommand.startScanning:
        setState(() => _scanningActive = true);
        break;

      case VoiceCommand.stopScanning:
        setState(() => _scanningActive = false);
        break;

      case VoiceCommand.scanNow:
        await _runFullScan();
        break;

      case VoiceCommand.readText:
        final b64 = await _cam.captureFrameBase64();
        if (b64 != null) await _runOCR(b64);
        break;

      case VoiceCommand.whichNote:
        await _runCurrencyDetection();
        break;

      case VoiceCommand.canITurnLeft:
      case VoiceCommand.canITurnRight:
        await _checkDirection(command == VoiceCommand.canITurnLeft ? 'left' : 'right');
        break;

      case VoiceCommand.activateSOS:
        await _triggerSOS();
        break;

      case VoiceCommand.whatTimeIsIt:
        await _speakTime();
        break;

      case VoiceCommand.batteryStatus:
        await _battery.speakBatteryStatus();
        break;

      case VoiceCommand.unknown:
        // confirmation already spoken
        break;
    }
  }

  Future<void> _checkDirection(String direction) async {
    if (!_cam.isInitialized) return;
    final b64 = await _cam.captureFrameBase64();
    if (b64 == null) return;

    final result = await _api.detectObjects(imageB64: b64, lang: _lang);
    final sideObjects = result.detections
        .where((d) => d.direction == direction)
        .toList();

    String msg;
    if (sideObjects.isEmpty) {
      msg = _lang == 'hi'
          ? '${direction == "left" ? "बाईं" : "दाईं"} ओर रास्ता साफ है।'
          : _lang == 'te'
          ? '${direction == "left" ? "ఎడమవైపు" : "కుడివైపు"} దారి స్పష్టంగా ఉంది.'
          : 'The ${direction} side appears clear. You can turn.';
    } else {
      final labels = sideObjects.map((d) => d.label).toSet().join(', ');
      msg = _lang == 'hi'
          ? '${direction == "left" ? "बाईं" : "दाईं"} ओर $labels है। सावधान रहें।'
          : _lang == 'te'
          ? '${direction == "left" ? "ఎడమవైపు" : "కుడివైపు"} $labels ఉంది. జాగ్రత్తగా ఉండండి.'
          : 'There is $labels on the $direction side. Be careful.';
    }

    setState(() { _statusText = msg; _lastResult = msg; });
    await _audio.speakLocal(msg, lang: _langToTts(_lang));
  }

  Future<void> _speakTime() async {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    String msg;
    if (_lang == 'hi') {
      msg = 'अभी समय है $h बजकर $m मिनट।';
    } else if (_lang == 'te') {
      msg = 'ప్రస్తుత సమయం $h గంటలు $m నిమిషాలు.';
    } else {
      msg = 'The time is $h:$m $period.';
    }
    await _audio.speakLocal(msg, lang: _langToTts(_lang));
  }

  // ── SOS ────────────────────────────────────────────────────────────────────

  void _setupShakeDetection() {
    _accelSub = accelerometerEventStream().listen((event) {
      final mag = event.x.abs() + event.y.abs() + event.z.abs();
      if (mag > 25) {
        final now = DateTime.now();
        if (_lastShake == null ||
            now.difference(_lastShake!) > const Duration(seconds: 3)) {
          _lastShake = now;
          _triggerSOS();
        }
      }
    });
  }

  Future<void> _triggerSOS() async {
    await _haptic.sosPulse();
    final msg = _lang == 'hi'
        ? 'आपातकालीन एसओएस सक्रिय। आपकी लोकेशन भेजी जा रही है।'
        : _lang == 'te'
        ? 'అత్యవసర ఎస్ఓఎస్ సక్రియమైంది. మీ స్థానం పంపబడుతోంది.'
        : 'Emergency SOS triggered. Sending your location.';
    await _audio.speakLocal(msg, lang: _langToTts(_lang));
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null) {
      await _api.sendSOS(lat: pos.latitude, lng: pos.longitude, lang: _lang);
    }
  }

  // ── Gesture handlers ───────────────────────────────────────────────────────

  void _onSingleTap() {
    if (_lastResult.isNotEmpty) {
      _audio.speakLocal(_lastResult, lang: _langToTts(_lang));
    }
  }

  Future<void> _onDoubleTap() async {
    final msg = _lang == 'hi' ? 'अभी स्कैन हो रहा है।'
        : _lang == 'te' ? 'ఇప్పుడు స్కాన్ అవుతోంది.'
        : 'Scanning now.';
    await _audio.speakLocal(msg, lang: _langToTts(_lang));
    await _runFullScan();
  }

  Future<void> _onLongPress() async => _speakTime();

  @override
  void dispose() {
    _scanTimer?.cancel();
    _alertTimer?.cancel();
    _accelSub?.cancel();
    _voice.stopListening();
    _battery.stopMonitoring();
    _cam.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onSingleTap,
        onDoubleTap: _onDoubleTap,
        onLongPress: _onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Camera preview
            if (_cam.isInitialized)
              Positioned.fill(child: CameraPreview(_cam.controller!))
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
              ),

            // Bounding boxes
            if (_detections.isNotEmpty && _cam.isInitialized)
              Positioned.fill(
                child: DetectionOverlay(detections: _detections),
              ),

            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          _audio.speakLocal('Going back.', lang: _langToTts(_lang));
                          Navigator.pop(context);
                        },
                        tooltip: 'Go back',
                      ),
                      // Status text
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _statusText,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Language badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00BCD4)),
                        ),
                        child: Text(
                          _langNames[_lang] ?? 'EN',
                          style: const TextStyle(
                              color: Color(0xFF00BCD4), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Gesture hint
            Positioned(
              bottom: 105, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap=repeat  •  Double-tap=scan  •  Hold=time',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  color: Colors.black.withOpacity(0.75),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Scan toggle
                      _ControlButton(
                        icon: _scanningActive
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        label: _scanningActive ? 'Pause' : 'Resume',
                        color: _scanningActive
                            ? Colors.orange
                            : const Color(0xFF00BCD4),
                        onTap: () {
                          setState(() => _scanningActive = !_scanningActive);
                          final msg = _scanningActive
                              ? 'Scanning resumed.'
                              : 'Scanning paused.';
                          _audio.speakLocal(msg, lang: _langToTts(_lang));
                        },
                      ),
                      // Voice command button (large, center)
                      GestureDetector(
                        onTap: _startVoiceListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.red.withOpacity(0.3)
                                : const Color(0xFF00BCD4).withOpacity(0.2),
                            border: Border.all(
                              color: _isListening
                                  ? Colors.red
                                  : const Color(0xFF00BCD4),
                              width: 3,
                            ),
                            boxShadow: _isListening
                                ? [BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 20, spreadRadius: 4)]
                                : [],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? Colors.red
                                : const Color(0xFF00BCD4),
                            size: 34,
                          ),
                        ),
                      ),
                      // SOS button
                      _ControlButton(
                        icon: Icons.sos,
                        label: 'SOS',
                        color: Colors.red,
                        onTap: _triggerSOS,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF00BCD4),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
