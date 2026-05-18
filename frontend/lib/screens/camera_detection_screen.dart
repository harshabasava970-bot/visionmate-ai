/// VisionMate AI - Camera Detection Screen
/// ==========================================
/// Live camera feed with real-time object detection and voice feedback.
/// Supports both object detection mode and OCR mode.
/// Designed for blind users: tap anywhere to scan, auto-announces results.

import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:sensors_plus/sensors_plus.dart';import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/camera_service.dart';
import '../services/haptic_service.dart';
import '../services/location_service.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/voice_command_button.dart';

enum DetectionMode { objects, ocr }

class CameraDetectionScreen extends StatefulWidget {
  final DetectionMode mode;
  const CameraDetectionScreen({super.key, this.mode = DetectionMode.objects});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  final CameraService _cam = CameraService.instance;
  final ApiService _api = ApiService.instance;
  final AudioService _audio = AudioService.instance;
  final HapticService _haptic = HapticService.instance;

  Timer? _detectionTimer;
  List<DetectionResult> _detections = [];
  String _statusText = 'Initialising camera…';
  bool _isProcessing = false;
  bool _isListening = false;
  bool _audioUnlocked = false; // tracks browser autoplay unlock

  // Shake detection for SOS
  StreamSubscription? _accelSub;
  DateTime? _lastShake;

  // Throttle TTS so it doesn't speak every 500ms
  DateTime? _lastSpokenAt;
  static const _speakIntervalSec = 4; // speak at most every 4 seconds

  @override
  void initState() {
    super.initState();
    _initCamera();
    _setupShakeDetection();
  }

  Future<void> _initCamera() async {
    try {
      await _cam.initialize();
      setState(() => _statusText = 'Camera ready. Tap anywhere to start scanning.');
      await _audio.speakLocal(
        widget.mode == DetectionMode.ocr
            ? 'OCR mode. Tap anywhere to read text in front of you.'
            : 'Detection mode active. Tap anywhere to scan your surroundings.',
      );
      _audioUnlocked = true;
      _startDetectionLoop();
    } catch (e) {
      setState(() => _statusText = 'Camera error. Please allow camera access.');
      await _audio.speakLocal('Camera error. Please allow camera access and try again.');
    }
  }

  void _startDetectionLoop() {
    // Auto-scan every 4 seconds (not 500ms) to avoid spamming TTS
    _detectionTimer = Timer.periodic(
      const Duration(seconds: _speakIntervalSec),
      (_) => _processFrame(),
    );
  }

  /// Called by auto-loop and manual tap
  Future<void> _processFrame() async {
    if (_isProcessing || !_cam.isInitialized) return;
    _isProcessing = true;

    setState(() => _statusText = 'Scanning…');

    try {
      final b64 = await _cam.captureFrameBase64();
      if (b64 == null) {
        setState(() => _statusText = 'Could not capture frame.');
        return;
      }

      if (widget.mode == DetectionMode.ocr) {
        await _runOCR(b64);
      } else {
        await _runDetection(b64);
      }
    } catch (e) {
      setState(() => _statusText = 'Scan failed. Retrying…');
      // Speak error only if it's been a while (avoid spam)
      await _speakIfReady('Scan failed. Please wait.');
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _runDetection(String b64) async {
    final result = await _api.detectObjects(imageB64: b64);
    if (!mounted) return;

    setState(() {
      _detections = result.detections;
      _statusText = result.sceneSummary.isNotEmpty
          ? result.sceneSummary
          : 'No objects detected.';
    });

    // Haptic feedback based on proximity
    final veryClose = result.detections.any((d) => d.isVeryClose);
    final close = result.detections.any((d) => d.isClose);

    if (veryClose) {
      await _haptic.pulseVeryClose();
    } else if (close) {
      await _haptic.pulseClose();
    }

    // Play TTS audio from backend (or speak locally if empty)
    if (result.audioB64.isNotEmpty) {
      // Try backend audio first, fall back to local TTS with the scene text
      try {
        await _audio.playBase64Audio(result.audioB64);
      } catch (_) {
        await _speakIfReady(_statusText);
      }
      _lastSpokenAt = DateTime.now();
    } else {
      await _speakIfReady(_statusText);
    }
  }

  Future<void> _runOCR(String b64) async {
    final result = await _api.readText(imageB64: b64);
    if (!mounted) return;

    final text = result['text'] as String? ?? 'No text found.';
    setState(() => _statusText = text);

    final audioB64 = result['audio_b64'] as String?;
    if (audioB64 != null && audioB64.isNotEmpty) {
      try {
        await _audio.playBase64Audio(audioB64);
      } catch (_) {
        await _speakIfReady(text);
      }
      _lastSpokenAt = DateTime.now();
    } else {
      await _speakIfReady(text);
    }
  }

  /// Speak only if enough time has passed since last speech
  Future<void> _speakIfReady(String text) async {
    final now = DateTime.now();
    if (_lastSpokenAt == null ||
        now.difference(_lastSpokenAt!).inSeconds >= _speakIntervalSec) {
      _lastSpokenAt = now;
      await _audio.speakLocal(text);
    }
  }

  void _setupShakeDetection() {
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = (event.x.abs() + event.y.abs() + event.z.abs());
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
    _detectionTimer?.cancel();
    _accelSub?.cancel();
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap anywhere on screen to trigger a scan
        onTap: () {
          _audioUnlocked = true;
          _processFrame();
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Camera preview ───────────────────────────────────────────────
            if (_cam.isInitialized)
              Positioned.fill(
                child: CameraPreview(_cam.controller!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
              ),

            // ── Detection overlay (bounding boxes) ───────────────────────────
            if (_detections.isNotEmpty && _cam.isInitialized)
              Positioned.fill(
                child: DetectionOverlay(detections: _detections),
              ),

            // ── Top status bar ───────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Go back',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            _audio.speakLocal('Going back.');
                            Navigator.pop(context);
                          },
                          tooltip: 'Go back',
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          liveRegion: true, // announces changes to screen readers
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
                      // Processing indicator
                      if (_isProcessing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4),
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tap hint overlay (shown briefly) ────────────────────────────
            if (!_isProcessing && _cam.isInitialized)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Tap anywhere to scan',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
              ),

            // ── Bottom controls ──────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black.withOpacity(0.75),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Manual scan button
                      Semantics(
                        label: 'Scan now',
                        button: true,
                        child: _ControlButton(
                          icon: Icons.search,
                          label: 'Scan Now',
                          onTap: _processFrame,
                        ),
                      ),
                      // Voice command button
                      VoiceCommandButton(
                        isListening: _isListening,
                        onListeningChanged: (v) => setState(() => _isListening = v),
                      ),
                      // SOS button
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

// ── Small control button widget ───────────────────────────────────────────────

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
            width: 64,
            height: 64,
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
