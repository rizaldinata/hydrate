import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:hydrate/data/repositories/auth/auth_repository.dart';
import 'package:hydrate/data/repositories/auth/auth_repository_impl.dart';
import 'package:hydrate/data/repositories/hydration/riwayat_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/hydration/riwayat_hidrasi_repository_impl.dart';
import 'package:hydrate/data/repositories/hydration/target_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/hydration/target_hidrasi_repository_impl.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/data/repositories/profile/profile_repository.dart';
import 'package:hydrate/data/repositories/profile/profile_repository_impl.dart';
import 'package:hydrate/data/repositories/sync/sync_repository.dart';
import 'package:hydrate/data/repositories/sync/sync_repository_impl.dart';


final locator = GetIt.instance;

Future<void> setupLocator() async {
  // 1. Daftarkan Dependensi Eksternal & Inti (Core Services)
  // Ini adalah objek-objek dasar yang dibutuhkan oleh repositori
  locator.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);
  
  // Daftarkan sebagai Lazy Singleton agar database tidak langsung dibuat
  locator.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  locator.registerLazySingleton<FirestoreService>(() => FirestoreService(auth: locator<FirebaseAuth>()));

  // 2. Daftarkan Implementasi Repositori
  // Perhatikan urutan pendaftaran jika ada dependensi antar repositori
  
  // Repositori yang tidak bergantung pada repo lain
  locator.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(
        dbHelper: locator<DatabaseHelper>(),
        firestoreService: locator<FirestoreService>(),
        auth: locator<FirebaseAuth>(),
      ));
  
  locator.registerLazySingleton<RiwayatHidrasiRepository>(() => RiwayatHidrasiRepositoryImpl(
        dbHelper: locator<DatabaseHelper>(),
        firestoreService: locator<FirestoreService>(),
      ));

  locator.registerLazySingleton<TargetHidrasiRepository>(() => TargetHidrasiRepositoryImpl(
        dbHelper: locator<DatabaseHelper>(),
        firestoreService: locator<FirestoreService>(),
      ));

  // Repositori yang bergantung pada repo lain
  locator.registerLazySingleton<SyncRepository>(() => SyncRepositoryImpl(
        dbHelper: locator<DatabaseHelper>(),
        firestoreService: locator<FirestoreService>(),
        prefs: locator<SharedPreferences>(),
        auth: locator<FirebaseAuth>(),
      ));

  // AuthRepository membutuhkan ProfileRepository dan SyncRepository
  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        auth: locator<FirebaseAuth>(),
        dbHelper: locator<DatabaseHelper>(),
        prefs: locator<SharedPreferences>(),
        profileRepository: locator<ProfileRepository>(), // <-- Injeksi
        syncRepository: locator<SyncRepository>(),       // <-- Injeksi
      ));

  // 3. Daftarkan Facade Utama
  // Ini adalah kelas yang akan paling sering Anda gunakan di UI/BLoC
  locator.registerLazySingleton<PenggunaRepository>(() => PenggunaRepository(
        authRepository: locator<AuthRepository>(),
        profileRepository: locator<ProfileRepository>(),
        riwayatHidrasiRepository: locator<RiwayatHidrasiRepository>(),
        targetHidrasiRepository: locator<TargetHidrasiRepository>(),
        syncRepository: locator<SyncRepository>(),
      ));
}