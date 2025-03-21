import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';

import '../../presentation/controllers/pengguna_controller.dart';

class HydrationCalculator {
  final PenggunaController _penggunaController = PenggunaController();
  final ProfilPenggunaController _profilPenggunaController =
      ProfilPenggunaController();

  late String gender;
  late double weight;
  late int wakeUpTime;
  late int sleepTime;

  // Konstruktor dengan penggunaId
  HydrationCalculator({
    required int penggunaId,
  }) {
    initializeData(
        penggunaId); // Memanggil metode publik untuk inisialisasi data pengguna
  }

  // Mengubah _initializeData menjadi metode publik
  Future<void> initializeData(int penggunaId) async {
    try {
      Pengguna? penggunaData =
          await _penggunaController.getPenggunaById(penggunaId);

      ProfilPengguna? profilPenggunaData =
          await _profilPenggunaController.getProfilPengguna(penggunaId);

      // Periksa apakah penggunaData null
      if (penggunaData == null) {
        throw Exception("Pengguna tidak ditemukan");
      }

      // Setel nilai properti berdasarkan data pengguna
      // Pastikan profilPenggunaData tidak null sebelum mengakses propertinya
      gender = profilPenggunaData?.jenisKelamin ?? 'unknown';
      weight = profilPenggunaData?.beratBadan ?? 70.0; // Default 70 kg
      wakeUpTime = int.tryParse(profilPenggunaData?.jamBangun ?? '') ?? 6;
      sleepTime = int.tryParse(profilPenggunaData?.jamTidur ?? '') ?? 22;
      // Konversi string ke int, default 22

      // Debugging
      print("Gender: $gender, Weight: $weight");

      // Jika weight masih 0, beri peringatan
      if (weight <= 0) {
        print("Warning: Weight is not valid. Using default value.");
        weight = 70.0; // Set default weight if invalid
      }
    } catch (e) {
      print("Error saat mengambil data pengguna: $e");
      gender = 'unknown';
      weight = 70.0; // Default weight jika error
      wakeUpTime = 6;
      sleepTime = 22;
    }
  }

  // Menghitung kebutuhan hidrasi harian dalam liter
  double calculateDailyWaterIntake() {
    if (weight <= 0) {
      print("Warning: Weight is not valid. Using default value.");
      weight = 70.0; // Set default weight if invalid
    }

    if (gender.toLowerCase() == "male") {
      return weight * 35 / 1000 * 1.1; // Tambah 10% untuk laki-laki
    } else {
      return weight * 35 / 1000; // 35ml per kg berat badan
    }
  }

  // Menghitung distribusi hidrasi sepanjang hari
  Map<String, double> calculateWaterDistribution() {
    double totalIntake = calculateDailyWaterIntake();
    int totalHours = sleepTime - wakeUpTime;
    if (totalHours <= 0) totalHours += 24; // Jika tidur lewat tengah malam

    double hourlyIntake = totalIntake / totalHours;

    Map<String, double> schedule = {};
    for (int i = wakeUpTime; i < sleepTime; i++) {
      schedule["$i:00"] = hourlyIntake;
    }

    return schedule;
  }
}
