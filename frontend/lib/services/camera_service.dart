/// VisionMate AI - Camera Service

import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) throw Exception('No cameras available.');

    // Always force BACK camera — never use front camera for blind navigation
    final CameraDescription backCamera;
    final backCameras = _cameras.where(
      (c) => c.lensDirection == CameraLensDirection.back,
    ).toList();

    if (backCameras.isNotEmpty) {
      backCamera = backCameras.first; // Use first (main) back camera
    } else {
      backCamera = _cameras.first; // Fallback only if no back camera exists
    }

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium, // medium = ~720p, good balance for free Render backend
      enableAudio: false,      // No audio needed, keeps permissions minimal
      imageFormatGroup: ImageFormatGroup.jpeg,
      // Do NOT enable flash/torch — haptic feedback only
    );
    await _controller!.initialize();
    // Ensure flash is completely off
    await _controller!.setFlashMode(FlashMode.off);
  }

  /// Capture a frame and return base64 JPEG string.
  Future<String?> captureFrameBase64() async {
    if (!isInitialized) return null;
    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Frame capture error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
