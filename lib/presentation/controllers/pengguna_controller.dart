// File: lib/presentation/controllers/pengguna_controller.dart

import 'package:hydrate/data/models/pengguna_model.dart'; // Hanya jika getPenggunaByLocalId mengembalikan model ini
import 'package:hydrate/services/app_services.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';

class PenggunaController {
  // Mengambil instance PenggunaRepository yang sudah diinisialisasi dari AppServices
  final PenggunaRepository _repository = AppServices.instance.penggunaRepository;

  /// Metode utama untuk proses registrasi lengkap (Firebase Auth + SQLite + Firestore)
  /// yang dipanggil dari UI screen registrasi.
  Future<bool> prosesRegistrasiLengkap({
      required String email,
      required String password,
      required String nama,
      required String jenisKelamin,
      required double beratBadan,
      required String jamBangun,
      required String jamTidur,
  }) async {
    print("PenggunaController: Memulai prosesRegistrasiLengkap untuk email: $email");
    
    try {
      // Data profil yang akan disimpan
      Map<String, dynamic> dataProfilMap = {
        'jenis_kelamin': jenisKelamin,
        'berat_badan': beratBadan,
        'jam_bangun': jamBangun,
        'jam_tidur': jamTidur,
        // 'email_kontak': email, // Menyimpan email di data profil juga
      };

      // Gunakan password default jika tidak diberikan
      String passwordToUse = password ?? _generateDefaultPassword(email);

      // Panggil method di repository untuk registrasi lengkap
      bool berhasil = await _repository.registerAndSetupUser(
        email: email,
        password: passwordToUse,
        namaPengguna: nama,
        dataProfil: dataProfilMap,
      );

      if (berhasil) {
        print("PenggunaController: Proses registrasi lengkap berhasil!");
        return true;
      } else {
        print("PenggunaController: Proses registrasi lengkap gagal dari repository.");
        return false;
      }
    } catch (e, s) {
      print("PenggunaController: Error saat prosesRegistrasiLengkap: $e");
      print("Stacktrace Controller: $s");
      return false;
    }
  }

  /// Metode untuk menyelesaikan setup profil pengguna SETELAH akun Firebase Auth dibuat
  /// dan pengguna sudah login.
  /// Metode ini akan menyimpan data profil ke SQLite dan menyinkronkannya ke Firestore.
  Future<bool> finalisasiSetupProfilPengguna({
    required String namaPengguna,     // Nama yang akan disimpan di tabel 'pengguna' SQLite & mungkin profil
    required String emailUntukProfil, // Email yang akan disimpan di data profil (bisa sama dengan auth email)
    required String jenisKelamin,
    required double beratBadan,
    required String jamBangun,
    required String jamTidur,
  }) async {
    print("PenggunaController: Memulai finalisasiSetupProfilPengguna untuk: $namaPengguna, email profil: $emailUntukProfil");
    try {
      // Data profil yang akan disimpan ke tabel 'profil_pengguna'
      Map<String, dynamic> dataProfilMap = {
        'jenis_kelamin': jenisKelamin,
        'berat_badan': beratBadan,
        'jam_bangun': jamBangun,
        'jam_tidur': jamTidur,
        // Jika Anda ingin menyimpan email di dalam dokumen profil di Firestore/SQLite juga:
        'email_kontak': emailUntukProfil, // Atau nama field lain yang sesuai
        // Kolom seperti sync_id, fk_id_pengguna, is_synced, is_deleted, last_modified_locally
        // akan diurus oleh DatabaseHelper dan PenggunaRepository saat menyimpan.
      };

      // Panggil metode di repository yang menangani penyimpanan profil untuk pengguna yang sudah ada/login.
      // Metode `setupNewUserProfile` di repository akan menggunakan `_auth.currentUser` untuk mendapatkan UID.
      bool berhasil = await _repository.setupNewUserProfile(
        namaPengguna: namaPengguna, // Nama untuk tabel 'pengguna' di SQLite
        dataProfil: dataProfilMap,  // Data untuk tabel 'profil_pengguna' di SQLite
      );

      if (berhasil) {
        print("PenggunaController: Finalisasi setup profil pengguna berhasil.");
        return true;
      } else {
        print("PenggunaController: Finalisasi setup profil pengguna gagal dari repository.");
        return false;
      }
    } catch (e, s) {
      print("PenggunaController: Error saat finalisasiSetupProfilPengguna: $e");
      print("Stacktrace Controller: $s");
      return false;
    }
  }

