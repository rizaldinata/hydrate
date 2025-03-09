import 'package:flutter/material.dart';
import 'dart:math';

class WaterIndicatorPainter extends CustomPainter {
  final double progress; // Progress from 0.0 to 1.0

  WaterIndicatorPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Professional color palette
    final activeBlue = Color(0xFF2196F3); // Vibrant, professional blue
    final inactiveGrey = Colors.grey[350]!; // Soft grey for inactive parts
    final backgroundGrey = Colors.grey[350]!; // Light background grey


    // Background paint with soft grey and rounded caps
    final backgroundPaint = Paint()
      ..color = backgroundGrey
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    // Active progress paint with professional blue
    final progressPaint = Paint()
      ..color = activeBlue
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    // Left vertical line paint (blue)
    final leftVerticalPaint = Paint()
      ..color = activeBlue
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    // Right vertical line paint (grey)
    final rightVerticalPaint = Paint()
      ..color = inactiveGrey
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    // Create rect for arc drawing
    final rect = Rect.fromLTWH(0, 0, width, height * 2);


    // Draw background semicircle
    canvas.drawArc(rect, pi, pi, false, backgroundPaint);

    // Draw progress semicircle
    canvas.drawArc(rect, pi, pi * progress, false, progressPaint);

    // Left vertical line with blue color
    canvas.drawLine(
      Offset(0, height), 
      Offset(0, height * 4), 
      leftVerticalPaint,
    );

    // Right vertical line with grey color
    canvas.drawLine(
      Offset(width, height), 
      Offset(width, height * 4), 
      rightVerticalPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is WaterIndicatorPainter) {
      return oldDelegate.progress != progress;
    }
    return true;
  }
}