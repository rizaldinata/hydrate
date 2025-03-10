class TargetHidrasi {
  int id;
  int fkIdPengguna;
  double targetHidrasi;
  String tanggalHidrasi;

  TargetHidrasi({
    required this.id,
    required this.fkIdPengguna,
    required this.targetHidrasi,
    required this.tanggalHidrasi,
  });

  factory TargetHidrasi.fromMap(Map<String, dynamic> map) => TargetHidrasi(
        id: map['id'],
        fkIdPengguna: map['fk_id_pengguna'],
        targetHidrasi: map['target_hidrasi'],
        tanggalHidrasi: map['tanggal_hidrasi'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fk_id_pengguna': fkIdPengguna,
        'target_hidrasi': targetHidrasi,
        'tanggal_hidrasi': tanggalHidrasi,
      };
}