  /// Metode untuk login pengguna dengan email dan password
  Future<bool> loginPengguna({
    required String email,
    required String password,
  }) async {
    print("PenggunaController: Memulai proses login untuk email: $email");
    
    try {
      var firebaseUser = await _repository.signInWithEmailPassword(email, password);
      
      if (firebaseUser != null) {
        print("PenggunaController: Login Firebase berhasil, UID: ${firebaseUser.uid}");
        
        // Inisialisasi data pengguna setelah login
        bool initBerhasil = await _repository.handleUserLoginInitialization(firebaseUser);
        
        if (initBerhasil) {
          print("PenggunaController: Inisialisasi setelah login berhasil.");
          return true;
        } else {
          print("PenggunaController: Inisialisasi setelah login gagal.");
          // Tetap return true karena login Firebase berhasil, data bisa di-sync nanti
          return true;
        }
      } else {
        print("PenggunaController: Login Firebase gagal, user null.");
        return false;
      }
    } catch (e, s) {
      print("PenggunaController: Error saat login: $e");
      print("Stacktrace: $s");
      return false;
    }
  }

  /// Metode untuk logout pengguna
  Future<bool> logoutPengguna() async {
    print("PenggunaController: Memulai proses logout.");
    
    try {
      await _repository.signOut();
      print("PenggunaController: Logout berhasil.");
      return true;
    } catch (e, s) {
      print("PenggunaController: Error saat logout: $e");
      print("Stacktrace: $s");
      return false;
    }
  }

  /// Mengambil data pengguna dari SQLite lokal berdasarkan ID lokal SQLite.
  /// Perhatikan bahwa ini menggunakan ID lokal, bukan firebase_uid.
  Future<Pengguna?> getPenggunaByLocalId(int id) async {
    print("PenggunaController: Mengambil pengguna dengan ID lokal SQLite: $id");
    return await _repository.getPenggunaById(id); // Menggunakan metode getPenggunaById yang ada di repo Anda
  }

  /// Mengambil data pengguna yang sedang login dari SQLite berdasarkan firebase_uid.
  Future<Pengguna?> getPenggunaSaatIniDariLokal() async {
    final currentUserUid = AppServices.instance.firebaseAuth.currentUser?.uid;
    if (currentUserUid == null) {
      print("PenggunaController: Tidak ada pengguna yang login untuk diambil datanya.");
      return null;
    }
    print("PenggunaController: Mengambil pengguna saat ini dari lokal dengan UID Firebase: $currentUserUid");
    return await _repository.getLocalPenggunaByFirebaseUid(currentUserUid);
  }

  /// Mengambil profil pengguna yang sedang login
  Future<Map<String, dynamic>?> getProfilPenggunaSaatIni() async {
    try {
      final pengguna = await getPenggunaSaatIniDariLokal();
      if (pengguna != null) {
        return await _repository.getLocalUserProfile(pengguna.id!);
      }
      return null;
    } catch (e) {
      print("PenggunaController: Error saat mengambil profil pengguna saat ini: $e");
      return null;
    }
  }

  /// Mengupdate nama pengguna
  Future<bool> updateNamaPengguna(String namaBaru) async {
    try {
      final pengguna = await getPenggunaSaatIniDariLokal();
      if (pengguna?.id != null) {
        int result = await _repository.updateNama(pengguna!.id!, namaBaru);
        return result > 0;
      }
      return false;
    } catch (e) {
      print("PenggunaController: Error saat update nama: $e");
      return false;
    }
  }

  /// Mengupdate profil pengguna
  Future<bool> updateProfilPengguna({
    required String jenisKelamin,
    required double beratBadan,
    required String jamBangun,
    required String jamTidur,
  }) async {
    try {
      final pengguna = await getPenggunaSaatIniDariLokal();
      final profil = await getProfilPenggunaSaatIni();
      
      if (pengguna?.id != null && profil?['sync_id'] != null) {
        Map<String, dynamic> dataUpdate = {
          'jenis_kelamin': jenisKelamin,
          'berat_badan': beratBadan,
          'jam_bangun': jamBangun,
          'jam_tidur': jamTidur,
        };
        
        return await _repository.updateLokalDanSinkronProfil(
          localPenggunaId: pengguna!.id!,
          profilSyncId: profil!['sync_id'],
          dataUpdateProfil: dataUpdate,
        );
      }
      return false;
    } catch (e) {
      print("PenggunaController: Error saat update profil: $e");
      return false;
    }
  }

  /// Mengecek apakah pengguna sudah terdaftar (ada data di SQLite)
  Future<bool> isPenggunaTerdaftar() async {
    return await _repository.isPenggunaTerdaftar();
  }

  /// Helper method untuk generate password default
  String _generateDefaultPassword(String email) {
    // Buat password default dari bagian pertama email + suffix
    String emailPrefix = email.split('@')[0];
    return "${emailPrefix}123!"; // Contoh: user@email.com -> user123!
  }

  // Metode `tambahPengguna` yang lama sudah di-comment karena tidak digunakan untuk registrasi Firebase
  // Jika diperlukan untuk keperluan lokal saja, bisa di-uncomment dan dimodifikasi sesuai kebutuhan
  /*
  Future<int> tambahPenggunaLokalSaja(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    print("PenggunaController: Memanggil _repository.tambahPenggunaDanProfil (UNTUK DATA LOKAL SAJA)");
    return await _repository.tambahPenggunaDanProfil(
        nama, jenisKelamin, beratBadan, jamBangun, jamTidur);
  }
  */
}