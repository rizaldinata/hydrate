import '../../data/models/target_hidrasi_model.dart';
import '../../data/repositories/target_hidrasi_repository.dart';

class TargetHidrasiController {
  final TargetHidrasiRepository _repository = TargetHidrasiRepository();

  // tambah riwayat hidrasi (nanti ini diganti edit aja / gimana soalnya nanti bakal diinisialisasi di pengguna controller)
  Future<int> tambahTargetHidrasi(TargetHidrasi target) async {
    return await _repository.tambahTargetHidrasi(target);
  }
}
