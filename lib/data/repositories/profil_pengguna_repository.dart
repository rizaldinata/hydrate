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

  // Method Repository Update Profil Pengguna dengan jam bangun dan jam tidur
  Future<int> updateProfilPenggunaLengkap({
    required int fkIdPengguna,
    required String jenisKelamin,
    required double beratBadan,
    required String jamBangun,
    required String jamTidur,
  }) async {
    try {
      final db = await _dbHelper.database;
      final existingProfile = await getProfilPenggunaByUserId(fkIdPengguna);
      
      if (existingProfile == null) {
        // Jika profil belum ada, buat baru
        return await db.insert(
          'profil_pengguna',
          {
            'fk_id_pengguna': fkIdPengguna,
            'jenis_kelamin': jenisKelamin,
            'berat_badan': beratBadan,
            'jam_bangun': jamBangun,
            'jam_tidur': jamTidur,
          },
        );
      } else {
        // Update profil yang sudah ada
        return await db.update(
          'profil_pengguna',
          {
            'jenis_kelamin': jenisKelamin,
            'berat_badan': beratBadan,
            'jam_bangun': jamBangun,
            'jam_tidur': jamTidur,
          },
          where: 'fk_id_pengguna = ?',
          whereArgs: [fkIdPengguna],
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception('Database error: $e');
    }
  }
  
  // Method lama dipertahankan untuk backward compatibility
  Future<int> updateProfilPengguna({
    required int fkIdPengguna,
    required String jenisKelamin,
    required double beratBadan,
  }) async {
    try {
      final currentProfile = await getProfilPenggunaByUserId(fkIdPengguna);
      final jamBangun = currentProfile?.jamBangun ?? 'Belum diatur';
      final jamTidur = currentProfile?.jamTidur ?? 'Belum diatur';
      
      return await updateProfilPenggunaLengkap(
        fkIdPengguna: fkIdPengguna, 
        jenisKelamin: jenisKelamin, 
        beratBadan: beratBadan,
        jamBangun: jamBangun,
        jamTidur: jamTidur,
      );
    } catch (e) {
      print("Error in updateProfilPengguna: $e");
      return 0;
    }
  }
}