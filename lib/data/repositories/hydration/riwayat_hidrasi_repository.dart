abstract class RiwayatHidrasiRepository {
  /// Menambahkan catatan minum baru ke DB lokal dan langsung sinkronisasi.
  Future<Map<String, dynamic>?> addRiwayatHidrasi({
    required int localPenggunaId,
    required double jumlah,
    required String tanggal,
    required String waktu,
  });

  /// Melakukan soft delete pada catatan minum di DB lokal dan sinkronisasi.
  Future<bool> softDeleteRiwayatHidrasi(String riwayatSyncId);

  /// Mengambil semua data riwayat minum dari DB lokal untuk pengguna tertentu.
  Future<List<Map<String, dynamic>>> getAllLocalRiwayatHidrasi(int localPenggunaId);

  Future<List<Map<String, dynamic>>> getLocalRiwayatHidrasiByTanggal(int localPenggunaId, String tanggal);
}