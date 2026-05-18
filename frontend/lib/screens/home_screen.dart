/// VisionMate AI - Home Screen
/// ==============================
/// Main hub with large accessible buttons for each feature.

import 'package:flutter/material.dart';
import 'camera_detection_screen.dart';
import 'navigation_screen.dart';
import 'settings_screen.dart';
import 'emergency_contacts_screen.dart';
import '../services/audio_service.dart';
import '../widgets/large_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Announce home screen
    AudioService.instance.speakLocal(
      'Home screen. Tap a button to get started.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VisionMate AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status bar ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    SizedBox(width: 8),
                    Text('AI Ready', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Main action buttons ─────────────────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    LargeActionButton(
                      icon: Icons.camera_alt,
                      label: 'Detect\nObjects',
                      color: const Color(0xFF00BCD4),
                      semanticLabel: 'Start object detection camera',
                      onTap: () => _navigate(const CameraDetectionScreen()),
                    ),
                    LargeActionButton(
                      icon: Icons.text_fields,
                      label: 'Read\nText',
                      color: const Color(0xFF9C27B0),
                      semanticLabel: 'Read text from camera',
                      onTap: () => _navigate(
                        const CameraDetectionScreen(mode: DetectionMode.ocr),
                      ),
                    ),
                    LargeActionButton(
                      icon: Icons.navigation,
                      label: 'Navigate',
                      color: const Color(0xFF4CAF50),
                      semanticLabel: 'Start navigation',
                      onTap: () => _navigate(const NavigationScreen()),
                    ),
                    LargeActionButton(
                      icon: Icons.sos,
                      label: 'Emergency\nSOS',
                      color: const Color(0xFFFF5252),
                      semanticLabel: 'Emergency SOS',
                      onTap: () => _navigate(const EmergencyContactsScreen()),
                    ),
                  ],
                ),
              ),

              // ── Quick voice command hint ────────────────────────────────────
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BCD4), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Color(0xFF00BCD4)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Say "What is ahead?" or "Read text" to get started',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
