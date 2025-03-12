import '../../presentation/controllers/pengguna_controller.dart';

class HydrationCalculator {
  final PenggunaController _penggunaController = PenggunaController(); // Inisialisasi controller pengguna

  late String gender;
  late double weight;
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
      // Ambil data pengguna berdasarkan ID
      Map<String, dynamic> penggunaData = await _penggunaController.getPenggunaById(penggunaId);

      // Debugging: Periksa data pengguna yang terambil
      print("Data Pengguna: $penggunaData");

      // Setel nilai properti berdasarkan data pengguna
      gender = penggunaData['jenis_kelamin'];
      weight = penggunaData['berat_badan'];
      wakeUpTime = penggunaData['wakeUpTime'] ?? 6; // Default jam bangun: 06:00
      sleepTime = penggunaData['sleepTime'] ?? 22; // Default jam tidur: 22:00

      // Debugging: Memeriksa apakah data sudah terisi dengan benar
      print("Gender: $gender, Weight: $weight");

      // Jika weight masih 0, beri peringatan
      if (weight <= 0) {
        print("Warning: Weight is not valid. Using default value.");
        weight = 70.0; // Set default weight if invalid
      }

    } catch (e) {
      print("Error saat mengambil data pengguna: $e");
      gender = 'unknown';
      weight = 70.0; // Set default weight if error occurs
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
