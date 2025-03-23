import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/target_hidrasi_model.dart';
import 'package:intl/intl.dart';

class TargetHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
    // Method untuk mendapatkan presentasi harian
  Future<double> getPresentasiHidrasiHarian(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      
      // Query untuk mengambil data target hidrasi
      final List<Map<String, dynamic>> results = await db.query(
        'target_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
      );

      if (results.isEmpty) {
        return 0.0; // Jika tidak ada data, kembalikan 0
      }

      final targetHidrasi = results.first;
      final double target = targetHidrasi['target_hidrasi'] ?? 0.0;
      final double totalHidrasi = targetHidrasi['total_hidrasi_harian'] ?? 0.0;

      // Hitung presentasi
      if (target > 0) {
        return (totalHidrasi / target) * 100;
      } else {
        return 0.0;
      }
    } catch (e) {
      print("Error saat menghitung presentasi hidrasi: $e");
      return 0.0;
    }
  }

  // Memeriksa apakah target hidrasi untuk hari ini sudah ada
  Future<bool> checkTargetHidrasiExists(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> result = await db.query(
        'target_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      print("Error saat memeriksa target hidrasi: $e");
      return false;
    }
  }

  // Membuat target hidrasi baru
  Future<int> createTargetHidrasi(
    int idPengguna, 
    double targetHidrasi, 
    String tanggal,
    double totalHidrasiHarian
  ) async {
    try {
      final db = await _dbHelper.database;
      
      final int id = await db.insert('target_hidrasi', {
        'fk_id_pengguna': idPengguna,
        'target_hidrasi': targetHidrasi,
        'tanggal_hidrasi': tanggal,
        'total_hidrasi_harian': totalHidrasiHarian,
      });
      
      print("Target hidrasi berhasil dibuat dengan ID: $id");
      return id;
    } catch (e) {
      print("Error saat membuat target hidrasi: $e");
      return -1;
    }
  }

  // Mengupdate total hidrasi harian
  Future<bool> updateTotalHidrasi(
    int idPengguna, 
    String tanggal, 
    double totalHidrasi
  ) async {
    try {
      final db = await _dbHelper.database;
      
      // Periksa apakah target hidrasi untuk hari ini sudah ada
      final targetExists = await checkTargetHidrasiExists(idPengguna, tanggal);
      
      if (targetExists) {
        // Update total hidrasi yang sudah ada
        final int count = await db.update(
          'target_hidrasi',
          {'total_hidrasi_harian': totalHidrasi},
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
        );
        
        print("Target hidrasi berhasil diupdate: $count row(s)");
        return count > 0;
      } else {
        // Jika belum ada, buat target hidrasi baru
        // Kita perlu mendapatkan target hidrasi dari HydrationCalculator atau nilai default
        // Untuk sementara gunakan nilai default 2000
        const double defaultTarget = 2000.0;
        final int id = await createTargetHidrasi(
          idPengguna, 
          defaultTarget, 
          tanggal, 
          totalHidrasi
        );
        
        return id > 0;
      }
    } catch (e) {
      print("Error saat mengupdate total hidrasi: $e");
      return false;
    }
  }

  // Mendapatkan total hidrasi hari ini
  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    try {
      final db = await _dbHelper.database;
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final List<Map<String, dynamic>> result = await db.query(
        'target_hidrasi',
        columns: ['total_hidrasi_harian'],
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, today],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['total_hidrasi_harian'] as double;
      } else {
        return 0.0;
      }
    } catch (e) {
      print("Error saat mendapatkan total hidrasi hari ini: $e");
      return 0.0;
    }
  }

  // Mendapatkan target hidrasi untuk tanggal tertentu
  Future<TargetHidrasi?> getTargetHidrasi(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> result = await db.query(
        'target_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return TargetHidrasi.fromMap(result.first);
      } else {
        return null;
      }
    } catch (e) {
      print("Error saat mendapatkan target hidrasi: $e");
      return null;
    }
  }

  getTargetHidrasiHarian(int i, String todayDate) {}
}