import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GlassAnimation extends StatefulWidget {
  const GlassAnimation({super.key}); // penting: tambahkan key di constructor

  @override
  State<GlassAnimation> createState() => GlassAnimationState();
}

class GlassAnimationState extends State<GlassAnimation> {
  int? idPengguna;
  double target = 0.0;
  double currentIntake = 0.0;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  
  final Map<double, double> _glassOffsets = {};

  // Jadikan public method
  void animate(double amount) {
    setState(() {
      _glassOffsets[amount] = -10;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _glassOffsets[amount] = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Tidak perlu UI di sini
  }
}
