import 'package:hydrate/data/models/hydration_stats_model.dart';
import 'package:hydrate/data/repositories/riwayat_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat

class HydrationStatsRepository {
  final RiwayatHidrasiRepository _riwayatRepo = RiwayatHidrasiRepository();
  final TargetHidrasiRepository _targetRepo = TargetHidrasiRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<HydrationStatsModel> getHydrationStatistics(int userId) async {
    try {
      final double todayIntake = await _riwayatRepo.getTodayIntake(userId);

      final double weeklyAverageIntake = await _riwayatRepo.getAverageIntakeLastNDays(userId, 7);

      final double monthlyAverageIntake = await _riwayatRepo.getAverageIntakeLastNDays(userId, 30);

      final int averageDailyDrinkFrequency = await _riwayatRepo.getAverageDrinkFrequencyLastNDays(userId, 7);

      final double averageDailyTarget = await _targetRepo.getAverageDailyTarget(userId);

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> completionResult = await db.rawQuery('''
        SELECT AVG(persentase_hidrasi) as avg_completion
        FROM target_hidrasi
        WHERE fk_id_pengguna = ?
      ''', [userId]);
      double averageCompletionRate = (completionResult.first['avg_completion'] as num?)?.toDouble() ?? 0.0;

      return HydrationStatsModel(
        weeklyAverageIntake: weeklyAverageIntake,
        monthlyAverageIntake: monthlyAverageIntake,
        averageCompletionRate: averageCompletionRate,
        averageDailyDrinkFrequency: averageDailyDrinkFrequency,
        todayIntake: todayIntake,
        averageDailyTarget: averageDailyTarget,
      );
    } catch (e) {
      return HydrationStatsModel.empty();
    }
  }

  Future<void> updateDailyTargetAndCompletion(int userId, DateTime date) async {
    final db = await _dbHelper.database;
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final todayIntakeResult = await db.rawQuery('''
      SELECT SUM(jumlah_hidrasi) as total
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi = ?
    ''', [userId, formattedDate]);
    double currentDayTotalIntake = (todayIntakeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final targetResult = await db.query(
      'target_hidrasi',
      columns: ['id', 'target_hidrasi'],
      where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
      whereArgs: [userId, formattedDate],
    );

    if (targetResult.isNotEmpty) {
      final int targetId = targetResult.first['id'] as int;
      final double dailyTarget = targetResult.first['target_hidrasi'] as double;

      double completionPercentage = 0.0;
      if (dailyTarget > 0) {
        completionPercentage = (currentDayTotalIntake / dailyTarget) * 100;
      }
      completionPercentage = completionPercentage.clamp(0.0, 100.0);

      await db.update(
        'target_hidrasi',
        {
          'total_hidrasi_harian': currentDayTotalIntake,
          'persentase_hidrasi': completionPercentage,
        },
        where: 'id = ?',
        whereArgs: [targetId],
      );
    } else {
      await _targetRepo.createTargetHidrasi(
        userId,
        0.0,
        formattedDate,
        currentDayTotalIntake,
      );
    }
  }
}