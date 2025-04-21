import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/presentation/widgets/nitip/checkAndCreateTodayTarget_widget.dart';

class InitializeTarget extends StatefulWidget {
  const InitializeTarget();

  @override
  State<InitializeTarget> createState() => InitializeTargetState();
}

class InitializeTargetState extends State<InitializeTarget> {
  int? idPengguna;
  double target = 0.0;
  double currentIntake = 0.0;
  late HydrationCalculator _hydrationCalculator;
  String? namaPengguna;


  @override
  void initState() {
    super.initState();
    
  }

  Future<void> initializeTarget() async {
    if (idPengguna == null) return;

    try {
      // Gunakan HydrationCalculator untuk mendapatkan nilai target
      await _hydrationCalculator.initializeData(idPengguna!);
      final targetHidrasi =
          _hydrationCalculator.calculateDailyWaterIntake() * 1000;

      setState(() {
        // Selalu gunakan nilai dari algoritma, jangan ada default
        target = targetHidrasi;
      });

      // Cek apakah target hidrasi untuk hari ini sudah ada
      await CheckAndCreateTodayTargetWidget();

      print("Target hidrasi diinisialisasi: $target mL berdasarkan algoritma");
    } catch (e) {
      print("Error initializing target: $e");

      // Jika terjadi error, tetap coba hitung dengan nilai default dalam HydrationCalculator
      // yang akan menggunakan berat badan default dll.
      try {
        final calculator = HydrationCalculator(penggunaId: idPengguna!);
        final targetHidrasi = calculator.calculateDailyWaterIntake() * 1000;

        setState(() {
          target = targetHidrasi;
        });

        print("Target hidrasi (fallback): $target mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (fallback): $e2");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }
}
