import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate/utils/hydration_calculator.dart';

void main() {
  group('Hydration Calculator Tests', () {
    test('Menghitung kebutuhan air harian untuk laki-laki 70kg', () {
      var calculator = HydrationCalculator(
        gender: "male",
        weight: 70, // kg
        wakeUpTime: 6, // 6 AM
        sleepTime: 22, // 10 PM
      );

      double result = calculator.calculateDailyWaterIntake();
      expect(result, closeTo(2.695, 0.1)); // Perkiraan 2.695 liter
    });

    test('Menghitung kebutuhan air harian untuk perempuan 60kg', () {
      var calculator = HydrationCalculator(
        gender: "female",
        weight: 60, // kg
        wakeUpTime: 7, // 7 AM
        sleepTime: 23, // 11 PM
      );

      double result = calculator.calculateDailyWaterIntake();
      expect(result, closeTo(2.1, 0.1)); // Perkiraan 2.1 liter
    });

    test('Distribusi hidrasi sepanjang hari', () {
      var calculator = HydrationCalculator(
        gender: "male",
        weight: 80, // kg
        wakeUpTime: 6,
        sleepTime: 22,
      );

      Map<String, double> distribution = calculator.calculateWaterDistribution();
      expect(distribution.length, 16); // Dari 6:00 hingga 21:00
      expect(distribution["6:00"], isNotNull);
      expect(distribution["21:00"], isNotNull);
    });
  });
}
