import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/target_hidrasi_model.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'dart:math';

class TargetHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Method untuk menghitung persentase hidrasi
  double _hitungPersentaseHidrasi(double totalHidrasi, double targetHidrasi) {
    if (targetHidrasi <= 0) return 0.0;
    
    // Batasi maksimal 100%
    return min(100.0, (totalHidrasi / targetHidrasi) * 100);
  }
  
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

      // Gunakan persentase yang tersimpan di database
      final targetHidrasi = results.first;
      final double persentaseHidrasi = targetHidrasi['persentase_hidrasi'] ?? 0.0;
      
      return persentaseHidrasi;
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

  // Mendapatkan target hidrasi berdasarkan data pengguna
  Future<double> _calculateTargetHidrasi(int idPengguna) async {
    try {
      // Menggunakan HydrationCalculator untuk menghitung target hidrasi secara dinamis
      final HydrationCalculator calculator = HydrationCalculator(penggunaId: idPengguna);
      await calculator.initializeData(idPengguna);
      
      // Mendapatkan target dalam liter dan konversi ke mililiter
      double targetLiter = calculator.calculateDailyWaterIntake();
      double targetMl = targetLiter * 1000;
      
      // Pastikan target memiliki nilai valid
      if (targetMl <= 0) {
        print("Target hidrasi tidak valid, menggunakan berat default untuk perhitungan");
        // Gunakan berat default 70kg untuk perhitungan jika target tidak valid
        // Untuk wanita: 70 * 35 / 1000 = 2.45L = 2450mL
        return 2450.0;
      }
      
      return targetMl;
    } catch (e) {
      print("Error saat menghitung target hidrasi: $e");
      // Gunakan rumus dengan berat standar 70kg untuk perhitungan darurat
      // Untuk wanita: 70 * 35 / 1000 = 2.45L = 2450mL
      return 2450.0;
    }
  }

  // Membuat target hidrasi baru dengan perhitungan dinamis
  Future<int> createTargetHidrasi(
    int idPengguna, 
    double targetHidrasi, 
    String tanggal,
    double totalHidrasiHarian
  ) async {
    try {
      final db = await _dbHelper.database;
      
      // Jika target adalah 0 atau negatif, hitung menggunakan calculator
      if (targetHidrasi <= 0) {
        targetHidrasi = await _calculateTargetHidrasi(idPengguna);
      }
      
      // Hitung persentase hidrasi
      double persentase = _hitungPersentaseHidrasi(totalHidrasiHarian, targetHidrasi);
      
      final int id = await db.insert('target_hidrasi', {
        'fk_id_pengguna': idPengguna,
        'target_hidrasi': targetHidrasi,
        'tanggal_hidrasi': tanggal,
        'total_hidrasi_harian': totalHidrasiHarian,
        'persentase_hidrasi': persentase,
      });
      
      print("Target hidrasi berhasil dibuat dengan ID: $id (Target: $targetHidrasi mL, Persentase: $persentase%)");
      return id;
    } catch (e) {
      print("Error saat membuat target hidrasi: $e");
      return -1;
    }
  }

  // Mengupdate total hidrasi harian dan persentase
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
        // Dapatkan target hidrasi untuk menghitung persentase
        final List<Map<String, dynamic>> result = await db.query(
          'target_hidrasi',
          columns: ['target_hidrasi'],
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
          limit: 1,
        );
        
        double targetHidrasi = result.first['target_hidrasi'] ?? 0.0;
        
        // Hitung persentase hidrasi
        double persentase = _hitungPersentaseHidrasi(totalHidrasi, targetHidrasi);
        
        // Update total hidrasi dan persentase yang sudah ada
        final int count = await db.update(
          'target_hidrasi',
          {
            'total_hidrasi_harian': totalHidrasi,
            'persentase_hidrasi': persentase
          },
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
        );
        
        print("Target hidrasi berhasil diupdate: $count row(s). Total: $totalHidrasi mL, Persentase: $persentase%");
        return count > 0;
      } else {
        // Jika belum ada, buat target hidrasi baru dengan perhitungan dinamis
        double targetHidrasi = await _calculateTargetHidrasi(idPengguna);
        
        final int id = await createTargetHidrasi(
          idPengguna, 
          targetHidrasi, 
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

  // Method untuk mendapatkan target hidrasi harian (nilai target saja)
  Future<Map<String, dynamic>?> getTargetHidrasiHarian(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> result = await db.query(
        'target_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        // Jika targetnya 0 atau negatif, hitung ulang
        if ((result.first['target_hidrasi'] ?? 0) <= 0) {
          double targetHidrasi = await _calculateTargetHidrasi(idPengguna);
          double totalHidrasi = result.first['total_hidrasi_harian'] ?? 0.0;
          double persentase = _hitungPersentaseHidrasi(totalHidrasi, targetHidrasi);
          
          // Update target yang sudah ada dengan nilai yang benar
          await db.update(
            'target_hidrasi',
            {
              'target_hidrasi': targetHidrasi,
              'persentase_hidrasi': persentase
            },
            where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
            whereArgs: [idPengguna, tanggal],
          );
          
          // Kembalikan data yang diperbarui
          Map<String, dynamic> updatedResult = Map.from(result.first);
          updatedResult['target_hidrasi'] = targetHidrasi;
          updatedResult['persentase_hidrasi'] = persentase;
          return updatedResult;
        }
        
        return result.first;
      } else {
        // Jika tidak ada data untuk tanggal tersebut, hitung target dinamis
        double targetHidrasi = await _calculateTargetHidrasi(idPengguna);
        return {
          'target_hidrasi': targetHidrasi,
          'total_hidrasi_harian': 0.0,
          'persentase_hidrasi': 0.0
        };
      }
    } catch (e) {
      print("Error saat mendapatkan target hidrasi harian: $e");
      
      // Jika terjadi kesalahan, hitung target dinamis sebagai fallback
      try {
        double targetHidrasi = await _calculateTargetHidrasi(idPengguna);
        return {
          'target_hidrasi': targetHidrasi,
          'total_hidrasi_harian': 0.0,
          'persentase_hidrasi': 0.0
        };
      } catch (_) {
        return null;
      }
    }
  }
  
  // Metode untuk mengupdate target hidrasi berdasarkan perubahan data pengguna
  Future<bool> updateTargetHidrasiValue(int idPengguna, String tanggal) async {
    try {
      // Hitung ulang target hidrasi berdasarkan data pengguna terbaru
      double newTarget = await _calculateTargetHidrasi(idPengguna);
      
      final db = await _dbHelper.database;
      final targetExists = await checkTargetHidrasiExists(idPengguna, tanggal);
      
      if (targetExists) {
        // Dapatkan total hidrasi saat ini untuk menghitung persentase baru
        final List<Map<String, dynamic>> result = await db.query(
          'target_hidrasi',
          columns: ['total_hidrasi_harian'],
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
          limit: 1,
        );
        
        double totalHidrasi = result.first['total_hidrasi_harian'] ?? 0.0;
        double persentase = _hitungPersentaseHidrasi(totalHidrasi, newTarget);
        
        // Update target hidrasi yang sudah ada dan persentase
        final int count = await db.update(
          'target_hidrasi',
          {
            'target_hidrasi': newTarget,
            'persentase_hidrasi': persentase
          },
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
        );
        
        print("Target hidrasi berhasil diperbarui menjadi $newTarget mL dengan persentase $persentase%");
        return count > 0;
      } else {
        // Jika belum ada, buat target hidrasi baru
        final int id = await createTargetHidrasi(
          idPengguna, 
          newTarget, 
          tanggal, 
          0.0 // Total hidrasi awal adalah 0
        );
        
        return id > 0;
      }
    } catch (e) {
      print("Error saat mengupdate nilai target hidrasi: $e");
      return false;
    }
  }
}