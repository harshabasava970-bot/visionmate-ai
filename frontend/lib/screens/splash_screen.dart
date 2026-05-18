/// VisionMate AI - Splash Screen
/// ================================
/// Animated splash with accessibility announcement.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _announceAndNavigate();
  }

  Future<void> _announceAndNavigate() async {
    // Announce app name via TTS for blind users
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    await Future.delayed(const Duration(milliseconds: 800));
    await _tts.speak('Welcome to VisionMate AI. Your visual assistant is ready.');

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _tts.stop();
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
              // App icon / logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.visibility,
                  size: 72,
                  color: Colors.white,
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
