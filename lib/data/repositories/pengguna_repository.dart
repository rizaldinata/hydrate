import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:sqflite/sqflite.dart' as sql;

class PenggunaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // pengecekan apakah sudah ada data pengguna atau belum
  Future<bool> isPenggunaTerdaftar() async {
    try {
      print('[DEBUG] Memulai pengecekan pengguna terdaftar');

      final db = await _dbHelper.database;
      if (db == null || !db.isOpen) {
        print('[ERROR] Koneksi database tidak valid atau tertutup');
        return false;
      }

      print('[DEBUG] Mengeksekusi query ke tabel pengguna');
      final List<Map<String, dynamic>> result = await db.query(
        'pengguna',
        limit: 1,
        columns: ['id'],
      );

      print('[DEBUG] Hasil query: ${result.length} record ditemukan');
      if (result.isNotEmpty) {
        print('[DEBUG] Data pengguna pertama: ${result.first}');
      }

      return result.isNotEmpty;
    } catch (e, stackTrace) {
      print('[ERROR] Gagal memeriksa pengguna terdaftar: $e');
      print('[STACK TRACE] $stackTrace');

      return false;
    } finally {
      print('[DEBUG] Proses pengecekan pengguna selesai');
    }
  }

  Future<int> tambahPenggunaDanProfil(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    final db = await _dbHelper.database;

    try {
      return await db.transaction((txn) async {
        // Insert ke tabel pengguna
        int idPengguna = await txn.insert('pengguna', {'nama_pengguna': nama});
        print("Insert ke 'pengguna' berhasil dengan ID: $idPengguna");

        if (idPengguna == 0) {
          print("Gagal menyisipkan pengguna.");
          return -1;
        }

        // Insert ke tabel profil_pengguna
        int idProfil = await txn.insert('profil_pengguna', {
          'fk_id_pengguna': idPengguna,
          'jenis_kelamin': jenisKelamin,
          'berat_badan': beratBadan,
          'jam_bangun': jamBangun,
          'jam_tidur': jamTidur,
        });
        print("Insert ke 'profil_pengguna' berhasil dengan ID: $idProfil");

        if (idProfil == 0) {
          print("Gagal menyisipkan profil pengguna.");
          return -1;
        }

        // Simpan session jika berhasil
        await SessionManager().saveUserId(idPengguna);
        print("Session berhasil disimpan dengan ID: $idPengguna");

        // Debug: Pastikan data benar-benar masuk ke database
        var penggunaBaru = await txn
            .query('pengguna', where: 'id = ?', whereArgs: [idPengguna]);
        var profilBaru = await txn.query('profil_pengguna',
            where: 'fk_id_pengguna = ?', whereArgs: [idPengguna]);

        print("Data pengguna yang baru dimasukkan: $penggunaBaru");
        print("Data profil yang baru dimasukkan: $profilBaru");

        print("Berhasil menambahkan pengguna dengan ID: $idPengguna");
        return idPengguna;
      });
    } catch (e) {
      print("Gagal menambahkan pengguna: $e");
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
        print("Data pengguna ditemukan: ${pengguna.toMap()}");
        return pengguna;
      } else {
        print("Pengguna dengan ID $id tidak ditemukan.");
        return null;
      }
    } catch (e) {
      print("Error saat mengambil pengguna: $e");
      return null;
    }
  }
}
