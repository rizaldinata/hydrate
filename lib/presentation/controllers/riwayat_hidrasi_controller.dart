import '../../data/models/riwayat_hidrasi_model.dart';
import '../../data/repositories/riwayat_hidrasi_repository.dart';

class RiwayatHidrasiController {
  final RiwayatHidrasiRepository _repository = RiwayatHidrasiRepository();

  // tambah hidrasi dan tambah riwayat hidrasi
  Future<int> tambahRiwayatHidrasi(RiwayatHidrasi riwayat) async {
    return await _repository.tambahRiwayatHidrasi(riwayat);
  }

  // tampilin semua riwayat hidrasi
  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    return await _repository.getRiwayatHidrasi(idPengguna);
  }
}
