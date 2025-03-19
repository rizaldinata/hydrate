class ProfilPengguna {
  int? id;
  int fkIdPengguna;
  String namaPengguna;
  String jenisKelamin;
  double beratBadan;
  String? jamBangun;
  String? jamTidur;

  ProfilPengguna({
    this.id,
    required this.fkIdPengguna,
    required this.namaPengguna,
    required this.jenisKelamin,
    required this.beratBadan,
    this.jamBangun,
    this.jamTidur,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fk_id_pengguna': fkIdPengguna,
      'nama_pengguna': namaPengguna,
      'jenis_kelamin': jenisKelamin,
      'berat_badan': beratBadan,
      'jam_bangun': jamBangun,
      'jam_tidur': jamTidur,
    };
  }

  factory ProfilPengguna.fromMap(Map<String, dynamic> map) {
    return ProfilPengguna(
      id: map['id'],
      fkIdPengguna: map['fk_id_pengguna'],
      namaPengguna: map['nama_pengguna'],
      jenisKelamin: map['jenis_kelamin'],
      beratBadan: map['berat_badan'],
      jamBangun: map['jam_bangun'],
      jamTidur: map['jam_tidur'],
    );
  }
}
