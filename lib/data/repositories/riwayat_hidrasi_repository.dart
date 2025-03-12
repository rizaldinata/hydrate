import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';

class RiwayatHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // tambah hidrasi dan tambah riwayat hidrasi
  Future<int> tambahRiwayatHidrasi(RiwayatHidrasi riwayat) async {
    try {
      final db = await _dbHelper.database;

      // cek pengguna nya udah ada atau belom
      final userExists = (await db.query(
        'pengguna',
        where: 'id = ?',
        whereArgs: [riwayat.fkIdPengguna],
      ))
          .isNotEmpty;

      if (!userExists) {
        print("User dengan ID ${riwayat.fkIdPengguna} tidak ditemukan.");
        return -1;
      }

      int result = await db.insert('riwayat_hidrasi', riwayat.toMap());
      print("Riwayat hidrasi berhasil ditambahkan dengan ID: $result");
      return result;
    } catch (e) {
      print("Error saat menambahkan riwayat hidrasi: $e");
      return -1;
    }
  }

  // ambil semua data riwayat hidrasi (peripheral kayake sambil nunggu halaman riwayat ada atau ngga)
  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'riwayat_hidrasi',
        where: 'fk_id_pengguna = ?',
        whereArgs: [idPengguna],
        orderBy: 'tanggal_hidrasi DESC',
      );

      return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
    } catch (e) {
      print("Error saat mengambil riwayat hidrasi: $e");
      return [];
    }
  }
}
