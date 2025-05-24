import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Field ini akan diinisialisasi oleh constructor
  final FirebaseAuth _auth;

  // Constructor yang menerima FirebaseAuth (WAJIB ADA)
  FirestoreService({required FirebaseAuth auth}) : _auth = auth;

  // Menggunakan _auth yang sudah di-inject untuk mendapatkan currentUser
  User? get currentUser => _auth.currentUser;

  // Helper untuk mendapatkan referensi dokumen pengguna saat ini
  DocumentReference? _getCurrentUserDocRef() {
    final user = currentUser; // Menggunakan getter currentUser di atas
    if (user == null) {
      print("FirestoreService: Pengguna tidak login.");
      return null;
    }
    return _db.collection('users').doc(user.uid);
  }
  Future<Map<String, dynamic>?> getUserMainProfileFromSubcollection() async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return null;

    try {
      final querySnapshot = await userDocRef
          .collection('profile_data') // Nama subkoleksi profil Anda
          .limit(1) // Asumsi hanya ada satu profil utama, ambil yang pertama
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['sync_id'] = doc.id; // Sertakan ID dokumen sebagai sync_id
        return data;
      } else {
        print("FirestoreService: Tidak ada dokumen profil ditemukan di subkoleksi 'profile_data'.");
        return null;
      }
    } catch (e) {
      print("FirestoreService: Error saat mengambil profil utama dari subkoleksi: $e");
      return null;
    }
  }

  // --- SINKRONISASI DATA PENGGUNA (BUKAN PROFIL) ---
  Future<void> savePenggunaInfo(Map<String, dynamic> penggunaData) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return;

    // Contoh: memastikan dokumen user ada dan mencatat lastSeen
    // Anda bisa menyesuaikan 'penggunaData' sesuai kebutuhan
    await userDocRef.set(
      {...penggunaData, 'lastSeen': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    print("FirestoreService: Info pengguna disimpan/diperbarui.");
  }

  // --- PROFIL PENGGUNA ---
  Future<void> saveProfilPengguna(Map<String, dynamic> profilData, String syncId) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return;

    // Menyimpan profil di subkoleksi 'profile_data' dengan syncId sebagai ID dokumen
    await userDocRef.collection('profile_data').doc(syncId).set(profilData, SetOptions(merge: true));
    print("FirestoreService: Profil pengguna disimpan ke Firestore (syncId: $syncId).");
  }

  Future<Map<String, dynamic>?> getProfilPengguna(String syncId) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return null;

    final docSnap = await userDocRef.collection('profile_data').doc(syncId).get();
    if (docSnap.exists) {
      return docSnap.data();
    }
    print("FirestoreService: Profil dengan syncId $syncId tidak ditemukan.");
    return null;
  }

  // --- RIWAYAT HIDRASI ---
  Future<void> saveRiwayatHidrasiItem(Map<String, dynamic> riwayatItemData, String syncId) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return;

    final Map<String, dynamic> dataToSave = Map.from(riwayatItemData);
    dataToSave.remove('id'); // Hapus ID lokal SQLite jika ada
    dataToSave.remove('fk_id_pengguna'); // Hapus foreign key lokal jika ada
    dataToSave.remove('is_synced'); // Status sinkronisasi lokal tidak perlu disimpan di Firestore

    await userDocRef.collection('riwayat_hidrasi').doc(syncId).set(dataToSave, SetOptions(merge: true));
    print("FirestoreService: Riwayat hidrasi disimpan (syncId: $syncId).");
  }

  Future<void> softDeleteRiwayatHidrasiItem(String syncId) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return;

    await userDocRef.collection('riwayat_hidrasi').doc(syncId).update({
      'is_deleted': true,
      'last_modified_locally': FieldValue.serverTimestamp(), // Gunakan server timestamp untuk konsistensi
    });
    print("FirestoreService: Riwayat hidrasi di-soft-delete (syncId: $syncId).");
  }

  Future<List<Map<String, dynamic>>> getAllRiwayatHidrasi() async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return [];

    final querySnapshot = await userDocRef.collection('riwayat_hidrasi').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['sync_id'] = doc.id; // Tambahkan ID dokumen Firestore sebagai sync_id
      return data;
    }).toList();
  }

  // --- TARGET HIDRASI ---
  Future<void> saveTargetHidrasi(Map<String, dynamic> targetData, String tanggalYYYYMMDDAsDocId) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return;

    final Map<String, dynamic> dataToSave = Map.from(targetData);
    dataToSave.remove('id');
    dataToSave.remove('fk_id_pengguna');
    dataToSave.remove('is_synced');
    // 'sync_id' dari SQLite bisa jadi adalah 'tanggalYYYYMMDDAsDocId' ini, atau field terpisah.
    // Jika 'sync_id' dari SQLite berbeda dengan 'tanggalYYYYMMDDAsDocId', pastikan dataToSave['sync_id'] di-set.

    await userDocRef.collection('target_hidrasi').doc(tanggalYYYYMMDDAsDocId).set(dataToSave, SetOptions(merge: true));
    print("FirestoreService: Target hidrasi disimpan (ID Dokumen/Tanggal: $tanggalYYYYMMDDAsDocId).");
  }

  Future<List<Map<String, dynamic>>> getAllTargetHidrasi() async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null) return [];

    final querySnapshot = await userDocRef.collection('target_hidrasi').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      // ID dokumen adalah tanggal (YYYY-MM-DD), yang juga merupakan sync_id atau kunci uniknya
      data['sync_id'] = doc.id;
      data['tanggal_hidrasi'] = doc.id; // Pastikan field ini ada atau sesuai
      return data;
    }).toList();
  }

  // --- SINKRONISASI BATCH ---
  Future<void> syncBatchToFirestore(
      String collectionName, List<Map<String, dynamic>> itemsToSync) async {
    final userDocRef = _getCurrentUserDocRef();
    if (userDocRef == null || itemsToSync.isEmpty) {
      if (itemsToSync.isEmpty) print("FirestoreService: Tidak ada item untuk di-batch sync ke $collectionName.");
      return;
    }

    final WriteBatch batch = _db.batch();
    final CollectionReference collectionRef = userDocRef.collection(collectionName);

    for (final item in itemsToSync) {
      // Pastikan 'sync_id' ada di dalam map 'item' dan bukan null
      final String? syncId = item['sync_id'] as String?;
      if (syncId == null || syncId.isEmpty) {
        print("FirestoreService: Peringatan - item tanpa sync_id valid dilewati dalam batch: $item");
        continue; // Lewati item ini jika sync_id tidak valid
      }
      final DocumentReference docRef = collectionRef.doc(syncId);

      final Map<String, dynamic> dataToSave = Map.from(item);
      dataToSave.remove('id');
      dataToSave.remove('fk_id_pengguna');
      dataToSave.remove('is_synced');
      // Anda mungkin ingin menambahkan atau memperbarui timestamp server di sini
      // dataToSave['firestore_last_updated'] = FieldValue.serverTimestamp();

      if (item['is_deleted'] == 1 || item['is_deleted'] == true) {
        // Konsisten dengan soft delete: set is_deleted true dan timestamp
        batch.set(docRef, {...dataToSave, 'is_deleted': true, 'last_modified_locally': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } else {
        // Jika tidak di-soft-delete, hapus field is_deleted agar tidak ambigu,
        // atau pastikan nilainya false jika field tersebut selalu ada di Firestore.
        dataToSave.remove('is_deleted'); // Atau dataToSave['is_deleted'] = false;
        batch.set(docRef, dataToSave, SetOptions(merge: true));
      }
    }

    try {
      await batch.commit();
      print("FirestoreService: Batch sync untuk '$collectionName' (${itemsToSync.length} items) berhasil.");
    } catch (e) {
      print("FirestoreService: Error saat batch sync untuk '$collectionName': $e");
      rethrow; // Biarkan error ini ditangani oleh pemanggil jika perlu
    }
  }
}