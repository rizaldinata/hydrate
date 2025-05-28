class RiwayatHidrasi {
  final int? id;
  final int fkIdPengguna;
  final double jumlahHidrasi;
  final String tanggalHidrasi;
  final String waktuHidrasi;
  final String? createdAt; // DateTime disimpan sebagai TEXT di SQLite

  RiwayatHidrasi({
    this.id,
    required this.fkIdPengguna,
    required this.jumlahHidrasi,
    required this.tanggalHidrasi,
    required this.waktuHidrasi,
    this.createdAt,
  });

  factory RiwayatHidrasi.fromMap(Map<String, dynamic> map) {
    return RiwayatHidrasi(
      id: map['id'],
      fkIdPengguna: map['fk_id_pengguna'],
      jumlahHidrasi: map['jumlah_hidrasi'],
      tanggalHidrasi: map['tanggal_hidrasi'],
      waktuHidrasi: map['waktu_hidrasi'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fk_id_pengguna': fkIdPengguna,
      'jumlah_hidrasi': jumlahHidrasi,
      'tanggal_hidrasi': tanggalHidrasi,
      'waktu_hidrasi': waktuHidrasi,
      'created_at': createdAt ?? DateTime.now().toIso8601String(), // Set default if null
    };
  }
}