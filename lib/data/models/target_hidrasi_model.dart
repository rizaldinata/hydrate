class TargetHidrasi {
  final int? id;
  final int fkIdPengguna;
  final double targetHidrasi;
  final String tanggalHidrasi;
  final double totalHidrasiHarian;

  TargetHidrasi({
    this.id,
    required this.fkIdPengguna,
    required this.targetHidrasi,
    required this.tanggalHidrasi,
    required this.totalHidrasiHarian,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fk_id_pengguna': fkIdPengguna,
      'target_hidrasi': targetHidrasi,
      'tanggal_hidrasi': tanggalHidrasi,
      'total_hidrasi_harian': totalHidrasiHarian,
    };
  }

  factory TargetHidrasi.fromMap(Map<String, dynamic> map) {
    return TargetHidrasi(
      id: map['id'],
      fkIdPengguna: map['fk_id_pengguna'],
      targetHidrasi: map['target_hidrasi'],
      tanggalHidrasi: map['tanggal_hidrasi'],
      totalHidrasiHarian: map['total_hidrasi_harian'],
    );
  }
}