import 'package:hydrate/data/datasources/database_helper.dart'; 
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:intl/intl.dart';

class RiwayatHidrasiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> tambahRiwayatHidrasi({
    required int fkIdPengguna,
    required double jumlahHidrasi,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Dapatkan waktu saat ini dalam WIB (UT+7)
      final now = DateTime.now().toUtc().add(Duration(hours: 7));
      final tanggalHariIni = DateFormat('yyyy-MM-dd').format(now);
      final waktuSekarang = DateFormat('HH:mm').format(now);

      print("Menambahkan riwayat hidrasi dengan jumlah: $jumlahHidrasi pada $tanggalHariIni $waktuSekarang WIB");

      int result = await db.rawInsert('''
      INSERT INTO riwayat_hidrasi (fk_id_pengguna, jumlah_hidrasi, tanggal_hidrasi, waktu_hidrasi, timestamp)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
    ''', [fkIdPengguna, jumlahHidrasi, tanggalHariIni, waktuSekarang]);

      if (result > 0) {
        print("Riwayat hidrasi berhasil ditambahkan! ID: $result");
      } else {
        print("Gagal menambahkan riwayat hidrasi.");
      }

      return result;
    } catch (e) {
      print("Error saat menambahkan riwayat hidrasi: $e");
      return -1;
    }
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, String tanggal) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'riwayat_hidrasi',
        where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ?',
        whereArgs: [idPengguna, tanggal],
        orderBy: 'waktu_hidrasi DESC',
      );

      print("Mengambil riwayat hidrasi untuk tanggal $tanggal: ${maps.length} data");
      return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
    } catch (e) {
      print("Error saat mengambil riwayat hidrasi berdasarkan tanggal: $e");
      return [];
    }
  }

  // ambil semua data riwayat hidrasi
  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'riwayat_hidrasi',
        where: 'fk_id_pengguna = ?',
        whereArgs: [idPengguna],
        orderBy: 'tanggal_hidrasi DESC, waktu_hidrasi DESC',
      );

      return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
    } catch (e) {
      print("Error saat mengambil riwayat hidrasi: $e");
      return [];
    }
  }
}