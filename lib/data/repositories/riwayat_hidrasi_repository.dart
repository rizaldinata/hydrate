import 'package:sqflite/sqflite.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class RiwayatHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> tambahRiwayatHidrasi({
    required int fkIdPengguna,
    required double jumlahHidrasi,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Dapatkan waktu saat ini dalam WIB (UTC+7)
      final now = DateTime.now().toUtc().add(Duration(hours: 7));
      final tanggalHariIni = DateFormat('yyyy-MM-dd').format(now);
      final waktuSekarang = DateFormat('HH:mm:ss').format(now);

      print("Menambahkan riwayat hidrasi dengan jumlah: $jumlahHidrasi pada $tanggalHariIni $waktuSekarang WIB");

      int result = await db.rawInsert('''
        INSERT INTO riwayat_hidrasi (fk_id_pengguna, jumlah_hidrasi, tanggal_hidrasi, waktu_hidrasi)
        VALUES (?, ?, ?, ?)
      ''', [fkIdPengguna, jumlahHidrasi, tanggalHariIni, waktuSekarang]);

      if (result > 0) {
        print("Riwayat hidrasi berhasil ditambahkan! ID: $result");
      } else {
        print("Gagal menambahkan riwayat hidrasi.");
      }

      return result;
    } catch (e) {
      print("Error saat menambahkan riwayat hidrasi: $e");
      return -1;
    }
  }

  /// Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal.
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'riwayat_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
        orderBy: 'waktu_hidrasi DESC',
      );

      print("Mengambil riwayat hidrasi untuk tanggal $tanggal: ${maps.length} data");
      return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
    } catch (e) {
      print("Error saat mengambil riwayat hidrasi berdasarkan tanggal: $e");
      return [];
    }
  }

  /// Ambil semua data riwayat hidrasi untuk pengguna tertentu.
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
      print("Error saat mengambil riwayat hidrasi: $e");
      return [];
    }
  }

  /// Menghapus Riwayat Hidrasi berdasarkan ID dan mengembalikan jumlah hidrasi yang dihapus.
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

    print("Jumlah hidrasi yang akan dihapus: $jumlah");

    final deleteResult = await db.delete(
      'riwayat_hidrasi',
      where: 'id = ?',
      whereArgs: [idRiwayat],
    );

    // Menampilkan hasil penghapusan
    print("Jumlah data yang dihapus: $deleteResult");

    return jumlah;
  }

  /// Mendapatkan total asupan hidrasi untuk hari ini.
  Future<double> getTodayIntake(int userId) async {
    final db = await _dbHelper.database;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7))); // Sesuaikan zona waktu
    final result = await db.rawQuery('''
      SELECT SUM(jumlah_hidrasi) as total
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi = ?
    ''', [userId, todayDate]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Mendapatkan rata-rata asupan harian selama N hari terakhir.
  Future<double> getAverageIntakeLastNDays(int userId, int days) async {
    final db = await _dbHelper.database;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: 7)); // Sesuaikan zona waktu
    final DateTime startDate = now.subtract(Duration(days: days));
    final String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(now);

    // Mengambil rata-rata total_hidrasi_harian dari tabel target_hidrasi
    // karena total_hidrasi_harian sudah mencerminkan total asupan per hari.
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

  /// Mendapatkan frekuensi minum rata-rata harian selama N hari terakhir.
  Future<int> getAverageDrinkFrequencyLastNDays(int userId, int days) async {
    final db = await _dbHelper.database;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: 7)); // Sesuaikan zona waktu
    final DateTime startDate = now.subtract(Duration(days: days));
    final String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(now);

    // Query untuk menghitung jumlah entri per hari dalam periode N hari
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

    // Hitung jumlah hari unik dalam periode tersebut
    final List<Map<String, dynamic>> uniqueDates = await db.rawQuery('''
      SELECT DISTINCT tanggal_hidrasi
      FROM riwayat_hidrasi
      WHERE fk_id_pengguna = ? AND tanggal_hidrasi BETWEEN ? AND ?
    ''', [userId, formattedStartDate, formattedEndDate]);

    int numberOfDays = uniqueDates.length;
    if (numberOfDays == 0) return 0;

    return (totalCount / numberOfDays).round(); // Rata-rata frekuensi per hari
  }
}