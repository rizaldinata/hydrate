import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:intl/intl.dart';

class CheckAndCreateTodayTargetWidget extends StatefulWidget {
  const CheckAndCreateTodayTargetWidget();

  @override
  State<CheckAndCreateTodayTargetWidget> createState() => CheckAndCreateTodayTargetWidgetState();
}

class CheckAndCreateTodayTargetWidgetState extends State<CheckAndCreateTodayTargetWidget> {
  int? idPengguna;
  double target = 0.0;
  final TargetHidrasiRepository _targetHidrasiRepository =TargetHidrasiRepository();
  late HydrationCalculator _hydrationCalculator;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 7)));

  @override
  void initState() {
    super.initState();
  }

  Future<void> checkAndCreateTodayTarget() async {
    if (idPengguna == null) return;

    try {
      final targetExists = await _targetHidrasiRepository
          .checkTargetHidrasiExists(idPengguna!, todayDate);

      if (!targetExists) {
        if (target <= 0) {
          await _hydrationCalculator.initializeData(idPengguna!);
          target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        }

        await _targetHidrasiRepository.createTargetHidrasi(
            idPengguna!, target, todayDate, 0.0);
        print(
            "Target hidrasi baru dibuat untuk tanggal $todayDate: $target mL");
      } else {
        await _targetHidrasiRepository.updateTargetHidrasiValue(
            idPengguna!, todayDate);
        print(
            "Target hidrasi untuk tanggal $todayDate sudah ada dan diperbarui");

        final updatedTarget = await _targetHidrasiRepository
            .getTargetHidrasiHarian(idPengguna!, todayDate);

        if (updatedTarget != null &&
            (updatedTarget['target_hidrasi'] ?? 0) > 0) {
          setState(() {
            target = updatedTarget['target_hidrasi'];
          });
          print("Target hidrasi diperbarui: $target mL");
        }
      }
    } catch (e) {
      print("Error saat memeriksa/membuat target hidrasi: $e");

      try {
        await _hydrationCalculator.initializeData(idPengguna!);
        target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        print("Target hidrasi (recovery): $target mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (recovery): $e2");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }
}
