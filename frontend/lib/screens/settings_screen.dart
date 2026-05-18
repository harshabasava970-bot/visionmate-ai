/// VisionMate AI - Settings Screen

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlController;
  String _selectedLang = AppConstants.defaultLang;
  double _voiceSpeed = AppConstants.defaultVoiceSpeed;
  bool _hapticEnabled = true;
  bool _offlineMode = false;
  bool _loaded = false;

  final Map<String, String> _languages = {
    'en': 'English', 'es': 'Spanish', 'fr': 'French',
    'de': 'German',  'ar': 'Arabic',  'hi': 'Hindi', 'zh': 'Chinese',
  };

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrlController.text = prefs.getString(AppConstants.keyApiBaseUrl) ?? AppConstants.defaultApiUrl;
      _selectedLang  = prefs.getString(AppConstants.keyLanguage)    ?? AppConstants.defaultLang;
      _voiceSpeed    = prefs.getDouble(AppConstants.keyVoiceSpeed)   ?? AppConstants.defaultVoiceSpeed;
      _hapticEnabled = prefs.getBool(AppConstants.keyHapticEnabled)  ?? true;
      _offlineMode   = prefs.getBool(AppConstants.keyOfflineMode)    ?? false;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyApiBaseUrl, _apiUrlController.text.trim());
    await prefs.setString(AppConstants.keyLanguage, _selectedLang);
    await prefs.setDouble(AppConstants.keyVoiceSpeed, _voiceSpeed);
    await prefs.setBool(AppConstants.keyHapticEnabled, _hapticEnabled);
    await prefs.setBool(AppConstants.keyOfflineMode, _offlineMode);
    await AudioService.instance.setSpeechRate(_voiceSpeed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved.')));
      await AudioService.instance.speakLocal('Settings saved.');
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader('API Configuration'),
            TextField(
              controller: _apiUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _inputDeco('Backend API URL', Icons.cloud, 'http://192.168.x.x:8000'),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Language'),
            DropdownButtonFormField<String>(
              value: _selectedLang,
              decoration: _inputDeco('Voice Language', Icons.language, ''),
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: _languages.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLang = v!),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Voice Speed'),
            Row(children: [
              const Icon(Icons.slow_motion_video, color: Colors.white54),
              Expanded(
                child: Slider(
                  value: _voiceSpeed, min: 0.5, max: 2.0, divisions: 6,
                  label: '${_voiceSpeed.toStringAsFixed(1)}x',
                  activeColor: const Color(0xFF00BCD4),
                  onChanged: (v) => setState(() => _voiceSpeed = v),
                ),
              ),
              const Icon(Icons.fast_forward, color: Colors.white54),
            ]),
            const SizedBox(height: 24),
            _SectionHeader('Accessibility'),
            _buildSwitch('Haptic Feedback', 'Vibrate on detection', Icons.vibration, _hapticEnabled, (v) => setState(() => _hapticEnabled = v)),
            _buildSwitch('Offline Mode', 'On-device only', Icons.wifi_off, _offlineMode, (v) => setState(() => _offlineMode = v)),
            const SizedBox(height: 32),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Settings')),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, String sub, IconData icon, bool val, ValueChanged<bool> cb) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        secondary: Icon(icon, color: const Color(0xFF00BCD4)),
        value: val, activeColor: const Color(0xFF00BCD4), onChanged: cb,
      ),
    );

  InputDecoration _inputDeco(String label, IconData icon, String hint) => InputDecoration(
    labelText: label, hintText: hint,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true, fillColor: const Color(0xFF1E1E1E),
    prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
  );
}
