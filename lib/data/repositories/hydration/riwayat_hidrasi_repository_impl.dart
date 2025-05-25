import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:hydrate/data/repositories/hydration/riwayat_hidrasi_repository.dart';

class RiwayatHidrasiRepositoryImpl implements RiwayatHidrasiRepository {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;

  RiwayatHidrasiRepositoryImpl({
    required DatabaseHelper dbHelper,
    required FirestoreService firestoreService,
  })  : _dbHelper = dbHelper,
        _firestoreService = firestoreService;

  @override
  Future<List<Map<String, dynamic>>> getLocalRiwayatHidrasiByTanggal(int localPenggunaId, String tanggal) async {
    final db = await _dbHelper.database;
    return await db.query(
      'riwayat_hidrasi',
      where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ? AND is_deleted = 0',
      whereArgs: [localPenggunaId, tanggal],
    );
  }

  @override
  Future<Map<String, dynamic>?> addRiwayatHidrasi({
    required int localPenggunaId,
    required double jumlah,
    required String tanggal,
    required String waktu,
  }) async {
    try {
      Map<String, dynamic> dataRiwayat = {
        'jumlah_hidrasi': jumlah,
        'tanggal_hidrasi': tanggal,
        'waktu_hidrasi': waktu,
      };
      Map<String, dynamic> recordDitambahkan = await _dbHelper.insertRiwayatHidrasi(dataRiwayat, localPenggunaId);
      String syncId = recordDitambahkan['sync_id'];

      // Langsung sinkronkan ke Firestore
      await _firestoreService.saveRiwayatHidrasiItem(recordDitambahkan, syncId);
      await _dbHelper.markAsSynced('riwayat_hidrasi', syncId);
      
      print("RiwayatHidrasiRepository: Riwayat ditambahkan dan disinkronkan, syncId: $syncId");
      return recordDitambahkan;
    } catch (e) {
      print("RiwayatHidrasiRepository: Error saat menambah riwayat hidrasi: $e");
      return null;
    }
  }

  @override
  Future<bool> softDeleteRiwayatHidrasi(String riwayatSyncId) async {
    try {
      int updatedRows = await _dbHelper.softDeleteRiwayatHidrasi(riwayatSyncId);
      if (updatedRows > 0) {
        // Tandai juga di Firestore
        await _firestoreService.softDeleteRiwayatHidrasiItem(riwayatSyncId);
        // Tandai sebagai sudah sinkron (karena perubahan delete sudah di-push)
        await _dbHelper.markAsSynced('riwayat_hidrasi', riwayatSyncId); 
        print("RiwayatHidrasiRepository: Riwayat di-soft-delete dan disinkronkan, syncId: $riwayatSyncId");
        return true;
      }
      return false;
    } catch (e) {
      print("RiwayatHidrasiRepository: Error saat soft delete riwayat hidrasi: $e");
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllLocalRiwayatHidrasi(int localPenggunaId) async {
    return await _dbHelper.getAllRiwayatHidrasiForPengguna(localPenggunaId);
  }
}