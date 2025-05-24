import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
// Pastikan nama file FirestoreService.dart Anda konsisten (misal, firestore_service.dart)
// dan path importnya benar.
import 'package:hydrate/data/datasources/FirestoreService.dart'; // atau firestore_service.dart

class AppServices {
  static AppServices? _instance;
  static AppServices get instance {
    // Pastikan instance sudah diinisialisasi sebelum diakses
    // Ini penting jika ada yang mencoba mengakses sebelum `initialize()` selesai
    // Namun, dalam alur normal, `initialize()` di main.dart akan berjalan dulu.
    assert(_instance != null, 'AppServices must be initialized before accessing instance.');
    return _instance!;
  }


  // Service instances
  late FirebaseAuth firebaseAuth;
  late DatabaseHelper dbHelper;
  late FirestoreService firestoreService;
  late SharedPreferences sharedPreferences;
  late PenggunaRepository penggunaRepository;

  AppServices._(); // Private constructor

  static Future<void> initialize() async {
    if (_instance != null) {
      print("AppServices: Already initialized.");
      return;
    }

    print("AppServices: Initializing...");
    _instance = AppServices._();

    try {
      // Initialize SharedPreferences
      _instance!.sharedPreferences = await SharedPreferences.getInstance();
      print("AppServices: SharedPreferences initialized");

      // Initialize Firebase Auth
      _instance!.firebaseAuth = FirebaseAuth.instance;
      print("AppServices: FirebaseAuth initialized");

      // Initialize Database Helper
      _instance!.dbHelper = DatabaseHelper(); // Menggunakan singleton internal dari DatabaseHelper
      await _instance!.dbHelper.database; // Pastikan database terbuka
      print("AppServices: DatabaseHelper initialized and database opened");

      // Initialize Firestore Service
      // Jika FirestoreService Anda memerlukan 'auth', seperti pada desain kita:
      _instance!.firestoreService = FirestoreService(auth: _instance!.firebaseAuth);
      // Jika FirestoreService Anda TIDAK punya constructor dengan parameter 'auth':
      // _instance!.firestoreService = FirestoreService(); // Hapus baris di atas jika ini kasusnya
      print("AppServices: FirestoreService initialized");

      // Initialize PenggunaRepository with all dependencies
      _instance!.penggunaRepository = PenggunaRepository(
        auth: _instance!.firebaseAuth,
        dbHelper: _instance!.dbHelper,
        firestoreService: _instance!.firestoreService,
        prefs: _instance!.sharedPreferences,
      );
      print("AppServices: PenggunaRepository initialized");

      print("AppServices: All services initialized successfully");
    } catch (e, s) {
      print("AppServices: Error during initialization: $e");
      print("AppServices: Stacktrace: $s");
      // Pertimbangkan untuk me-rethrow error jika inisialisasi kritis gagal,
      // agar aplikasi tidak berjalan dalam state yang tidak valid.
      rethrow;
    }
  }

  // Opsional: metode dispose jika Anda perlu membersihkan resource
  static void dispose() {
    // Tambahkan logika dispose di sini jika ada service yang perlu di-dispose
    _instance = null;
    print("AppServices: Disposed");
  }
}