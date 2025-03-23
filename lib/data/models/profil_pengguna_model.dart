// profil_pengguna_model.dart
class ProfilPengguna {
  final int id;
  final int fkIdPengguna;
  final String jenisKelamin;
  final double beratBadan;
  final String jamBangun;
  final String jamTidur;

  ProfilPengguna({
    required this.id,
    required this.fkIdPengguna,
    required this.jenisKelamin,
    required this.beratBadan,
    required this.jamBangun,
    required this.jamTidur,
  });

  factory ProfilPengguna.fromMap(Map<String, dynamic> map) {
    return ProfilPengguna(
      id: map['id'] as int,
      fkIdPengguna: map['fk_id_pengguna'] as int,
      jenisKelamin: map['jenis_kelamin'] as String,
      beratBadan: map['berat_badan'] as double,
      jamBangun: map['jam_bangun'] as String,
      jamTidur: map['jam_tidur'] as String,
    );
  }
}