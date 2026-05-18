/// VisionMate AI - Navigation Screen
/// =====================================
/// Voice-guided walking navigation using Google Maps.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final TextEditingController _destController = TextEditingController();
  final ApiService _api = ApiService.instance;
  final AudioService _audio = AudioService.instance;

  List<String> _voiceInstructions = [];
  int _currentStep = 0;
  bool _isNavigating = false;
  bool _isLoading = false;
  String _statusText = 'Enter a destination to start navigation.';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _audio.speakLocal('Navigation screen. Enter your destination.');
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService.instance.getCurrentPosition();
    setState(() => _currentPosition = pos);
  }

  Future<void> _startNavigation() async {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      await _audio.speakLocal('Please enter a destination.');
      return;
    }
    if (_currentPosition == null) {
      await _audio.speakLocal('Unable to get your location. Please enable GPS.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = 'Calculating route…';
    });

    try {
      final result = await _api.getNavigation(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        destination: dest,
      );

      final instructions = (result['voice_instructions'] as List)
          .map((e) => e as String)
          .toList();

      setState(() {
        _voiceInstructions = instructions;
        _currentStep = 0;
        _isNavigating = true;
        _statusText = instructions.isNotEmpty ? instructions[0] : 'Route ready.';
      });

      // Play first instruction audio
      if (result['first_instruction_audio'] != null) {
        await _audio.playBase64Audio(result['first_instruction_audio'] as String);
      }
    } catch (e) {
      setState(() => _statusText = 'Navigation error. Check your connection.');
      await _audio.speakLocal('Navigation failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < _voiceInstructions.length - 1) {
      setState(() {
        _currentStep++;
        _statusText = _voiceInstructions[_currentStep];
      });
      await _audio.speakLocal(_voiceInstructions[_currentStep]);
    } else {
      await _audio.speakLocal('You have arrived at your destination.');
      setState(() {
        _isNavigating = false;
        _statusText = 'You have arrived!';
      });
    }
  }

  Future<void> _repeatInstruction() async {
    if (_voiceInstructions.isNotEmpty) {
      await _audio.speakLocal(_voiceInstructions[_currentStep]);
    }
  }

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Destination input ──────────────────────────────────────────
              TextField(
                controller: _destController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter destination…',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () => _destController.clear(),
                  ),
                ),
                onSubmitted: (_) => _startNavigation(),
              ),
              const SizedBox(height: 16),

              // ── Start button ───────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startNavigation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.navigation),
                label: Text(_isLoading ? 'Calculating…' : 'Start Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 24),

              // ── Current instruction ────────────────────────────────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        size: 64,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isNavigating) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Step ${_currentStep + 1} of ${_voiceInstructions.length}',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Navigation controls ────────────────────────────────────────
              if (_isNavigating)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _repeatInstruction,
                        icon: const Icon(Icons.replay),
                        label: const Text('Repeat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _nextStep,
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Next Step'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
