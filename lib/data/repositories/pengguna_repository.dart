import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/pengguna_model.dart';

class PenggunaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> isPenggunaTerdaftar() async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> result = await db.query(
        'pengguna',
        limit: 1,
        columns: ['id'],
      );

      return result.isNotEmpty;
    } catch (e) {
      return false;
    } 
  }

  Future<int> tambahPenggunaDanProfil(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    final db = await _dbHelper.database;

    try {
      return await db.transaction((txn) async {
        int idPengguna = await txn.insert('pengguna', {'nama_pengguna': nama});

        if (idPengguna == 0) {
          return -1;
        }

        int idProfil = await txn.insert('profil_pengguna', {
          'fk_id_pengguna': idPengguna,
          'jenis_kelamin': jenisKelamin,
          'berat_badan': beratBadan,
          'jam_bangun': jamBangun,
          'jam_tidur': jamTidur,
        });

        if (idProfil == 0) {
          return -1;
        }

        await SessionManager().saveUserId(idPengguna);
        return idPengguna;
      });
    } catch (e) {
      return -1;
    }
  }

  Future<Pengguna?> getPenggunaById(int id) async {
    final db = await _dbHelper.database;

    try {
      final maps = await db.query(
        'pengguna',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        Pengguna pengguna = Pengguna.fromMap(maps.first);
        return pengguna;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<int> updateNama(int userId, String newNama) async {
    final db = await _dbHelper.database;
    return await db.update(
      'pengguna',
      {'nama_pengguna': newNama}, 
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
