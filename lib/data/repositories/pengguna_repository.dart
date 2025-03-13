import 'package:hydrate/data/datasources/database_helper.dart';
// import 'package:hydrate/data/models/pengguna_model.dart';

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

    try {
      return await db.transaction((txn) async {
        int idPengguna = await txn.insert('pengguna', {'nama_pengguna': nama});
        await txn.insert('profil_pengguna', {
          'fk_id_pengguna': idPengguna,
          'jenis_kelamin': jenisKelamin,
          'berat_badan': beratBadan,
          'jam_bangun': jamBangun,
          'jam_tidur': jamTidur,
        });

        print("Berhasil menambahkan pengguna dengan ID: $idPengguna");
        return idPengguna;
      });
    } catch (e) {
      print("Gagal menambahkan pengguna: $e");
      return -1;
    }
  }

  // ambil dara semua pengguna (kek e nanti ngga kepake)
 Future<Map<String, dynamic>> getPenggunaById(int id) async {
  final db = await _dbHelper.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'profil_pengguna',
    where: 'id = ?',
    whereArgs: [id],
  );
  
  if (maps.isNotEmpty) {
    return maps.first; // Mengambil data pengguna pertama
  } else {
    throw Exception("Pengguna tidak ditemukan");
  }
}

Future<Map<String, dynamic>> getPenggunaBynama(String nama) async {
  final db = await _dbHelper.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'pengguna',
    where: 'nama_pengguna = ?',
    whereArgs: [nama],
  );
  
  if (maps.isNotEmpty) {
     
    return maps.first; // Mengambil data pengguna pertama
  } else {
    throw Exception("Pengguna tidak ditemukan");
  }
}

}
