import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';

class ProfilPenggunaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Method Repository Mengambil Data Profil Pengguna 
  Future<ProfilPengguna?> getProfilPenggunaByUserId(int fkIdPengguna) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'profil_pengguna',
      where: 'fk_id_pengguna = ?',
      whereArgs: [fkIdPengguna],
    );
    return result.isNotEmpty ? ProfilPengguna.fromMap(result.first) : null;
  }

  // Method Repository Update Profil Pengguna
  Future<int> updateProfilPengguna({
    required int fkIdPengguna,
    required String jenisKelamin,
    required double beratBadan,
  }) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'profil_pengguna',
        {
          'jenis_kelamin': jenisKelamin,
          'berat_badan': beratBadan,
        },
        where: 'fk_id_pengguna = ?',
        whereArgs: [fkIdPengguna],
      );
    } catch (e) {
      print("Error updating profile: $e");
      return 0;
    }
  }
}