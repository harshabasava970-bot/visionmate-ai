/// VisionMate AI - Detection Overlay
/// =====================================
/// Draws bounding boxes and labels over the camera preview.

import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;

  const DetectionOverlay({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetectionPainter(detections),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;

  _DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final color = _colorForDistance(det.distanceLabel);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Scale bounding box to canvas size
      // Note: bbox coords are in original image space (640px max dim)
      // We scale proportionally to the canvas
      const double modelSize = 640.0;
      final scaleX = size.width / modelSize;
      final scaleY = size.height / modelSize;

      final rect = Rect.fromLTRB(
        det.bbox.x1 * scaleX,
        det.bbox.y1 * scaleY,
        det.bbox.x2 * scaleX,
        det.bbox.y2 * scaleY,
      );

      canvas.drawRect(rect, paint);

      // Label background
      final labelText = '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: ' $labelText ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            backgroundColor: color.withOpacity(0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(rect.left, rect.top - textPainter.height - 2),
      );
    }
  }

  Color _colorForDistance(String distanceLabel) {
    switch (distanceLabel) {
      case 'very_close':
        return Colors.red;
      case 'close':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  bool shouldRepaint(_DetectionPainter old) => old.detections != detections;
}
