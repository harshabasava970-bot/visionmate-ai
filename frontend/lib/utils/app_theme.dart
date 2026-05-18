/// VisionMate AI - Accessibility-First Dark Theme

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primary    = Color(0xFF00BCD4);
  static const Color _secondary  = Color(0xFFFF9800);
  static const Color _error      = Color(0xFFFF5252);
  static const Color _background = Color(0xFF121212);
  static const Color _surface    = Color(0xFF1E1E1E);
  static const Color _onSurface  = Color(0xFFE0E0E0);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:   _primary,
      secondary: _secondary,
      error:     _error,
      surface:   _surface,
      onSurface: _onSurface,
    ),
    scaffoldBackgroundColor: _background,
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.bold,  color: Colors.white),
      displayMedium:  TextStyle(fontSize: 28, fontWeight: FontWeight.bold,  color: Colors.white),
      headlineLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600,  color: Colors.white),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,  color: Colors.white),
      bodyLarge:      TextStyle(fontSize: 18, color: _onSurface),
      bodyMedium:     TextStyle(fontSize: 16, color: _onSurface),
      labelLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.bold,  color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 64),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    iconTheme: const IconThemeData(size: 32, color: _primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: _surface,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      centerTitle: true,
    ),
    // Fixed: use CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
