class RiwayatHidrasi {
  int? id;
  int fkIdPengguna;
  double jumlahHidrasi;
  String tanggalHidrasi;
  String waktuHidrasi;

  RiwayatHidrasi({
    this.id,
    required this.fkIdPengguna,
    required this.jumlahHidrasi,
    required this.tanggalHidrasi,
    required this.waktuHidrasi,
  });

  factory RiwayatHidrasi.fromMap(Map<String, dynamic> map) => RiwayatHidrasi(
        id: map['id'],
        fkIdPengguna: map['user_id'],
        jumlahHidrasi: map['jumlah_hidrasi'],
        tanggalHidrasi: map['tanggal_hidrasi'],
        waktuHidrasi: map['waktu_hidrasi'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': fkIdPengguna,
        'jumlah_hidrasi': jumlahHidrasi,
        'tanggal_hidrasi': tanggalHidrasi,
        'waktu_hidrasi': waktuHidrasi,
      };
}
