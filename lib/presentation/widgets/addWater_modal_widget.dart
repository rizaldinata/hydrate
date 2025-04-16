import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class addWaterWidget extends StatelessWidget {
  addWaterWidget({super.key});

  late AudioPlayer _audioPlayer;
  int? idPengguna;
  StreamSubscription? _eventSubscription;

  @override
  // void initState() {
  //   super.initState();
  //   // WidgetsBinding.instance.addObserver(this);
  //   // _loadUserData();
  //   // _controller.initAnimation(this);
  //   _audioPlayer = AudioPlayer();
  //   // Subscribe ke event bus untuk refresh data
  //   _eventSubscription = _eventBus.stream.listen((event) {
  //     if (event.type == 'refresh_home' || event.type == 'refresh_all') {
  //       refresh();
  //     }
  //   });
  // }

  @override
  // void dispose() {
  //   // Dispose AudioPlayer when widget is disposed
  //   _audioPlayer.dispose();
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  Future<void> _playDrinkingSound() async {
    try {
      print("Attempting to play drinking sound...");
      // Reset the player to ensure it can play again
      await _audioPlayer.stop();
      print("AudioPlayer stopped successfully");

      // Play the sound
      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
      print("Sound playing started successfully");
    } catch (e) {
      print("Error playing sound: $e");
      // Add more detailed error info
      print("Error details: ${e.toString()}");
    }
  }

  // Update fungsi _loadTodayIntake() untuk menggunakan persentase dari database
  Future<void> _loadTodayIntake() async {
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
          _startCountdown();
        }
      } else {
        await _checkAndCreateTodayTarget();

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
            _startCountdown();
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

  // Modify _animateGlass method to play sound
  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User tidak teridentifikasi!")));
      return;
    }

    // Play drinking sound effect
    _playDrinkingSound();

    try {
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
      );

      double newTotalIntake = currentIntake + amount;
      await _targetHidrasiRepository.updateTotalHidrasi(
          idPengguna!, todayDate, newTotalIntake);

      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(idPengguna!, todayDate);

      if (targetHarian != null) {
        double persentase = targetHarian['persentase_hidrasi'] ?? 0.0;
        setState(() {
          currentIntake = newTotalIntake;
          _valueNotifier.value = persentase;
        });
        print("Persentase hidrasi diperbarui dari database: $persentase%");
      } else {
        setState(() {
          currentIntake = newTotalIntake;
          _valueNotifier.value = min(100, (currentIntake / target) * 100);
        });
      }

      // Notifikasi halaman lain tentang perubahan data hidrasi
      _eventBus.fire('refresh_statistics');
    } catch (e) {
      print("Gagal menyimpan riwayat: $e");

      setState(() {
        currentIntake += amount;
        _valueNotifier.value = min(100, (currentIntake / target) * 100);
      });
    }

    _animateGlassMovement(amount);
    _startCountdown();
    _showAddedWaterPopup(context, amount);
  }
}

