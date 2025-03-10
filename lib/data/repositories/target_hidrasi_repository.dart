import 'package:hydrate/data/database_helper.dart';
import 'package:hydrate/models/target_hidrasi_model.dart';

class TargetHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // tambah target hidrasi (kek e nanti kepakek cuma ditambahin ke repo pengguna waktu register, jadi yang disini ngga kepake)
  Future<int> tambahTargetHidrasi(TargetHidrasi target) async {
    try {
      final db = await _dbHelper.database;

      // cek pengguna udah ada atau belom
      final userExists = (await db.query(
        'pengguna',
        where: 'id = ?',
        whereArgs: [target.fkIdPengguna],
      ))
          .isNotEmpty;

      if (!userExists) {
        print("User dengan ID ${target.fkIdPengguna} tidak ditemukan.");
        return -1;
      }

      int result = await db.insert('target_hidrasi', target.toMap());
      print("Target hidrasi berhasil ditambahkan dengan ID: $result");
      return result;
    } catch (e) {
      print("Error saat menambahkan target hidrasi: $e");
      return -1;
    }
  }

  // ambil data target hidrasi
  Future<TargetHidrasi?> getTargetHidrasi(int idPengguna) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'target_hidrasi',
        where: 'fk_id_pengguna = ?',
        whereArgs: [idPengguna],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return TargetHidrasi.fromMap(maps.first);
      } else {
        print("Target hidrasi untuk pengguna ID $idPengguna tidak ditemukan.");
        return null;
      }
    } catch (e) {
      print("Error saat mengambil target hidrasi: $e");
      return null;
    }
  }
}
