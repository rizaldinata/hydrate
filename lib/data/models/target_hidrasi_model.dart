// File: lib/data/models/target_hidrasi_model.dart

class TargetHidrasi {
  final int? id;
  final int fkIdPengguna;
  final double targetHidrasi;
  final String tanggalHidrasi;
  final double totalHidrasiHarian;
  final double persentaseHidrasi;

  TargetHidrasi({
    this.id,
    required this.fkIdPengguna,
    required this.targetHidrasi,
    required this.tanggalHidrasi,
    required this.totalHidrasiHarian,
    this.persentaseHidrasi = 0.0,
  });

  // Factory constructor untuk membuat objek TargetHidrasi dari Map
  factory TargetHidrasi.fromMap(Map<String, dynamic> map) {
    return TargetHidrasi(
      id: map['id'],
      fkIdPengguna: map['fk_id_pengguna'],
      targetHidrasi: map['target_hidrasi'],
      tanggalHidrasi: map['tanggal_hidrasi'],
      totalHidrasiHarian: map['total_hidrasi_harian'],
      persentaseHidrasi: map['persentase_hidrasi'] ?? 0.0,
    );
  }

  // Konversi objek TargetHidrasi ke Map untuk penyimpanan database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fk_id_pengguna': fkIdPengguna,
      'target_hidrasi': targetHidrasi,
      'tanggal_hidrasi': tanggalHidrasi,
      'total_hidrasi_harian': totalHidrasiHarian,
      'persentase_hidrasi': persentaseHidrasi,
    };
  }

  // Membuat salinan objek TargetHidrasi dengan nilai yang diubah
  TargetHidrasi copyWith({
    int? id,
    int? fkIdPengguna,
    double? targetHidrasi,
    String? tanggalHidrasi,
    double? totalHidrasiHarian,
    double? persentaseHidrasi,
  }) {
    return TargetHidrasi(
      id: id ?? this.id,
      fkIdPengguna: fkIdPengguna ?? this.fkIdPengguna,
      targetHidrasi: targetHidrasi ?? this.targetHidrasi,
      tanggalHidrasi: tanggalHidrasi ?? this.tanggalHidrasi,
      totalHidrasiHarian: totalHidrasiHarian ?? this.totalHidrasiHarian,
      persentaseHidrasi: persentaseHidrasi ?? this.persentaseHidrasi,
    );
  }

  @override
  String toString() {
    return 'TargetHidrasi{id: $id, fkIdPengguna: $fkIdPengguna, targetHidrasi: $targetHidrasi, '
        'tanggalHidrasi: $tanggalHidrasi, totalHidrasiHarian: $totalHidrasiHarian, '
        'persentaseHidrasi: $persentaseHidrasi}';
  }
}