import 'package:hydrate/data/database_helper.dart';
import 'package:hydrate/models/profil_pengguna_model.dart';

class ProfilPenggunaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // tambah profil pengguna (kek e ngga kepakek dikasih edit aja soalnya tambah nya diinisialisasi waktu register)
  Future<int> tambahProfilPengguna(ProfilPengguna profil) async {
    final db = await _dbHelper.database;
    return await db.insert('profil_pengguna', profil.toMap());
  }
}
