import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/target_hidrasi_model.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'dart:math';

class TargetHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  double _hitungPersentaseHidrasi(double totalHidrasi, double targetHidrasi) {
    if (targetHidrasi <= 0) return 0.0;

    return min(100.0, (totalHidrasi / targetHidrasi) * 100);
  }

  Future<double> getPresentasiHidrasiHarian(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
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
      return 0.0;
    }
  }

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
      return false;
    }
  }

  Future<double> _calculateTargetHidrasi(int idPengguna) async {
    try {
      final HydrationCalculator calculator = HydrationCalculator(penggunaId: idPengguna);
      await calculator.initializeData(idPengguna); 

      double targetLiter = calculator.calculateDailyWaterIntake();
      double targetMl = targetLiter * 1000;

      if (targetMl <= 0) {
        return 2450.0;
      }
      return targetMl;
    } catch (e) {
      return 2450.0;
    }
  }

  Future<int> createTargetHidrasi(
    int idPengguna,
    double targetHidrasi,
    String tanggal,
    double totalHidrasiHarian,
  ) async {
    try {
      final db = await _dbHelper.database;

      if (targetHidrasi <= 0) {
        targetHidrasi = await _calculateTargetHidrasi(idPengguna);
      }
      double persentase = _hitungPersentaseHidrasi(totalHidrasiHarian, targetHidrasi);

      final int id = await db.insert('target_hidrasi', {
        'fk_id_pengguna': idPengguna,
        'target_hidrasi': targetHidrasi,
        'tanggal_hidrasi': tanggal,
        'total_hidrasi_harian': totalHidrasiHarian,
        'persentase_hidrasi': persentase,
      });

      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<bool> updateTotalHidrasi(
    int idPengguna,
    String tanggal,
    double totalHidrasi,
  ) async {
    try {
      final db = await _dbHelper.database;

      final targetExists = await checkTargetHidrasiExists(idPengguna, tanggal);

      if (targetExists) {
        final List<Map<String, dynamic>> result = await db.query(
          'target_hidrasi',
          columns: ['target_hidrasi'],
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
          limit: 1,
        );

        double targetHidrasi = result.first['target_hidrasi'] ?? 0.0;

        double persentase = _hitungPersentaseHidrasi(totalHidrasi, targetHidrasi);

        final int count = await db.update(
          'target_hidrasi',
          {
            'total_hidrasi_harian': totalHidrasi,
            'persentase_hidrasi': persentase
          },
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
        );

        return count > 0;
      } else {
        double targetHidrasi = await _calculateTargetHidrasi(idPengguna);

        final int id = await createTargetHidrasi(
          idPengguna,
          targetHidrasi,
          tanggal,
          totalHidrasi,
        );

        return id > 0;
      }
    } catch (e) {
      return false;
    }
  }

  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    try {
      final db = await _dbHelper.database;
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));

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
      return 0.0;
    }
  }

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
      return null;
    }
  }

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
        if ((result.first['target_hidrasi'] ?? 0) <= 0) {
          double targetHidrasi = await _calculateTargetHidrasi(idPengguna);
          double totalHidrasi = result.first['total_hidrasi_harian'] ?? 0.0;
          double persentase = _hitungPersentaseHidrasi(totalHidrasi, targetHidrasi);

          await db.update(
            'target_hidrasi',
            {
              'target_hidrasi': targetHidrasi,
              'persentase_hidrasi': persentase
            },
            where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
            whereArgs: [idPengguna, tanggal],
          );

          Map<String, dynamic> updatedResult = Map.from(result.first);
          updatedResult['target_hidrasi'] = targetHidrasi;
          updatedResult['persentase_hidrasi'] = persentase;
          return updatedResult;
        }

        return result.first;
      } else {
        double targetHidrasi = await _calculateTargetHidrasi(idPengguna);
        return {
          'target_hidrasi': targetHidrasi,
          'total_hidrasi_harian': 0.0,
          'persentase_hidrasi': 0.0
        };
      }
    } catch (_) {
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

  Future<double> getAverageDailyTarget(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT AVG(target_hidrasi) as avg_target
      FROM target_hidrasi
      WHERE fk_id_pengguna = ?
    ''', [userId]);

    if (result.isNotEmpty && result.first['avg_target'] != null) {
      return (result.first['avg_target'] as num).toDouble();
    }
    return await _calculateTargetHidrasi(userId); 
  }

  Future<bool> updateTargetHidrasiValue(int idPengguna, String tanggal) async {
    try {
      double newTarget = await _calculateTargetHidrasi(idPengguna);

      final db = await _dbHelper.database;
      final targetExists = await checkTargetHidrasiExists(idPengguna, tanggal);

      if (targetExists) {
        final List<Map<String, dynamic>> result = await db.query(
          'target_hidrasi',
          columns: ['total_hidrasi_harian'],
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
          limit: 1,
        );

        double totalHidrasi = result.first['total_hidrasi_harian'] ?? 0.0;
        double persentase = _hitungPersentaseHidrasi(totalHidrasi, newTarget);

        final int count = await db.update(
          'target_hidrasi',
          {
            'target_hidrasi': newTarget,
            'persentase_hidrasi': persentase
          },
          where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
          whereArgs: [idPengguna, tanggal],
        );

        return count > 0;
      } else {
        final int id = await createTargetHidrasi(
          idPengguna,
          newTarget,
          tanggal,
          0.0,
        );

        return id > 0;
      }
    } catch (_) {
      return false;
    }
  }

  Future<double> fallbackCalculateTarget(int userId) async {
    return await _calculateTargetHidrasi(userId); 
  }

  double internalCalculatePercentage(double totalHidrasi, double targetHidrasi) {
    return _hitungPersentaseHidrasi(totalHidrasi, targetHidrasi); 
  }
}