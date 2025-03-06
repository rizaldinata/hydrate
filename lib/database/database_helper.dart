import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../models/hydration_target_model.dart';
import '../models/hydration_log_model.dart';

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
    final path = join(await getDatabasesPath(), 'hydration.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE user_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            gender TEXT NOT NULL,
            weight REAL NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE hydration_targets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            target REAL NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE hydration_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    int result = await db.insert('users', user.toMap());
    print("User berhasil ditambahkan dengan ID: $result");
    return result;
  }

  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profiles', profile.toMap());
  }

  Future<int> insertHydrationTarget(HydrationTarget target) async {
    final db = await database;
    return await db.insert('hydration_targets', target.toMap());
  }

  Future<int> insertHydrationLog(HydrationLog log) async {
    final db = await database;
    return await db.insert('hydration_logs', log.toMap());
  }

  Future<List<HydrationLog>> getHydrationLogs(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'hydration_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => HydrationLog.fromMap(map)).toList();
  }
}
