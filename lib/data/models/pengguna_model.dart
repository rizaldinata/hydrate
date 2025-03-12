class Pengguna {
  int? id;
  String nama;

  Pengguna({this.id, required this.nama});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_pengguna': nama,
    };
  }

  factory Pengguna.fromMap(Map<String, dynamic> map) {
    return Pengguna(
      id: map['id'],
      nama: map['nama_pengguna'],
    );
  }
}
