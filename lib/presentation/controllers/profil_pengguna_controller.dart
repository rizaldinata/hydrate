import 'package:flutter/foundation.dart'; 
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/locator.dart';


class ProfilPenggunaController with ChangeNotifier {
  final PenggunaRepository _penggunaRepository = locator<PenggunaRepository>();
  final SessionManager _sessionManager = locator<SessionManager>();

  // State Variables
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _idPengguna;
  String? _namaPengguna;
  String? _jenisKelamin;
  double? _beratBadan;
  String? _jamBangun;
  String? _jamTidur;

  // Getters untuk UI
  int? get idPengguna => _idPengguna;
  String? get namaPengguna => _namaPengguna;
  String? get jenisKelamin => _jenisKelamin;
  double? get beratBadan => _beratBadan;
  String? get jamBangun => _jamBangun;
  String? get jamTidur => _jamTidur;

  // Metode untuk memuat data profil pengguna
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); 

    try {
      _idPengguna = await _sessionManager.getUserId();
      if (_idPengguna == null) {
        _errorMessage = "Sesi pengguna tidak ditemukan. Silakan login ulang.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final penggunaDataMap = await _penggunaRepository.getPenggunaById(_idPengguna!);
      if (penggunaDataMap != null) {
        _namaPengguna = penggunaDataMap.nama;
      } else {
         _namaPengguna = "Pengguna"; 
      }
      
      final profilDataMap = await _penggunaRepository.getLocalUserProfile(_idPengguna!);
      if (profilDataMap != null) {
        _jenisKelamin = profilDataMap['jenis_kelamin'] as String?;
        _beratBadan = (profilDataMap['berat_badan'] as num?)?.toDouble();
        _jamBangun = profilDataMap['jam_bangun'] as String?;
        _jamTidur = profilDataMap['jam_tidur'] as String?;
      } else {
        // Set nilai default jika profil tidak ditemukan
        _jenisKelamin = "Laki-laki";
        _beratBadan = 60.0;
        _jamBangun = "06:00";
        _jamTidur = "22:00";
         print("ProfilPenggunaController: Detail profil tidak ditemukan untuk userId: $_idPengguna, menggunakan default.");
      }

    } catch (e) {
      _errorMessage = "Gagal memuat data profil: ${e.toString()}";
      print("ProfilPenggunaController: Error loading user profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Metode untuk mengupdate profil lengkap
  Future<bool> updateUserProfile({
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
    required String jamBangun,
    required String jamTidur,
  }) async {
    if (_idPengguna == null) {
      _errorMessage = "Tidak bisa update, ID Pengguna tidak ditemukan.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update nama di tabel pengguna (jika berbeda)
      if (_namaPengguna != nama) {
         await _penggunaRepository.updateNama(_idPengguna!, nama);
      }
      
      // Dapatkan sync_id profil yang ada untuk update
      final existingProfile = await _penggunaRepository.getLocalUserProfile(_idPengguna!);
      if (existingProfile == null || existingProfile['sync_id'] == null) {
        throw Exception("Profil pengguna tidak ditemukan untuk update atau sync_id hilang.");
      }
      String profilSyncId = existingProfile['sync_id'] as String;

      Map<String, dynamic> dataUpdateProfil = {
        'jenis_kelamin': jenisKelamin,
        'berat_badan': beratBadan,
        'jam_bangun': jamBangun,
        'jam_tidur': jamTidur,
      };

      bool isSuccess = await _penggunaRepository.updateLokalDanSinkronProfil(
        profilSyncId: profilSyncId,
        dataUpdateProfil: dataUpdateProfil,
      );

      if (isSuccess) {
        await loadUserProfile(); 
        return true;
      } else {
        _errorMessage = "Gagal mengupdate profil.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Error saat mengupdate profil: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}