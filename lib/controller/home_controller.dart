import 'package:flutter/material.dart';

class HomeController {
  late AnimationController animationController;
  late Animation<Offset> animation;
  final double waterProgress = 0.6; // Persentase air yang diminum (0.0 - 1.0)

  void initAnimation(TickerProvider vsync) {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );

    animation = Tween<Offset>(
      begin: Offset(0.0, 0),
      end: const Offset(2.0, 0),
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));
  }

  void startAnimation() {
    animationController.forward();
  }

  void dispose() {
    animationController.dispose();
  }
}