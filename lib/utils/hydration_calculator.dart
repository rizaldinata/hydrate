class HydrationCalculator {
  final String gender; // jenis kelamin nya ya bess
  final double weight; // kg
  final int wakeUpTime; // jam (24-hour format)
  final int sleepTime; // jam (24-hour format)

  HydrationCalculator({
    required this.gender,
    required this.weight,
    required this.wakeUpTime,
    required this.sleepTime,
  });

  /// Menghitung kebutuhan hidrasi harian dalam liter
  double calculateDailyWaterIntake() {
    double baseIntake = weight * 35 / 1000; // 35ml per kg berat badan

    if (gender.toLowerCase() == "male") {
      baseIntake *= 1.1; // Tambah 10% untuk laki-laki
    }

    return baseIntake;
  }

  /// Menghitung distribusi hidrasi sepanjang hari
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
