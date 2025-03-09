import 'package:flutter/material.dart';
import 'dart:math';

class WaterIndicatorPainter extends CustomPainter {
  final double progress; // Progress dari 0.0 sampai 1.0

  WaterIndicatorPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final backgroundPaint = Paint() 
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    // Gambar background setengah lingkaran
    canvas.drawArc(rect, pi, pi, false, backgroundPaint);

    // Gambar progress setengah lingkaran
    canvas.drawArc(rect, pi, pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
