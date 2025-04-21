import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/widgets/nitip/initializeTarget.dart';
import 'package:hydrate/presentation/widgets/nitip/loadTodayIntake.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadUserData extends StatefulWidget {
  const LoadUserData();

  @override
  State<LoadUserData> createState() => LoadUserDataState();
}

class LoadUserDataState extends State<LoadUserData> {
  int? idPengguna;
  double target = 0.0;
  double currentIntake = 0.0;
  late final PenggunaController _penggunaController;
  late HydrationCalculator _hydrationCalculator;
  String? namaPengguna;


  @override
  void initState() {
    super.initState();
  }

  Future<void> loadUserData() async {
    try {
      final session = SessionManager();
      final userId = await session.getUserId();

      if (userId != null) {
        final pengguna = await _penggunaController.getPenggunaById(userId);

        if (pengguna != null) {
          _hydrationCalculator = HydrationCalculator(penggunaId: userId);

          setState(() {
            idPengguna = userId;
            namaPengguna = pengguna.nama;
          });

          await InitializeTarget();
          await LoadTodayIntake(); // Load today's intake
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }
}
