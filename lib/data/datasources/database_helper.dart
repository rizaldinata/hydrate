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
        version: 2, // Naikkan versi untuk migrasi
        onCreate: (db, version) async {
          print("Membuat tabel database...");

          await db.execute("PRAGMA foreign_keys = ON;");

          // Tabel Pengguna
          await db.execute('''
            CREATE TABLE pengguna (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama_pengguna TEXT NOT NULL
            )
          ''');

          // Tabel Profil Pengguna
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

          // Tabel Target Hidrasi
          await db.execute('''
            CREATE TABLE target_hidrasi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fk_id_pengguna INTEGER NOT NULL,
              target_hidrasi REAL NOT NULL,
              tanggal_hidrasi TEXT NOT NULL,
              total_hidrasi_harian REAL NOT NULL,
              persentase_hidrasi REAL DEFAULT 0.0,
              FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
            )
          ''');

          // Tabel Riwayat Hidrasi
          await db.execute('''
            CREATE TABLE riwayat_hidrasi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fk_id_pengguna INTEGER NOT NULL,
              jumlah_hidrasi REAL NOT NULL,
              tanggal_hidrasi TEXT NOT NULL,
              waktu_hidrasi TEXT NOT NULL,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
            )
          ''');

          print("Database berhasil dibuat!");
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Migrasi database jika diperlukan
          if (oldVersion < 2) {
            // Tambahkan kolom persentase_hidrasi ke tabel target_hidrasi
            await db.execute('''
              ALTER TABLE target_hidrasi 
              ADD COLUMN persentase_hidrasi REAL DEFAULT 0.0
            ''');
            print("Kolom persentase_hidrasi berhasil ditambahkan");
          }
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

  // Method untuk update skema jika diperlukan
  Future<void> updateTargetHidrasiSchema() async {
    try {
      final db = await database;
      
      final columns = await db.rawQuery("PRAGMA table_info(target_hidrasi)");
      
      bool hasPersentaseColumn = columns.any((column) => 
        column['name'] == 'persentase_hidrasi'
      );

      if (!hasPersentaseColumn) {
        await db.execute('''
          ALTER TABLE target_hidrasi 
          ADD COLUMN persentase_hidrasi REAL DEFAULT 0.0
        ''');
        print("Kolom persentase_hidrasi berhasil ditambahkan");
      }
    } catch (e) {
      print("Error saat update skema: $e");
    }
  }
}