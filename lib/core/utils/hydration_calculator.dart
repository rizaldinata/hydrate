class HydrationCalculator {
  // Jadikan field ini final karena nilainya di-set sekali saat konstruksi
  final String jenisKelamin;
  final double beratBadan;
  final int wakeUpTimeHour; // Simpan sebagai jam (integer)
  final int sleepTimeHour;  // Simpan sebagai jam (integer)

  // Constructor baru yang menerima semua data yang diperlukan
  HydrationCalculator({
    required String jenisKelaminInput,
    required double beratBadanInput,
    required String jamBangunInputStr, // Terima sebagai String "HH:MM"
    required String jamTidurInputStr,  // Terima sebagai String "HH:MM"
  }) : // Inisialisasi field di sini
       jenisKelamin = jenisKelaminInput,
       // Validasi dan set default jika berat badan tidak valid
       beratBadan = (beratBadanInput <= 0 || beratBadanInput > 300) ? 70.0 : beratBadanInput,
       // Parse string jam menjadi integer jam, dengan default jika parsing gagal
       wakeUpTimeHour = _parseHourFromString(jamBangunInputStr, 6), // Default jam 6
       sleepTimeHour = _parseHourFromString(jamTidurInputStr, 22);  // Default jam 22
       
       // Anda bisa menambahkan print di sini jika ingin debug nilai setelah inisialisasi
       // print("HydrationCalculator initialized: JK=$jenisKelamin, BB=$beratBadan, Bangun=$wakeUpTimeHour, Tidur=$sleepTimeHour");


  // Helper method statis untuk mengekstrak jam dari string format "HH:MM"
  // Statis karena tidak bergantung pada instance state dari HydrationCalculator
  static int _parseHourFromString(String? timeString, int defaultValue) {
    if (timeString == null || timeString == 'Belum diatur' || timeString.isEmpty) {
      return defaultValue;
    }
    try {
      if (timeString.contains(':')) {
        return int.parse(timeString.split(':')[0]);
      }
      // Jika formatnya hanya angka (misal "6" atau "22")
      return int.parse(timeString);
    } catch (e) {
      print("HydrationCalculator: Error parsing time string '$timeString': $e");
      return defaultValue;
    }
  }

  // Menghitung kebutuhan hidrasi harian dalam liter
  // Metode ini sekarang menggunakan field dari instance
  double calculateDailyWaterIntake() {
    // jenisKelamin dan beratBadan sudah divalidasi/default di constructor
    if (jenisKelamin == "Laki-laki") {
      return beratBadan * 35 / 1000; // 35ml per kg berat badan untuk laki-laki
    } else { // Asumsi default atau "Perempuan"
      return beratBadan * 31 / 1000; // 31ml per kg berat badan untuk perempuan
    }
  }

  // Menghitung distribusi hidrasi sepanjang hari
  // Metode ini sekarang menggunakan field dari instance
  Map<String, double> calculateWaterDistribution() {
    double totalIntake = calculateDailyWaterIntake();
    int totalActiveHours = sleepTimeHour - wakeUpTimeHour;
    
    // Penyesuaian jika jam tidur melewati tengah malam (misal bangun jam 6, tidur jam 1)
    if (totalActiveHours <= 0) {
      totalActiveHours += 24; 
    }
    
    if (totalActiveHours == 0) return {}; // Hindari pembagian dengan nol

    double hourlyIntake = totalIntake / totalActiveHours;

    Map<String, double> schedule = {};
    for (int i = 0; i < totalActiveHours; i++) {
      int currentHour = (wakeUpTimeHour + i) % 24; // Agar jam tetap 0-23
      schedule["${currentHour.toString().padLeft(2, '0')}:00"] = hourlyIntake;
    }
    return schedule;
  }
}