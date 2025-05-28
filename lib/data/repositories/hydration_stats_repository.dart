import 'package:hydrate/data/models/hydration_stats_model.dart';
import 'package:hydrate/data/repositories/riwayat_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:sqflite/sqflite.dart'; // Pastikan ini diimpor jika ada rawQuery di sini
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat

class HydrationStatsRepository {
  final RiwayatHidrasiRepository _riwayatRepo = RiwayatHidrasiRepository();
  final TargetHidrasiRepository _targetRepo = TargetHidrasiRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Untuk query langsung jika diperlukan

  /// Mengambil semua statistik hidrasi yang diperlukan untuk laporan.
  ///
  /// Menggabungkan data dari RiwayatHidrasiRepository dan TargetHidrasiRepository
  /// untuk menyajikan gambaran lengkap hidrasi pengguna.
  Future<HydrationStatsModel> getHydrationStatistics(int userId) async {
    try {
      // Dapatkan asupan hidrasi untuk hari ini.
      final double todayIntake = await _riwayatRepo.getTodayIntake(userId);

      // Dapatkan rata-rata asupan mingguan (7 hari terakhir).
      final double weeklyAverageIntake = await _riwayatRepo.getAverageIntakeLastNDays(userId, 7);

      // Dapatkan rata-rata asupan bulanan (30 hari terakhir).
      final double monthlyAverageIntake = await _riwayatRepo.getAverageIntakeLastNDays(userId, 30);

      // Dapatkan frekuensi minum rata-rata harian (7 hari terakhir).
      final int averageDailyDrinkFrequency = await _riwayatRepo.getAverageDrinkFrequencyLastNDays(userId, 7);

      // Dapatkan rata-rata target harian pengguna dari semua target yang pernah ditetapkan.
      final double averageDailyTarget = await _targetRepo.getAverageDailyTarget(userId);

      // Dapatkan rata-rata persentase penyelesaian dari tabel target_hidrasi.
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> completionResult = await db.rawQuery('''
        SELECT AVG(persentase_hidrasi) as avg_completion
        FROM target_hidrasi
        WHERE fk_id_pengguna = ?
      ''', [userId]);
      double averageCompletionRate = (completionResult.first['avg_completion'] as num?)?.toDouble() ?? 0.0;

      // Mengembalikan objek HydrationStatsModel dengan semua data yang terkumpul.
      return HydrationStatsModel(
        weeklyAverageIntake: weeklyAverageIntake,
        monthlyAverageIntake: monthlyAverageIntake,
        averageCompletionRate: averageCompletionRate,
        averageDailyDrinkFrequency: averageDailyDrinkFrequency,
        todayIntake: todayIntake,
        averageDailyTarget: averageDailyTarget,
      );
    } catch (e) {
      // Tangani error dan kembalikan model kosong sebagai fallback.
      print("Error fetching hydration statistics: $e");
      return HydrationStatsModel.empty();
    }
  }

  /// Memperbarui total hidrasi harian dan persentase penyelesaian di tabel `target_hidrasi`
  /// untuk tanggal tertentu.
  ///
  /// Metode ini harus dipanggil setiap kali pengguna mencatat asupan hidrasi baru
  /// atau menghapus riwayat hidrasi.
  Future<void> updateDailyTargetAndCompletion(int userId, DateTime date) async {
    final db = await _dbHelper.database;
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // 1. Hitung total asupan hidrasi untuk tanggal ini dari riwayat_hidrasi.
    final todayIntakeResult = await db.rawQuery('''
      SELECT SUM(jumlah_hidrasi) as total
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi = ?
    ''', [userId, formattedDate]);
    double currentDayTotalIntake = (todayIntakeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Dapatkan entri target hidrasi untuk tanggal ini.
    final targetResult = await db.query(
      'target_hidrasi',
      columns: ['id', 'target_hidrasi'],
      where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
      whereArgs: [userId, formattedDate],
    );

    if (targetResult.isNotEmpty) {
      // Jika entri target sudah ada, perbarui.
      final int targetId = targetResult.first['id'] as int;
      final double dailyTarget = targetResult.first['target_hidrasi'] as double;

      // 3. Hitung persentase hidrasi berdasarkan asupan saat ini dan target harian.
      double completionPercentage = 0.0;
      if (dailyTarget > 0) {
        completionPercentage = (currentDayTotalIntake / dailyTarget) * 100;
      }
      // Batasi persentase agar tidak melebihi 100%.
      completionPercentage = completionPercentage.clamp(0.0, 100.0);

      // 4. Perbarui kolom `total_hidrasi_harian` dan `persentase_hidrasi` di tabel `target_hidrasi`.
      await db.update(
        'target_hidrasi',
        {
          'total_hidrasi_harian': currentDayTotalIntake,
          'persentase_hidrasi': completionPercentage,
        },
        where: 'id = ?',
        whereArgs: [targetId],
      );
      print("Target hidrasi dan persentase untuk $formattedDate berhasil diperbarui.");
    } else {
      // Jika belum ada entri target_hidrasi untuk hari ini, buat yang baru.
      print("Tidak ada target hidrasi ditemukan untuk $formattedDate. Membuat entri default.");
      // Dapatkan target default dari profil pengguna atau hitung ulang jika perlu.
      // Di sini kita memanggil _targetRepo.createTargetHidrasi yang akan menghitung
      // target dinamis jika target yang diberikan adalah 0 atau negatif.
      await _targetRepo.createTargetHidrasi( // Perbaikan: Menggunakan createTargetHidrasi
        userId,
        0.0, // Berikan 0.0 agar createTargetHidrasi menghitung target dinamis
        formattedDate,
        currentDayTotalIntake,
      );
      print("Entri target hidrasi default dibuat untuk $formattedDate.");
    }
  }
}