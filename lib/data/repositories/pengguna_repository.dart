import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:hydrate/data/repositories/auth/auth_repository.dart';
import 'package:hydrate/data/repositories/hydration/riwayat_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/hydration/target_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/profile/profile_repository.dart';
import 'package:hydrate/data/repositories/sync/sync_repository.dart';

/// Ini adalah kelas Facade.
/// Kelas ini mengimplementasikan SEMUA interface repositori,
/// menjadikannya pengganti yang sempurna untuk kelas lama.
/// Tugasnya hanya mendelegasikan panggilan ke repositori yang sesuai.
class PenggunaRepository implements
    AuthRepository,
    ProfileRepository,
    RiwayatHidrasiRepository,
    TargetHidrasiRepository,
    SyncRepository {
      
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final RiwayatHidrasiRepository _riwayatHidrasiRepository;
  final TargetHidrasiRepository _targetHidrasiRepository;
  final SyncRepository _syncRepository;

  PenggunaRepository({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required RiwayatHidrasiRepository riwayatHidrasiRepository,
    required TargetHidrasiRepository targetHidrasiRepository,
    required SyncRepository syncRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _riwayatHidrasiRepository = riwayatHidrasiRepository,
        _targetHidrasiRepository = targetHidrasiRepository,
        _syncRepository = syncRepository;

  // --- Delegasi ke AuthRepository ---
  @override
  fb_auth.User? get currentUser => _authRepository.currentUser;

  @override
  Stream<fb_auth.User?> get authStateChanges => _authRepository.authStateChanges;
  
  @override
  Future<bool> isPenggunaTerdaftarLokal() =>
      _authRepository.isPenggunaTerdaftarLokal();

  @override
  Future<fb_auth.User?> signInWithEmailPassword(String email, String password) =>
      _authRepository.signInWithEmailPassword(email, password);

  @override
  Future<bool> registerAndSetupUser({
    required String email,
    required String password,
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  }) =>
      _authRepository.registerAndSetupUser(
        email: email,
        password: password,
        namaPengguna: namaPengguna,
        dataProfil: dataProfil,
      );

  @override
  Future<void> signOut() => _authRepository.signOut();

  @override
  Future<bool> setupNewUserProfile({required String namaPengguna, required Map<String, dynamic> dataProfil}) =>
      _profileRepository.setupNewUserProfile(namaPengguna: namaPengguna, dataProfil: dataProfil);
  
  @override
  Future<int> tambahPenggunaDanProfilLokal(String nama, String jenisKelamin, double beratBadan, String jamBangun, String jamTidur) =>
      _profileRepository.tambahPenggunaDanProfilLokal(nama, jenisKelamin, beratBadan, jamBangun, jamTidur);

  @override
  Future<Map<String, dynamic>> setupNewLocalUser({required String firebaseUid, required String namaPengguna, required Map<String, dynamic> dataProfil}) =>
      _profileRepository.setupNewLocalUser(firebaseUid: firebaseUid, namaPengguna: namaPengguna, dataProfil: dataProfil);

  @override
  Future<Pengguna?> getPenggunaById(int id) =>
      _profileRepository.getPenggunaById(id);

  @override
  Future<Pengguna?> getLocalPenggunaByFirebaseUid(String firebaseUid) =>
      _profileRepository.getLocalPenggunaByFirebaseUid(firebaseUid);

  @override
  Future<Map<String, dynamic>?> getLocalUserProfile(int localPenggunaId) =>
      _profileRepository.getLocalUserProfile(localPenggunaId);

  @override
  Future<int> updateNama(int userId, String newNama) =>
      _profileRepository.updateNama(userId, newNama);

  @override
  Future<bool> updateLokalDanSinkronProfil({required String profilSyncId, required Map<String, dynamic> dataUpdateProfil}) =>
      _profileRepository.updateLokalDanSinkronProfil(profilSyncId: profilSyncId, dataUpdateProfil: dataUpdateProfil);

  // --- Delegasi ke RiwayatHidrasiRepository ---
  @override
  Future<Map<String, dynamic>?> addRiwayatHidrasi({required int localPenggunaId, required double jumlah, required String tanggal, required String waktu}) =>
      _riwayatHidrasiRepository.addRiwayatHidrasi(localPenggunaId: localPenggunaId, jumlah: jumlah, tanggal: tanggal, waktu: waktu);

  @override
  Future<bool> softDeleteRiwayatHidrasi(String riwayatSyncId) =>
      _riwayatHidrasiRepository.softDeleteRiwayatHidrasi(riwayatSyncId);

  @override
  Future<List<Map<String, dynamic>>> getAllLocalRiwayatHidrasi(int localPenggunaId) =>
      _riwayatHidrasiRepository.getAllLocalRiwayatHidrasi(localPenggunaId);

  // --- Delegasi ke TargetHidrasiRepository ---
  @override
  Future<Map<String, dynamic>?> saveOrUpdateTargetHidrasi({required int localPenggunaId, required String tanggal, required double target, double? totalHarian, double? persentase}) =>
      _targetHidrasiRepository.saveOrUpdateTargetHidrasi(localPenggunaId: localPenggunaId, tanggal: tanggal, target: target, totalHarian: totalHarian, persentase: persentase);
  
  @override
  Future<Map<String, dynamic>?> getLocalTargetHidrasi(int localPenggunaId, String tanggal) =>
      _targetHidrasiRepository.getLocalTargetHidrasi(localPenggunaId, tanggal);
  
  @override
  Future<Map<String, dynamic>?> getTargetHidrasiHarian(int userId, String tanggal) =>
      _targetHidrasiRepository.getTargetHidrasiHarian(userId, tanggal);
  
  @override
  Future<bool> checkTargetHidrasiExists(int userId, String tanggal) =>
      _targetHidrasiRepository.checkTargetHidrasiExists(userId, tanggal);

  @override
  Future<Map<String, dynamic>?> createTargetHidrasi(int userId, double targetValue, String tanggal, double initialTotalIntake) =>
      _targetHidrasiRepository.createTargetHidrasi(userId, targetValue, tanggal, initialTotalIntake);

  @override
  Future<void> updateTargetHidrasiValueIfDifferent(int userId, String tanggal, double newCalculatedTarget) =>
      _targetHidrasiRepository.updateTargetHidrasiValueIfDifferent(userId, tanggal, newCalculatedTarget);
      
  @override
  Future<Map<String, dynamic>?> updateTotalHidrasi(int userId, String tanggal, double newTotalIntake) =>
      _targetHidrasiRepository.updateTotalHidrasi(userId, tanggal, newTotalIntake);

  // --- Delegasi ke SyncRepository ---
  @override
  Future<bool> handleUserLoginInitialization(fb_auth.User firebaseUser) =>
      _syncRepository.handleUserLoginInitialization(firebaseUser);

  @override
  Future<void> syncOfflineData() => _syncRepository.syncOfflineData();
  
  @override
  Future<void> syncInitialRegistrationData({required String firebaseUid, required int localPenggunaId, required String profilSyncId}) =>
      _syncRepository.syncInitialRegistrationData(firebaseUid: firebaseUid, localPenggunaId: localPenggunaId, profilSyncId: profilSyncId);

  @override
  Future<List<Map<String, dynamic>>> getLocalRiwayatHidrasiByTanggal(int localPenggunaId, String tanggal) =>
      _riwayatHidrasiRepository.getLocalRiwayatHidrasiByTanggal(localPenggunaId, tanggal);
}