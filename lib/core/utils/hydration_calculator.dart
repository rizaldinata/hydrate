import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import '../../presentation/controllers/pengguna_controller.dart';

class HydrationCalculator {
  final PenggunaController _penggunaController = PenggunaController();
  final ProfilPenggunaController _profilPenggunaController =
      ProfilPenggunaController();

  late String jenisKelamin;
  late double beratBadan;
  late int wakeUpTime;
  late int sleepTime;

  // Konstruktor dengan penggunaId
  HydrationCalculator({
    required int penggunaId,
  }) {
    initializeData(penggunaId); // Memanggil metode publik untuk inisialisasi data pengguna
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
      jenisKelamin = profilPenggunaData?.jenisKelamin ?? 'Laki-laki'; // Default ke Laki-laki
      beratBadan = profilPenggunaData?.beratBadan ?? 70.0; // Default 70 kg
      
      // Parsing jam bangun dan tidur
      // Format jam yang diharapkan: "HH:MM"
      String jamBangunStr = profilPenggunaData?.jamBangun ?? '';
      String jamTidurStr = profilPenggunaData?.jamTidur ?? '';
      
      wakeUpTime = _parseHour(jamBangunStr, 6); // Default 6 pagi
      sleepTime = _parseHour(jamTidurStr, 22);  // Default 10 malam

      // Debugging
      print("Jenis Kelamin: $jenisKelamin, Berat Badan: $beratBadan kg");
      print("Jam Bangun: $wakeUpTime, Jam Tidur: $sleepTime");

      // Jika beratBadan masih 0, beri peringatan
      if (beratBadan <= 0) {
        print("Warning: Berat badan tidak valid. Menggunakan nilai default.");
        beratBadan = 70.0; // Set default weight if invalid
      }
    } catch (e) {
      print("Error saat mengambil data pengguna: $e");
      jenisKelamin = 'Laki-laki';
      beratBadan = 70.0; // Default weight jika error
      wakeUpTime = 6;
      sleepTime = 22;
    }
  }
  
  // Helper method untuk mengekstrak jam dari string format "HH:MM"
  int _parseHour(String timeString, int defaultValue) {
    if (timeString == 'Belum diatur' || timeString.isEmpty) {
      return defaultValue;
    }
    
    try {
      // Untuk format "HH:MM"
      if (timeString.contains(':')) {
        return int.parse(timeString.split(':')[0]);
      }
      // Untuk format integer dalam string
      return int.parse(timeString);
    } catch (e) {
      print("Error parsing time: $e");
      return defaultValue;
    }
  }

  // Menghitung kebutuhan hidrasi harian dalam liter
  double calculateDailyWaterIntake() {
    if (beratBadan <= 0) {
      print("Warning: Berat badan tidak valid. Menggunakan nilai default.");
      beratBadan = 70.0; // Set default weight if invalid
    }

    // Gunakan format yang konsisten dengan database: "Laki-laki" dan "Perempuan"
    if (jenisKelamin == "Laki-laki") {
      return beratBadan * 35 / 1000; // 35ml per kg berat badan untuk laki-laki
    } else {
      return beratBadan * 31 / 1000; // 31ml per kg berat badan untuk perempuan
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