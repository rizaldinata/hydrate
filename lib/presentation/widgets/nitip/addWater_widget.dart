import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/presentation/widgets/nitip/countDown_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/drinkSound_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/glassAnimation_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/loadTodayIntake.dart';
import 'package:hydrate/presentation/widgets/nitip/loadUserData.dart';
import 'package:hydrate/presentation/widgets/nitip/popupAddWater_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddWater extends StatefulWidget {
  final Function(double)? onIntakeChanged;

  const AddWater({Key? key, this.onIntakeChanged}) : super(key: key);

  @override
  State<AddWater> createState() => AddWaterState();
}

class AddWaterState extends State<AddWater> {
  
  int? idPengguna;
  double target = 0.0;
  double currentIntake = 0.0;
  final TargetHidrasiRepository _targetHidrasiRepository =
      TargetHidrasiRepository();
  final RiwayatHidrasiController _riwayatHidrasiController =
      RiwayatHidrasiController();
  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);
  final AppEventBus _eventBus = AppEventBus(); // Inisialisasi event bus

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUserId();
  }

  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idPengguna = prefs.getInt('id_pengguna'); // Pastikan key-nya sesuai
    });
  }

  void animateGlass(BuildContext context, double amount) async {
    if (idPengguna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User tidak teridentifikasi!")));
      return;
    }

    // Play drinking sound effect
    DrinkSound();

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

    widget.onIntakeChanged?.call(currentIntake);

    GlassAnimation();
    Countdown();
    Popupaddwater();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Tidak perlu UI di sini
  }
}
