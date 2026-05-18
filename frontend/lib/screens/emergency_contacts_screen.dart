/// VisionMate AI - Emergency Contacts Screen

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_contact.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/location_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isSendingSOS = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    AudioService.instance.speakLocal('Emergency contacts screen.');
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('contacts') ?? '[]';
    final list = jsonDecode(raw) as List;
    setState(() {
      _contacts = list.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contacts', jsonEncode(_contacts.map((c) => c.toJson()).toList()));
  }

  void _showContactDialog({EmergencyContact? existing}) {
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact',
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameCtrl, 'Name', Icons.person),
          const SizedBox(height: 12),
          _field(phoneCtrl, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              setState(() {
                if (existing != null) {
                  final i = _contacts.indexWhere((c) => c.id == existing.id);
                  _contacts[i] = EmergencyContact(id: existing.id, name: name, phone: phone);
                } else {
                  _contacts.add(EmergencyContact(id: const Uuid().v4(), name: name, phone: phone));
                }
              });
              _saveContacts();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    if (_contacts.isEmpty) {
      await AudioService.instance.speakLocal('No emergency contacts. Please add one first.');
      return;
    }
    setState(() => _isSendingSOS = true);
    await HapticService.instance.sosPulse();
    await AudioService.instance.speakLocal('Sending emergency SOS. Please wait.');
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos == null) {
        await AudioService.instance.speakLocal('Cannot get location. SOS failed.');
        return;
      }
      final result = await ApiService.instance.sendSOS(
        lat: pos.latitude, lng: pos.longitude, contactNumber: _contacts.first.phone,
      );
      await AudioService.instance.playBase64Audio(result['audio_b64'] as String);
    } catch (_) {
      await AudioService.instance.speakLocal('SOS failed. Please call for help manually.');
    } finally {
      setState(() => _isSendingSOS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showContactDialog())],
      ),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onDoubleTap: _sendSOS,
            child: Container(
              width: double.infinity, height: 120,
              decoration: BoxDecoration(
                color: _isSendingSOS ? Colors.red.withOpacity(0.5) : Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.sos, size: 48, color: Colors.white.withOpacity(_isSendingSOS ? 0.5 : 1)),
                const SizedBox(height: 8),
                Text(_isSendingSOS ? 'Sending SOS…' : 'DOUBLE TAP FOR SOS',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ]),
            ),
          ),
        ),
        Expanded(
          child: _contacts.isEmpty
              ? const Center(child: Text('No contacts.\nTap + to add one.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _contacts.length,
                  itemBuilder: (_, i) {
                    final c = _contacts[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF00BCD4),
                            child: Icon(Icons.person, color: Colors.white)),
                        title: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
                        subtitle: Text(c.phone, style: const TextStyle(color: Colors.white54)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.white54),
                              onPressed: () => _showContactDialog(existing: c)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () { setState(() => _contacts.removeAt(i)); _saveContacts(); }),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ])),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) =>
    TextField(
      controller: ctrl, keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
}
