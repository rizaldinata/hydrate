abstract class TargetHidrasiRepository {
  /// Menyimpan atau memperbarui target harian, lalu sinkronisasi.
  Future<Map<String, dynamic>?> saveOrUpdateTargetHidrasi({
    required int localPenggunaId,
    required String tanggal,
    required double target,
    double? totalHarian,
    double? persentase,
  });

  /// Mengambil data target dari DB lokal untuk tanggal tertentu.
  Future<Map<String, dynamic>?> getLocalTargetHidrasi(int localPenggunaId, String tanggal);
  
  /// Alias untuk getLocalTargetHidrasi, untuk konsistensi API.
  Future<Map<String, dynamic>?> getTargetHidrasiHarian(int userId, String tanggal);

  /// Memeriksa apakah target untuk tanggal tertentu sudah ada di DB lokal.
  Future<bool> checkTargetHidrasiExists(int userId, String tanggal);

  /// Membuat target baru untuk tanggal tertentu.
  Future<Map<String, dynamic>?> createTargetHidrasi(
    int userId, 
    double targetValue, 
    String tanggal, 
    double initialTotalIntake,
  );

  /// Memperbarui nilai target jika berbeda dengan yang sudah ada di DB.
  Future<void> updateTargetHidrasiValueIfDifferent(
    int userId, 
    String tanggal, 
    double newCalculatedTarget,
  );

  /// Memperbarui total minum harian dan persentase pada record target.
  Future<Map<String, dynamic>?> updateTotalHidrasi(
    int userId, 
    String tanggal, 
    double newTotalIntake,
  );
}