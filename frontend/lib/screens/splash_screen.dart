/// VisionMate AI - Splash Screen
/// ================================
/// Announces app, then goes DIRECTLY to camera detection.
/// Blind users don't need to navigate — camera starts immediately.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'camera_detection_screen.dart';
import 'home_screen.dart';
import '../services/audio_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _announceAndNavigate();
  }

  Future<void> _announceAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    await AudioService.instance.speakLocal(
      'Welcome to VisionMate AI. Starting camera now.',
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Go directly to camera — blind users don't need the home menu
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CameraDetectionScreen(
          mode: DetectionMode.objects,
          autoStart: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.visibility, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'VisionMate AI',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your AI-Powered Visual Assistant',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Color(0xFF00BCD4)),
              const SizedBox(height: 24),
              const Text(
                'Starting camera…',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
