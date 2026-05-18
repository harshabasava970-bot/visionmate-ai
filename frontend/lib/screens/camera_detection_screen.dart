/// VisionMate AI - Camera Detection Screen
/// ==========================================
/// Live camera feed with real-time object detection and voice feedback.
/// Supports both object detection mode and OCR mode.

import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

  // Shake detection for SOS
  StreamSubscription? _accelSub;
  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _setupShakeDetection();
    _audio.speakLocal(
      widget.mode == DetectionMode.ocr
          ? 'OCR mode. Point camera at text to read it.'
          : 'Detection mode active. Scanning surroundings.',
    );
  }

  Future<void> _initCamera() async {
    try {
      await _cam.initialize();
      setState(() => _statusText = 'Camera ready');
      _startDetectionLoop();
    } catch (e) {
      setState(() => _statusText = 'Camera error: $e');
    }
  }

  void _startDetectionLoop() {
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.frameIntervalMs),
      (_) => _processFrame(),
    );
  }

  Future<void> _processFrame() async {
    if (_isProcessing || !_cam.isInitialized) return;
    _isProcessing = true;

    try {
      final b64 = await _cam.captureFrameBase64();
      if (b64 == null) return;

      if (widget.mode == DetectionMode.ocr) {
        await _runOCR(b64);
      } else {
        await _runDetection(b64);
      }
    } catch (e) {
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
      _statusText = result.sceneSummary;
    });

    // Haptic feedback based on proximity
    final veryClose = result.detections.any((d) => d.isVeryClose);
    final close = result.detections.any((d) => d.isClose);

    if (veryClose) {
      await _haptic.pulseVeryClose();
    } else if (close) {
      await _haptic.pulseClose();
    }

    // Play TTS audio
    await _audio.playBase64Audio(result.audioB64);
  }

  Future<void> _runOCR(String b64) async {
    final result = await _api.readText(imageB64: b64);
    if (!mounted) return;

    final text = result['text'] as String? ?? 'No text found.';
    setState(() => _statusText = text);
    await _audio.playBase64Audio(result['audio_b64'] as String);
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
      body: Stack(
        children: [
          // ── Camera preview ─────────────────────────────────────────────────
          if (_cam.isInitialized)
            Positioned.fill(
              child: CameraPreview(_cam.controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            ),

          // ── Detection overlay (bounding boxes) ─────────────────────────────
          if (_detections.isNotEmpty && _cam.isInitialized)
            Positioned.fill(
              child: DetectionOverlay(detections: _detections),
            ),

          // ── Top status bar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Go back',
                    ),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Manual scan button
                    _ControlButton(
                      icon: Icons.search,
                      label: 'Scan Now',
                      onTap: _processFrame,
                    ),
                    // Voice command button
                    VoiceCommandButton(
                      isListening: _isListening,
                      onListeningChanged: (v) => setState(() => _isListening = v),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
