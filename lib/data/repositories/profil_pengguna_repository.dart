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

  // // tambah profil pengguna (kek e ngga kepakek dikasih edit aja soalnya tambah nya diinisialisasi waktu register)
  // Future<int> tambahProfilPengguna(ProfilPengguna profil) async {
  //   final db = await _dbHelper.database;
  //   return await db.insert('profil_pengguna', profil.toMap());
  // }

  // // edit profil pengguna
  // Future<int> editProfilPengguna(ProfilPengguna profil) async {
  //   final db = await _dbHelper.database;
  //   return await db.update(
  //     'profil_pengguna',
  //     profil.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [profil.id],
  //   );
  // }
}
