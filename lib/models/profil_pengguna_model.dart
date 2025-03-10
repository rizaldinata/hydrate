class ProfilPengguna {
  int id;
  int fkIdPengguna;
  String jenisKelamin;
  double beratBadan;
  String? jamBangun;
  String? jamTidur;

  ProfilPengguna(
      {required this.id,
      required this.fkIdPengguna,
      required this.jenisKelamin,
      required this.beratBadan,
      this.jamBangun,
      this.jamTidur});

  factory ProfilPengguna.fromMap(Map<String, dynamic> map) => ProfilPengguna(
        id: map['id'],
        fkIdPengguna: map['fk_id_pengguna'],
        jenisKelamin: map['jenis_kelamin'],
        beratBadan: map['berat_badan'],
        jamBangun: map['jam_bangun'],
        jamTidur: map['jam_tidur'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fk_id_pengguna': fkIdPengguna,
        'jenis_kelamin': jenisKelamin,
        'berat_badan': beratBadan,
        'jam_bangun': jamBangun,
        'jam_tidur': jamTidur,
      };
}
