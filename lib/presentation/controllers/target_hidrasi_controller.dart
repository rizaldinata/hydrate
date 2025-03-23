import '../../data/models/target_hidrasi_model.dart';
import '../../data/repositories/target_hidrasi_repository.dart';
import 'package:intl/intl.dart';

class TargetHidrasiController {
  final TargetHidrasiRepository _repository = TargetHidrasiRepository();

  // Method untuk mendapatkan presentasi harian
  Future<double> getPresentasiHidrasiHarian(int idPengguna, String tanggal) async {
    return await _repository.getPresentasiHidrasiHarian(idPengguna, tanggal);
  }

  // Memeriksa apakah target hidrasi untuk hari ini sudah ada
  Future<bool> isTargetHidrasiExist(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _repository.checkTargetHidrasiExists(idPengguna, today);
  }

  // Membuat target hidrasi baru
  Future<int> createTargetHidrasi(
    int idPengguna, 
    double targetHidrasi, 
    {double initialIntake = 0.0}
  ) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _repository.createTargetHidrasi(
      idPengguna, 
      targetHidrasi, 
      today, 
      initialIntake
    );
  }

  // Mengupdate total hidrasi harian
  Future<bool> updateTotalHidrasi(
    int idPengguna, 
    double totalHidrasi
  ) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _repository.updateTotalHidrasi(
      idPengguna, 
      today, 
      totalHidrasi
    );
  }

  // Mendapatkan total hidrasi hari ini
  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    return await _repository.getTotalHidrasiHariIni(idPengguna);
  }

  // Mendapatkan target hidrasi untuk hari ini
  Future<TargetHidrasi?> getTargetHidrasiHariIni(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _repository.getTargetHidrasi(idPengguna, today);
  }

  // Mendapatkan target hidrasi untuk tanggal tertentu
  Future<TargetHidrasi?> getTargetHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    return await _repository.getTargetHidrasi(idPengguna, formattedDate);
  }
}