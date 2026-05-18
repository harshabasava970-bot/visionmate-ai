/// VisionMate AI - Camera Detection Screen
/// ==========================================
/// Designed for blind users:
/// - Camera starts automatically
/// - Scans every 3 seconds and speaks results
/// - IMMEDIATE alert (voice + vibration) when object is very close
/// - Double-tap anywhere = instant scan
/// - Long-press anywhere = speak time + battery info
/// - Single tap = speak last result again

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/camera_service.dart';
import '../services/haptic_service.dart';
import '../services/location_service.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/voice_command_button.dart';

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
  final CameraService _cam = CameraService.instance;
  final ApiService _api = ApiService.instance;
  final AudioService _audio = AudioService.instance;
  final HapticService _haptic = HapticService.instance;

  // Timers
  Timer? _scanTimer;        // regular 3-second scan
  Timer? _alertTimer;       // fast 1-second proximity check

  List<DetectionResult> _detections = [];
  String _statusText = 'Starting camera…';
  bool _isProcessing = false;
  bool _isListening = false;
  String _lastSpokenText = '';

  // Throttle regular TTS
  DateTime? _lastSpokenAt;
  static const _scanIntervalSec = 3;

  // Proximity alert throttle — alert at most every 2 seconds
  DateTime? _lastAlertAt;
  static const _alertIntervalSec = 2;

  // Shake → SOS
  StreamSubscription? _accelSub;
  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _setupShakeDetection();
  }

  // ── Camera init ────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      await _cam.initialize();
      setState(() => _statusText = 'Camera ready');

      final modeMsg = widget.mode == DetectionMode.ocr
          ? 'Text reader ready. Scanning for text.'
          : 'Camera ready. Scanning your surroundings.';
      await _audio.speakLocal(modeMsg);

      _startScanLoop();
      _startAlertLoop();
    } catch (e) {
      setState(() => _statusText = 'Camera error. Please allow camera access.');
      await _audio.speakLocal('Camera error. Please allow camera access.');
    }
  }

  // ── Scan loops ─────────────────────────────────────────────────────────────

  /// Regular scan every 3 seconds — speaks full scene description
  void _startScanLoop() {
    _scanTimer = Timer.periodic(
      const Duration(seconds: _scanIntervalSec),
      (_) => _runFullScan(),
    );
  }

  /// Fast proximity check every 1 second — ONLY for collision alerts
  void _startAlertLoop() {
    _alertTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _runProximityCheck(),
    );
  }

  /// Full scan: detect objects and speak scene description
  Future<void> _runFullScan() async {
    if (_isProcessing || !_cam.isInitialized) return;
    _isProcessing = true;

    try {
      final b64 = await _cam.captureFrameBase64();
      if (b64 == null) return;

      if (widget.mode == DetectionMode.ocr) {
        await _runOCR(b64);
      } else {
        await _runDetection(b64, speakResult: true);
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Fast proximity check — only triggers if something is very close
  Future<void> _runProximityCheck() async {
    if (_isProcessing || !_cam.isInitialized) return;

    try {
      final b64 = await _cam.captureFrameBase64();
      if (b64 == null) return;
      await _runDetection(b64, speakResult: false, proximityOnly: true);
    } catch (_) {}
  }

  Future<void> _runDetection(
    String b64, {
    required bool speakResult,
    bool proximityOnly = false,
  }) async {
    final result = await _api.detectObjects(imageB64: b64);
    if (!mounted) return;

    final summary = result.sceneSummary.isNotEmpty
        ? result.sceneSummary
        : 'No objects detected.';

    if (!proximityOnly) {
      setState(() {
        _detections = result.detections;
        _statusText = summary;
        _lastSpokenText = summary;
      });
    }

    // ── COLLISION ALERT (highest priority) ──────────────────────────────────
    final veryClose = result.detections.where((d) => d.isVeryClose).toList();
    if (veryClose.isNotEmpty) {
      final now = DateTime.now();
      final canAlert = _lastAlertAt == null ||
          now.difference(_lastAlertAt!).inSeconds >= _alertIntervalSec;

      if (canAlert) {
        _lastAlertAt = now;

        // 1. Strong vibration pattern
        await _haptic.pulseVeryClose();

        // 2. Urgent voice alert — interrupts everything
        final labels = veryClose.map((d) => d.label).toSet().join(' and ');
        await _audio.speakLocal(
          'Warning! $labels very close. Stop immediately.',
        );
        return; // skip regular description
      }
    }

    // ── CLOSE OBJECT (caution) ───────────────────────────────────────────────
    final close = result.detections.where((d) => d.isClose).toList();
    if (close.isNotEmpty && !proximityOnly) {
      await _haptic.pulseClose();
    }

    // ── REGULAR SCENE DESCRIPTION ────────────────────────────────────────────
    if (speakResult && !proximityOnly) {
      final now = DateTime.now();
      final canSpeak = _lastSpokenAt == null ||
          now.difference(_lastSpokenAt!).inSeconds >= _scanIntervalSec;
      if (canSpeak) {
        _lastSpokenAt = now;
        await _audio.speakLocal(summary);
      }
    }
  }

  Future<void> _runOCR(String b64) async {
    final result = await _api.readText(imageB64: b64);
    if (!mounted) return;

    final text = result['text'] as String? ?? 'No text found.';
    setState(() {
      _statusText = text;
      _lastSpokenText = text;
    });

    final now = DateTime.now();
    final canSpeak = _lastSpokenAt == null ||
        now.difference(_lastSpokenAt!).inSeconds >= _scanIntervalSec;
    if (canSpeak) {
      _lastSpokenAt = now;
      await _audio.speakLocal(text);
    }
  }

  // ── Gesture handlers ───────────────────────────────────────────────────────

  /// Single tap — repeat last spoken result
  void _onSingleTap() {
    if (_lastSpokenText.isNotEmpty) {
      _audio.speakLocal(_lastSpokenText);
    } else {
      _audio.speakLocal('Scanning. Please wait.');
    }
  }

  /// Double tap — immediate scan right now
  Future<void> _onDoubleTap() async {
    await _audio.speakLocal('Scanning now.');
    await _runFullScan();
  }

  /// Long press — speak time and useful info
  Future<void> _onLongPress() async {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    await _audio.speakLocal(
      'The time is $hour:$minute $period. '
      'Double tap to scan. Long press for time.',
    );
  }

  // ── SOS via shake ──────────────────────────────────────────────────────────

  void _setupShakeDetection() {
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = event.x.abs() + event.y.abs() + event.z.abs();
      if (magnitude > 25) {
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
    await _audio.speakLocal('Emergency SOS triggered. Sending your location.');
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null) {
      await _api.sendSOS(lat: pos.latitude, lng: pos.longitude);
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _alertTimer?.cancel();
    _accelSub?.cancel();
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
            // ── Camera preview ─────────────────────────────────────────────
            if (_cam.isInitialized)
              Positioned.fill(child: CameraPreview(_cam.controller!))
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
              ),

            // ── Detection bounding boxes ───────────────────────────────────
            if (_detections.isNotEmpty && _cam.isInitialized)
              Positioned.fill(
                child: DetectionOverlay(detections: _detections),
              ),

            // ── Top status bar ─────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Go back to home',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () {
                            _audio.speakLocal('Going back to home.');
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isProcessing)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4), strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Gesture hint ───────────────────────────────────────────────
            Positioned(
              bottom: 110, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap = repeat  •  Double-tap = scan now  •  Hold = time',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // ── Bottom controls ────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  color: Colors.black.withOpacity(0.75),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Semantics(
                        label: 'Scan now',
                        button: true,
                        child: _ControlButton(
                          icon: Icons.search,
                          label: 'Scan Now',
                          onTap: _onDoubleTap,
                        ),
                      ),
                      VoiceCommandButton(
                        isListening: _isListening,
                        onListeningChanged: (v) =>
                            setState(() => _isListening = v),
                      ),
                      Semantics(
                        label: 'Emergency SOS',
                        button: true,
                        child: _ControlButton(
                          icon: Icons.sos,
                          label: 'SOS',
                          color: Colors.red,
                          onTap: _triggerSOS,
                        ),
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
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
