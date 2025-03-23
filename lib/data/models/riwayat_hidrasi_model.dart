class RiwayatHidrasi {
  final int? id;
  final int fkIdPengguna;
  final double jumlahHidrasi;
  final String? tanggalHidrasi;
  final String? waktuHidrasi;
  final String? timestamp;

  RiwayatHidrasi({
    this.id,
    required this.fkIdPengguna,
    required this.jumlahHidrasi,
    this.tanggalHidrasi,
    this.waktuHidrasi,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fk_id_pengguna': fkIdPengguna,
      'jumlah_hidrasi': jumlahHidrasi,
      'tanggal_hidrasi': tanggalHidrasi,
      'waktu_hidrasi': waktuHidrasi,
      'timestamp': timestamp,
    };
  }

  factory RiwayatHidrasi.fromMap(Map<String, dynamic> map) {
    return RiwayatHidrasi(
      id: map['id'],
      fkIdPengguna: map['fk_id_pengguna'],
      jumlahHidrasi: map['jumlah_hidrasi'],
      tanggalHidrasi: map['tanggal_hidrasi'],
      waktuHidrasi: map['waktu_hidrasi'],
      timestamp: map['timestamp'],
    );
  }
}