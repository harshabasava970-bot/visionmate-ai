/// VisionMate AI - Large Accessible Action Button
/// =================================================
/// High-contrast, large-touch-target button for the home screen grid.

import 'package:flutter/material.dart';

class LargeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;

  const LargeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
