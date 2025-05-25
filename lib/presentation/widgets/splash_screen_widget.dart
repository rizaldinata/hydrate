import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreenWidget extends StatelessWidget {
  const SplashScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: Center(
        child: Lottie.asset(
          'assets/loading.json', // Pastikan path ke file Lottie Anda benar
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}