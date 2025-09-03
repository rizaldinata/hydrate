import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

      return await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
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
              berat_badan REAL NOT NULL CHECK (berat_badan >= 1 AND berat_badan <= 300),
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
              persentase_hidrasi REAL DEFAULT 0.0,
              FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
            )
          ''');

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

        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              ALTER TABLE target_hidrasi 
              ADD COLUMN persentase_hidrasi REAL DEFAULT 0.0
            ''');
          }
        },
        onOpen: (db) async {
          await db.execute("PRAGMA foreign_keys = ON;");
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTargetHidrasiSchema() async {
    try {
      final db = await database;

      final columns = await db.rawQuery("PRAGMA table_info(target_hidrasi)");

      bool hasPersentaseColumn =
          columns.any((column) => column['name'] == 'persentase_hidrasi');

      if (!hasPersentaseColumn) {
        await db.execute('''
          ALTER TABLE target_hidrasi 
          ADD COLUMN persentase_hidrasi REAL DEFAULT 0.0
        ''');
      }
    } catch (e) {
      rethrow;
    }
  }
}
