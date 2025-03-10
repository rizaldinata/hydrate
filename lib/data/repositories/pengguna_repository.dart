import 'package:hydrate/data/database_helper.dart';
import 'package:hydrate/models/pengguna_model.dart';

class PenggunaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // cek sudah pernah daftar atau belom
  Future<bool> isPenggunaTerdaftar() async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> result = await db.query('pengguna');
    return result.isNotEmpty;
  }

  // tambah pengguna dan profil pengguna dalam satu transaksi
  Future<int> tambahPenggunaDanProfil(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      int idPengguna = await txn.insert('pengguna', {'nama_pengguna': nama});

      await txn.insert('profil_pengguna', {
        'fk_id_pengguna': idPengguna,
        'jenis_kelamin': jenisKelamin,
        'berat_badan': beratBadan,
        'jam_bangun': jamBangun,
        'jam_tidur': jamTidur,
      });

      return idPengguna;
    });
  }

  // ambil dara semua pengguna (kek e nanti ngga kepake)
  Future<List<Pengguna>> getPengguna() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('pengguna');

    return List.generate(maps.length, (i) {
      return Pengguna.fromMap(maps[i]);
    });
  }
}
