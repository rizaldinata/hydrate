class RiwayatHidrasi {
  final int? id;
  final int fkIdPengguna;
  final double jumlahHidrasi;
  final String? tanggalHidrasi;
  final String? waktuHidrasi;
  final String? timestamp;
  final DateTime? createdAt;

  RiwayatHidrasi({
    this.id,
    required this.fkIdPengguna,
    required this.jumlahHidrasi,
    this.tanggalHidrasi,
    this.waktuHidrasi,
    this.timestamp,
    this.createdAt
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fk_id_pengguna': fkIdPengguna,
      'jumlah_hidrasi': jumlahHidrasi,
      'tanggal_hidrasi': tanggalHidrasi,
      'waktu_hidrasi': waktuHidrasi,
      'timestamp': timestamp,
      'createdAt' : createdAt,
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
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }
  @override
  String toString() {
    return 'RiwayatHidrasi{id: $id, waktu: $waktuHidrasi, createdAt: $createdAt}';
  }
}
