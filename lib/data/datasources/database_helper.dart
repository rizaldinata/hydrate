import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pengguna_model.dart';
import '../models/profil_pengguna_model.dart';
import '../models/target_hidrasi_model.dart';
import '../models/riwayat_hidrasi_model.dart';

// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   static Database? _database;

//   factory DatabaseHelper() => _instance;

//   DatabaseHelper._internal();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     try {
//       final path = join(await getDatabasesPath(), 'hydration.db');
//       print("Membuka database di: $path");

//       return await openDatabase(
//         path,
//         version: 1,
//         onCreate: (db, version) async {
//           print("Membuat tabel database...");

//           await db.execute("PRAGMA foreign_keys = ON;");

//           await db.execute('''
//             CREATE TABLE pengguna (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               nama_pengguna TEXT NOT NULL
//             )
//           ''');

//           await db.execute('''
//             CREATE TABLE profil_pengguna (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               fk_id_pengguna INTEGER NOT NULL,
//               jenis_kelamin TEXT NOT NULL,
//               berat_badan REAL NOT NULL,
//               jam_bangun TEXT,
//               jam_tidur TEXT,
//               FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
//             )
//           ''');

//           await db.execute('''
//             CREATE TABLE target_hidrasi (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               fk_id_pengguna INTEGER NOT NULL,
//               target_hidrasi REAL NOT NULL,
//               tanggal_hidrasi TEXT NOT NULL,
//               FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
//             )
//           ''');

//           await db.execute('''
//             CREATE TABLE riwayat_hidrasi (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               fk_id_pengguna INTEGER NOT NULL,
//               jumlah_hidrasi REAL NOT NULL,
//               tanggal_hidrasi TEXT NOT NULL,
//               waktu_hidrasi TEXT NOT NULL,
//               FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
//             )
//           ''');

//           print("Database berhasil dibuat!");
//         },
//         onOpen: (db) async {
//           await db.execute("PRAGMA foreign_keys = ON;");
//           print("Database berhasil dibuka!");
//         },
//       );
//     } catch (e) {
//       print("Error saat membuka database: $e");
//       rethrow;
//     }
//   }

//   // cek apakah pengguna sudah pernah mendaftar
//   Future<bool> isPenggunaTerdaftar() async {
//     try {
//       final db = await database;
//       List<Map<String, dynamic>> result = await db.query('pengguna');

//       print("Jumlah pengguna terdaftar: ${result.length}"); // Tambahkan log ini

//       return result.isNotEmpty;
//     } catch (e) {
//       print("Error saat mengecek pengguna: $e");
//       return false;
//     }
//   }

//   // menambahkan data pengguna pada halaman registrasi
//   Future<void> registerPengguna(
//     String nama,
//     String jenisKelamin,
//     double beratBadan,
//     String jamBangun,
//     String jamTidur,
//   ) async {
//     try {
//       final db = await database;

//       int idPengguna = await db.insert('pengguna', {'nama_pengguna': nama});
//       print("User berhasil didaftarkan dengan ID: $idPengguna");

//       await db.insert('profil_pengguna', {
//         'fk_id_pengguna': idPengguna,
//         'jenis_kelamin': jenisKelamin,
//         'berat_badan': beratBadan,
//         'jam_bangun': jamBangun,
//         'jam_tidur': jamTidur,
//       });

//       print("Profil pengguna berhasil disimpan!");
//     } catch (e) {
//       print("Error saat registrasi pengguna: $e");
//     }
//   }

//   // menambahkan pengguna
//   Future<int> tambahPengguna(Pengguna pengguna) async {
//     final db = await database;
//     int result = await db.insert('pengguna', pengguna.toMap());
//     print("User berhasil ditambahkan dengan ID: $result");
//     return result;
//   }

//   // mengamabil semua data pengguna
//   Future<List<Pengguna>> getPengguna() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('pengguna');

//     return maps.map((map) => Pengguna.fromMap(map)).toList();
//   }

//   Future<int> tambahProfilPengguna(ProfilPengguna profil) async {
//     final db = await database;
//     return await db.insert('profil_pengguna', profil.toMap());
//   }

//   Future<int> tambahTargetHidrasi(TargetHidrasi targetHidrasi) async {
//     final db = await database;
//     return await db.insert('target_hidrasi', targetHidrasi.toMap());
//   }

//   Future<int> tambahRiwayatHidrasi(RiwayatHidrasi riwayatHidrasi) async {
//     try {
//       final db = await database;

//       final userExists = (await db.query(
//         'pengguna',
//         where: 'id = ?',
//         whereArgs: [riwayatHidrasi.fkIdPengguna],
//       ))
//           .isNotEmpty;

//       if (!userExists) {
//         print("User dengan ID ${riwayatHidrasi.fkIdPengguna} tidak ditemukan.");
//         return -1; 
//       }

//       int result = await db.insert('riwayat_hidrasi', riwayatHidrasi.toMap());
//       print("Riwayat hidrasi berhasil ditambahkan dengan ID: $result");
//       return result;
//     } catch (e) {
//       print("Error saat menambahkan riwayat hidrasi: $e");
//       return -1;
//     }
//   }

//   Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'riwayat_hidrasi',
//       where: 'fk_id_pengguna = ?',
//       whereArgs: [idPengguna],
//       orderBy: 'tanggal_hidrasi DESC',
//     );
//     return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
//   }
// }

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), 'hydration.db');
      print("Membuka database di: $path");

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          print("Membuat tabel database...");

          await db.execute("PRAGMA foreign_keys = ON;");

          await db.execute('''
            CREATE TABLE pengguna (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama_pengguna TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE profil_pengguna (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fk_id_pengguna INTEGER NOT NULL,
              jenis_kelamin TEXT NOT NULL,
              berat_badan REAL NOT NULL,
              jam_bangun TEXT,
              jam_tidur TEXT,
              FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE target_hidrasi (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fk_id_pengguna INTEGER NOT NULL,
  target_hidrasi REAL NOT NULL,
  tanggal_hidrasi TEXT NOT NULL,  -- Bisa menggunakan tanggal untuk memisahkan target per hari
  total_hidrasi_harian REAL NOT NULL,  -- Untuk memudahkan perbandingan konsumsi dengan target harian
  FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
);

          ''');

          await db.execute('''
            CREATE TABLE riwayat_hidrasi (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fk_id_pengguna INTEGER NOT NULL,
  jumlah_hidrasi REAL NOT NULL,
  tanggal_hidrasi TEXT NOT NULL,
  waktu_hidrasi TEXT NOT NULL,  -- Diganti menjadi timestamp atau tetap disesuaikan
  timestamp INTEGER NOT NULL,   -- Kolom timestamp untuk waktu yang lebih spesifik
  FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
);

          ''');

          print("Database berhasil dibuat!");
        },
        onOpen: (db) async {
          await db.execute("PRAGMA foreign_keys = ON;");
          print("Database berhasil dibuka!");
        },
      );
    } catch (e) {
      print("Error saat membuka database: $e");
      rethrow;
    }
  }
}
