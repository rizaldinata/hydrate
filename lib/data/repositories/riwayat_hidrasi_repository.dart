import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:intl/intl.dart';

class RiwayatHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> tambahRiwayatHidrasi({
    required int fkIdPengguna,
    required double jumlahHidrasi,
  }) async {
    try {
      final db = await _dbHelper.database;

      final now = DateTime.now().toUtc().add(Duration(hours: 7));
      final tanggalHariIni = DateFormat('yyyy-MM-dd').format(now);
      final waktuSekarang = DateFormat('HH:mm:ss').format(now);

      int result = await db.rawInsert('''
        INSERT INTO riwayat_hidrasi (fk_id_pengguna, jumlah_hidrasi, tanggal_hidrasi, waktu_hidrasi)
        VALUES (?, ?, ?, ?)
      ''', [fkIdPengguna, jumlahHidrasi, tanggalHariIni, waktuSekarang]);

      return result;
    } catch (e) {
      return -1;
    }
  }

  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'riwayat_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
        orderBy: 'waktu_hidrasi DESC',
      );

      return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'riwayat_hidrasi',
        where: 'fk_id_pengguna = ?',
        whereArgs: [idPengguna],
        orderBy: 'tanggal_hidrasi DESC, waktu_hidrasi DESC',
      );

      return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<double?> hapusRiwayatBerdasarkanId(int idRiwayat) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'riwayat_hidrasi',
      columns: ['jumlah_hidrasi'],
      where: 'id = ?',
      whereArgs: [idRiwayat],
    );

    if (result.isEmpty) return null;

    final double jumlah = result.first['jumlah_hidrasi'];

    await db.delete(
      'riwayat_hidrasi',
      where: 'id = ?',
      whereArgs: [idRiwayat],
    );
    return jumlah;
  }

  Future<double> getTodayIntake(int userId) async {
    final db = await _dbHelper.database;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final result = await db.rawQuery('''
      SELECT SUM(jumlah_hidrasi) as total
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi = ?
    ''', [userId, todayDate]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getAverageIntakeLastNDays(int userId, int days) async {
    final db = await _dbHelper.database;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: 7));
    final DateTime startDate = now.subtract(Duration(days: days));
    final String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(now);

    final result = await db.rawQuery('''
      SELECT AVG(total_hidrasi_harian) as avg_intake
      FROM target_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi BETWEEN ? AND ?
    ''', [userId, formattedStartDate, formattedEndDate]);

    if (result.isNotEmpty && result.first['avg_intake'] != null) {
      return (result.first['avg_intake'] as num).toDouble();
    }
    return 0.0;
  }

  Future<int> getAverageDrinkFrequencyLastNDays(int userId, int days) async {
    final db = await _dbHelper.database;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: 7));
    final DateTime startDate = now.subtract(Duration(days: days));
    final String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(now);

    final List<Map<String, dynamic>> dailyCounts = await db.rawQuery('''
      SELECT COUNT(id) as count, tanggal_hidrasi
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi BETWEEN ? AND ?
      GROUP BY tanggal_hidrasi
    ''', [userId, formattedStartDate, formattedEndDate]);

    if (dailyCounts.isEmpty) {
      return 0;
    }

    double totalCount = 0;
    for (var row in dailyCounts) {
      totalCount += (row['count'] as int);
    }

    final List<Map<String, dynamic>> uniqueDates = await db.rawQuery('''
      SELECT DISTINCT tanggal_hidrasi
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi BETWEEN ? AND ?
    ''', [userId, formattedStartDate, formattedEndDate]);

    int numberOfDays = uniqueDates.length;
    if (numberOfDays == 0) return 0;

    return (totalCount / numberOfDays).round();
  }

  Future<List<Map<String, dynamic>>> getDailyHydrationForWeek(int userId, DateTime weekEndDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> dailyTotals = [];

    for (int i = 6; i >= 0; i--) {
      final currentDate = weekEndDate.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);

      final result = await db.rawQuery('''
        SELECT SUM(jumlah_hidrasi) as total
        FROM riwayat_hidrasi
        WHERE fk_id_pengguna = ? AND tanggal_hidrasi = ?
      ''', [userId, formattedDate]);
      
      double totalForDay = (result.first['total'] as num?)?.toDouble() ?? 0.0;

      int dayIndex = 6 - i;
      dailyTotals.add({
        'x': dayIndex,
        'y': totalForDay,
        'label': DateFormat('E', 'id_ID').format(currentDate),
      });
    }
    return dailyTotals;
  }

  Future<List<Map<String, dynamic>>> getWeeklyHydrationForMonth(int userId, int year, int month) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> weeklyTotals = [];

    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    DateTime currentWeekStart = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    if (firstDayOfMonth.weekday == DateTime.sunday) { 
        currentWeekStart = firstDayOfMonth.subtract(Duration(days: 6));
    }

    int weekIndex = 0;
    while (currentWeekStart.isBefore(lastDayOfMonth) || currentWeekStart.isAtSameMomentAs(lastDayOfMonth)) {
      DateTime currentWeekEnd = currentWeekStart.add(Duration(days: 6));

      String formattedWeekStart = DateFormat('yyyy-MM-dd').format(currentWeekStart);
      String formattedWeekEnd = DateFormat('yyyy-MM-dd').format(currentWeekEnd);

      final result = await db.rawQuery('''
        SELECT SUM(jumlah_hidrasi) as total
        FROM riwayat_hidrasi
        WHERE fk_id_pengguna = ? AND tanggal_hidrasi BETWEEN ? AND ?
      ''', [userId, formattedWeekStart, formattedWeekEnd]);
      
      double totalForWeek = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      weeklyTotals.add({'x': weekIndex, 'y': totalForWeek, 'label': 'M${weekIndex + 1}'});
      
      currentWeekStart = currentWeekStart.add(Duration(days: 7));
      weekIndex++;
      if (weekIndex > 4 && currentWeekStart.month != month) break; 
    }
    return weeklyTotals;
  }

  Future<List<Map<String, dynamic>>> getMonthlyHydrationForYear(int userId, int year) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> monthlyTotals = [];

    for (int month = 1; month <= 12; month++) {
      String monthPadded = month.toString().padLeft(2, '0');
      final result = await db.rawQuery('''
        SELECT SUM(jumlah_hidrasi) as total
        FROM riwayat_hidrasi
        WHERE fk_id_pengguna = ? AND INSTR(tanggal_hidrasi, ?) > 0 
      ''', [userId, '$year-$monthPadded']);
      
      double totalForMonth = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      monthlyTotals.add({'x': month - 1, 'y': totalForMonth, 'label': DateFormat('MMM', 'id_ID').format(DateTime(year, month))});
    }
    return monthlyTotals;
  }
}