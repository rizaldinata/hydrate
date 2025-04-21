import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/presentation/widgets/nitip/countDown_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/popupAddWater_widget.dart';
import 'package:intl/intl.dart';

class Todayintake extends StatefulWidget {
  const Todayintake({super.key}); // penting: tambahkan key di constructor

  @override
  State<Todayintake> createState() => TodayintakeState();
}

class TodayintakeState extends State<Todayintake> {
  int? idPengguna;
  double target = 0.0;
  double currentIntake = 0.0;
  Duration _remainingTime = Duration.zero;
  final TargetHidrasiRepository _targetHidrasiRepository = TargetHidrasiRepository();
  final RiwayatHidrasiController _riwayatHidrasiController = RiwayatHidrasiController();
  late HydrationCalculator _hydrationCalculator;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);

  // Jadikan public method
  Future<void> loadTodayIntake() async {
    if (idPengguna == null) return;

    try {
      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(idPengguna!, todayDate);

      if (targetHarian != null) {
        double targetHidrasi = targetHarian['target_hidrasi'] ?? 0.0;
        double totalHidrasi = targetHarian['total_hidrasi_harian'] ?? 0.0;
        double persentaseHidrasi = targetHarian['persentase_hidrasi'] ?? 0.0;

        setState(() {
          target = targetHidrasi;
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi;
        });

        print(
            "Data hidrasi dimuat: $totalHidrasi mL dari target $targetHidrasi mL (${persentaseHidrasi.toStringAsFixed(1)}%)");

        if (totalHidrasi > 0 && _remainingTime.inSeconds <= 0) {
          Countdown();
        }
      } else {
        Popupaddwater();

        final riwayatHariIni = await _riwayatHidrasiController
            .getRiwayatHidrasiHariIni(idPengguna!);

        double totalIntake = 0;
        for (var riwayat in riwayatHariIni) {
          totalIntake += riwayat.jumlahHidrasi;
        }

        if (totalIntake > 0) {
          await _targetHidrasiRepository.updateTotalHidrasi(
              idPengguna!, todayDate, totalIntake);

          final updatedTarget = await _targetHidrasiRepository
              .getTargetHidrasiHarian(idPengguna!, todayDate);

          if (updatedTarget != null) {
            setState(() {
              currentIntake = totalIntake;
              _valueNotifier.value = updatedTarget['persentase_hidrasi'] ?? 0.0;
            });
          } else {
            setState(() {
              currentIntake = totalIntake;
              _valueNotifier.value = min(100, (currentIntake / target) * 100);
            });
          }

          if (_remainingTime.inSeconds <= 0) {
            Countdown();
          }
        }
      }
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");

      try {
        await _hydrationCalculator.initializeData(idPengguna!);
        final targetHidrasi =
            _hydrationCalculator.calculateDailyWaterIntake() * 1000;

        setState(() {
          target = targetHidrasi;
          _valueNotifier.value = min(100, (currentIntake / target) * 100);
        });

        print("Menggunakan target hidrasi fallback: $targetHidrasi mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (fallback): $e2");
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Tidak perlu UI di sini
  }
}
