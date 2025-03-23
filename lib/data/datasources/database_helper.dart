import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // menampilkan database dari sqlite
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
              jam_bangun TEXT NOT NULL,
              jam_tidur TEXT NOT NULL,
              FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE target_hidrasi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fk_id_pengguna INTEGER NOT NULL,
            target_hidrasi REAL NOT NULL,
            tanggal_hidrasi TEXT NOT NULL,
            total_hidrasi_harian REAL NOT NULL, 
            FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
          );
          ''');

          await db.execute('''
            CREATE TABLE riwayat_hidrasi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fk_id_pengguna INTEGER NOT NULL,
            jumlah_hidrasi REAL NOT NULL,
            tanggal_hidrasi TEXT NOT NULL,
            waktu_hidrasi TEXT NOT NULL,  
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
