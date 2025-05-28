class HydrationStatsModel {
  final double weeklyAverageIntake;
  final double monthlyAverageIntake;
  final double averageCompletionRate;
  final int averageDailyDrinkFrequency;
  final double todayIntake;
  final double averageDailyTarget;

  HydrationStatsModel({
    required this.weeklyAverageIntake,
    required this.monthlyAverageIntake,
    required this.averageCompletionRate,
    required this.averageDailyDrinkFrequency,
    required this.todayIntake,
    required this.averageDailyTarget,
  });

  // Konstruktor pabrik untuk data kosong atau keadaan error
  factory HydrationStatsModel.empty() {
    return HydrationStatsModel(
      weeklyAverageIntake: 0.0,
      monthlyAverageIntake: 0.0,
      averageCompletionRate: 0.0,
      averageDailyDrinkFrequency: 0,
      todayIntake: 0.0,
      averageDailyTarget: 2500.0, // Nilai default atau placeholder
    );
  }
}