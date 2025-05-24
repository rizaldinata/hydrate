import 'package:sqflite/sqflite.dart' as sql; // Menggunakan alias sql
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sql.Database? _database; // Menggunakan alias sql.Database
  final Uuid _uuid = Uuid();

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    final path = join(await sql.getDatabasesPath(), 'hydration_v4.db'); // Naikkan versi nama file jika ada perubahan skema besar
    print("DatabaseHelper: Path DB: $path");
    return await sql.openDatabase( // Menggunakan alias sql.openDatabase
      path,
      version: 1, // Versi awal untuk skema yang konsisten dengan PenggunaRepository baru
      onCreate: _createDb,
      onUpgrade: _onUpgradeDb,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON;");
        print("DatabaseHelper: Database berhasil dibuka!");
      },
    );
  }

  Future<void> _createDb(sql.Database db, int version) async {
    print("DatabaseHelper: Membuat tabel database versi $version...");
    await db.execute("PRAGMA foreign_keys = ON;");

    // Tabel Pengguna
    await db.execute('''
      CREATE TABLE pengguna (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pengguna TEXT NOT NULL,
        firebase_uid TEXT UNIQUE, 
        last_modified_locally INTEGER,
        is_synced INTEGER DEFAULT 0 
      )
    ''');

    // Tabel Profil Pengguna
    await db.execute('''
      CREATE TABLE profil_pengguna (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE NOT NULL,
        fk_id_pengguna INTEGER NOT NULL UNIQUE,
        jenis_kelamin TEXT NOT NULL,
        berat_badan REAL NOT NULL,
        jam_bangun TEXT NOT NULL,
        jam_tidur TEXT NOT NULL,
        last_modified_locally INTEGER,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Target Hidrasi
    await db.execute('''
      CREATE TABLE target_hidrasi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE NOT NULL, -- Ini akan diisi dengan tanggal YYYY-MM-DD
        fk_id_pengguna INTEGER NOT NULL,
        target_hidrasi REAL NOT NULL,
        tanggal_hidrasi TEXT NOT NULL, -- Seharusnya sama dengan sync_id untuk tabel ini
        total_hidrasi_harian REAL NOT NULL DEFAULT 0.0,
        persentase_hidrasi REAL DEFAULT 0.0,
        last_modified_locally INTEGER,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE,
        UNIQUE (fk_id_pengguna, tanggal_hidrasi) 
      )
    ''');

    // Tabel Riwayat Hidrasi
    await db.execute('''
      CREATE TABLE riwayat_hidrasi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE NOT NULL,
        fk_id_pengguna INTEGER NOT NULL,
        jumlah_hidrasi REAL NOT NULL,
        tanggal_hidrasi TEXT NOT NULL, 
        waktu_hidrasi TEXT NOT NULL, 
        created_at INTEGER, 
        last_modified_locally INTEGER,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (fk_id_pengguna) REFERENCES pengguna (id) ON DELETE CASCADE
      )
    ''');
    print("DatabaseHelper: Semua tabel berhasil dibuat!");
  }

  Future<void> _onUpgradeDb(sql.Database db, int oldVersion, int newVersion) async {
    print("DatabaseHelper: Upgrading database from version $oldVersion to $newVersion");
    // Tambahkan ALTER TABLE statement di sini jika ada perubahan skema di versi mendatang
    // if (oldVersion < 2) {
    //   await db.execute("ALTER TABLE nama_tabel ADD COLUMN nama_kolom_baru TEXT;");
    // }
  }

  // --- PENGGUNA ---
  Future<int> insertPengguna(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('pengguna', {
      ...row, // Asumsi 'nama_pengguna' dan 'firebase_uid' sudah ada di 'row'
      'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0, // Data baru lokal dianggap belum sinkron
    });
  }

  Future<int?> getLocalPenggunaId(String firebaseUid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pengguna',
      columns: ['id'],
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first['id'] as int?;
    return null;
  }

  Future<Map<String, dynamic>?> getPenggunaByFirebaseUid(String firebaseUid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pengguna',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

    Future<Map<String, dynamic>?> getPenggunaByLocalId(int localId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pengguna',
      where: 'id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }


  // --- PROFIL PENGGUNA ---
  // Mengembalikan Map yang berisi data yang diinsert termasuk ID lokal dan sync_id
  Future<Map<String, dynamic>> insertProfilPengguna(Map<String, dynamic> row, int fkPenggunaId) async {
    final db = await database;
    String syncId = _uuid.v4();
    Map<String, dynamic> dataToInsert = {
      ...row, // jenisKelamin, beratBadan, jamBangun, jamTidur
      'sync_id': syncId,
      'fk_id_pengguna': fkPenggunaId,
      'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
      'is_deleted': 0,
    };
    int recordId = await db.insert('profil_pengguna', dataToInsert,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return {...dataToInsert, 'id': recordId};
  }

  Future<int> updateProfilPengguna(Map<String, dynamic> row, String syncId) async {
    final db = await database;
    return await db.update(
        'profil_pengguna',
        {
          ...row, // Hanya field yang diupdate (misal jenisKelamin, beratBadan, dll.)
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0, // Tandai belum sinkron karena ada perubahan
        },
        where: 'sync_id = ? AND is_deleted = 0',
        whereArgs: [syncId]);
  }

  Future<Map<String, dynamic>?> getProfilPenggunaByLocalId(int localPenggunaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profil_pengguna',
      where: 'fk_id_pengguna = ? AND is_deleted = 0',
      whereArgs: [localPenggunaId],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<Map<String, dynamic>?> getProfilPenggunaBySyncId(String syncId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profil_pengguna',
      where: 'sync_id = ? AND is_deleted = 0',
      whereArgs: [syncId],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> insertOrReplaceProfilFromFirestore(Map<String, dynamic> firestoreData, int fkPenggunaId) async {
  final db = await database;
  print("DatabaseHelper: Memulai insertOrReplaceProfilFromFirestore. Data: $firestoreData, FkPenggunaId: $fkPenggunaId");
  try {
    await db.insert(
      'profil_pengguna',
      {
        ...firestoreData, // Pastikan firestoreData memiliki 'sync_id'
        'fk_id_pengguna': fkPenggunaId,
        'is_synced': 1, // Data dari server dianggap sudah sinkron
        'is_deleted': firestoreData['is_deleted'] ?? 0,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    print("DatabaseHelper: SUKSES insertOrReplaceProfilFromFirestore untuk sync_id: ${firestoreData['sync_id']}");
  } catch (e, s) {
    print("DatabaseHelper: GAGAL insertOrReplaceProfilFromFirestore. Error: $e");
    print("Stacktrace: $s");
    rethrow; // Penting untuk me-rethrow agar error bisa ditangani di atasnya jika perlu
  }
}

  // --- RIWAYAT HIDRASI ---
  Future<Map<String, dynamic>> insertRiwayatHidrasi(Map<String, dynamic> row, int fkPenggunaId) async {
    final db = await database;
    String syncId = _uuid.v4();
    Map<String, dynamic> dataToInsert = {
      ...row, // jumlah_hidrasi, tanggal_hidrasi, waktu_hidrasi
      'sync_id': syncId,
      'fk_id_pengguna': fkPenggunaId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
      'is_deleted': 0,
    };
    int recordId = await db.insert('riwayat_hidrasi', dataToInsert);
    return {...dataToInsert, 'id': recordId};
  }

  Future<int> softDeleteRiwayatHidrasi(String syncId) async {
    final db = await database;
    return await db.update(
      'riwayat_hidrasi',
      {
        'is_deleted': 1,
        'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
      where: 'sync_id = ? AND is_deleted = 0',
      whereArgs: [syncId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllRiwayatHidrasiForPengguna(int localPenggunaId) async {
    final db = await database;
    return await db.query(
      'riwayat_hidrasi',
      where: 'fk_id_pengguna = ? AND is_deleted = 0',
      whereArgs: [localPenggunaId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> insertOrReplaceRiwayatFromFirestore(Map<String, dynamic> firestoreData, int fkPenggunaId) async {
    final db = await database;
    await db.insert(
      'riwayat_hidrasi',
      {
        ...firestoreData, // Pastikan firestoreData memiliki 'sync_id'
        'fk_id_pengguna': fkPenggunaId,
        'is_synced': 1,
        'is_deleted': firestoreData['is_deleted'] ?? 0,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  // --- TARGET HIDRASI ---
  Future<Map<String, dynamic>> insertOrReplaceTargetHidrasi(Map<String, dynamic> row, int fkPenggunaId) async {
    final db = await database;
    // Untuk target_hidrasi, sync_id adalah tanggal_hidrasi (YYYY-MM-DD)
    String syncId = row['tanggal_hidrasi'] as String; // Pastikan ini ada di 'row'

    Map<String, dynamic> dataToInsert = {
      ...row, // target_hidrasi, total_hidrasi_harian, persentase_hidrasi
      'sync_id': syncId, // Set sync_id dari tanggal_hidrasi
      'fk_id_pengguna': fkPenggunaId,
      'tanggal_hidrasi': syncId, // Pastikan konsisten
      'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
      'is_deleted': row['is_deleted'] ?? 0,
    };
    dataToInsert.remove('id');

    await db.insert(
      'target_hidrasi',
      dataToInsert,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    return await getTargetHidrasiByTanggal(fkPenggunaId, syncId) ?? dataToInsert;
  }

  Future<Map<String, dynamic>?> getTargetHidrasiByTanggal(int localPenggunaId, String tanggal) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'target_hidrasi',
      where: 'fk_id_pengguna = ? AND tanggal_hidrasi = ? AND is_deleted = 0',
      whereArgs: [localPenggunaId, tanggal],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> insertOrReplaceTargetFromFirestore(Map<String, dynamic> firestoreData, int fkPenggunaId) async {
    final db = await database;
    await db.insert(
      'target_hidrasi',
      {
        ...firestoreData, // Pastikan firestoreData memiliki 'sync_id' (yaitu tanggal_hidrasi)
        'fk_id_pengguna': fkPenggunaId,
        'is_synced': 1,
        'is_deleted': firestoreData['is_deleted'] ?? 0,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }


  // --- SINKRONISASI & UTILITAS UMUM ---
  Future<void> markAsSynced(String tableName, String syncId) async {
    final db = await database;
    await db.update(
      tableName,
      {'is_synced': 1},
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );
  }

  Future<void> markAsSyncedByLocalId(String tableName, int id) async {
    final db = await database;
    await db.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedData(String tableName) async {
    final db = await database;
    return await db.query(tableName, where: 'is_synced = 0');
  }

  Future<void> clearUserData(int localPenggunaId) async {
    final db = await database;
    await db.delete('riwayat_hidrasi', where: 'fk_id_pengguna = ?', whereArgs: [localPenggunaId]);
    await db.delete('target_hidrasi', where: 'fk_id_pengguna = ?', whereArgs: [localPenggunaId]);
    await db.delete('profil_pengguna', where: 'fk_id_pengguna = ?', whereArgs: [localPenggunaId]);
    // Pertimbangkan untuk tidak menghapus tabel 'pengguna' kecuali jika akun benar-benar dihapus
    // await db.delete('pengguna', where: 'id = ?', whereArgs: [localPenggunaId]);
    print("DatabaseHelper: Data lokal untuk pengguna $localPenggunaId dibersihkan (kecuali record pengguna utama).");
  }


  // --- METODE DENGAN TRANSAKSI (Untuk digunakan oleh PenggunaRepository) ---
  Future<Map<String, dynamic>> insertProfilPenggunaWithTxn(sql.Transaction txn, Map<String, dynamic> row, int fkPenggunaId) async {
    String syncId = _uuid.v4();
    Map<String, dynamic> dataToInsert = {
      ...row,
      'sync_id': syncId,
      'fk_id_pengguna': fkPenggunaId,
      'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
      'is_synced': 0,
      'is_deleted': 0,
    };
    int recordId = await txn.insert('profil_pengguna', dataToInsert, conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return {...dataToInsert, 'id': recordId};
  }

  Future<Map<String, dynamic>?> getPenggunaByFirebaseUidWithTxn(sql.Transaction txn, String firebaseUid) async {
    final List<Map<String, dynamic>> maps = await txn.query(
      'pengguna',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<Map<String, dynamic>?> getProfilPenggunaByLocalIdWithTxn(sql.Transaction txn, int localPenggunaId) async {
    final List<Map<String, dynamic>> maps = await txn.query(
      'profil_pengguna',
      where: 'fk_id_pengguna = ? AND is_deleted = 0',
      whereArgs: [localPenggunaId],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> markAsSyncedWithTxn(sql.Transaction txn, String tableName, String syncId) async {
    await txn.update(
      tableName,
      {'is_synced': 1},
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );
  }

  Future<void> markAsSyncedByLocalIdWithTxn(sql.Transaction txn, String tableName, int id) async {
    await txn.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}