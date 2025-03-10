import 'package:flutter/material.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final double target = 1500; // Target total minum (ml)
  double currentIntake = 0; // Jumlah air yang diminum (ml)
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0); // Persentase progress

  void _addWater(double amount) {
    setState(() {
      if (currentIntake + amount <= target) {
        currentIntake += amount;
      } else {
        currentIntake = target; // Batas maksimal
      }
      _valueNotifier.value = (currentIntake / target) * 100; // Hitung persentase progress
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Hydration Tracker'),
        backgroundColor: Colors.blue[400],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(36.0),
            child: Center(
              child: DashedCircularProgressBar.aspectRatio(
                aspectRatio: 1,
                valueNotifier: _valueNotifier,
                progress: _valueNotifier.value,
                startAngle: 250,
                sweepAngle: 225,
                foregroundColor: Colors.blue,
                backgroundColor: const Color(0xffeeeeee),
                foregroundStrokeWidth: 15,
                backgroundStrokeWidth: 15,
                animation: true,
                seekSize: 6,
                seekColor: const Color(0xffeeeeee),
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: _valueNotifier,
                    builder: (_, double value, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                            fontSize: 60,
                          ),
                        ),
                        Text(
                          '${currentIntake.toInt()} ml / ${target.toInt()} ml',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Tombol untuk menambah asupan air
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWaterButton(100),
              _buildWaterButton(250),
              _buildWaterButton(500),
            ],
          ),
        ],
      ),
    );
  }

  // Widget tombol untuk menambah jumlah air
  Widget _buildWaterButton(double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _addWater(amount),
        child: Text("+ ${amount.toInt()} ml", style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
