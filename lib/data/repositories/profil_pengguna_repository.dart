import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';

class ProfilPenggunaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<ProfilPengguna?> getProfilPenggunaByUserId(int fkIdPengguna) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'profil_pengguna',
      where: 'fk_id_pengguna = ?',
      whereArgs: [fkIdPengguna],
    );

    if (result.isNotEmpty) {
      return ProfilPengguna.fromMap(result.first);
    }
    return null;
  }
}
