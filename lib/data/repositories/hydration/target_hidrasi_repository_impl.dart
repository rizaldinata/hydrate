import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:hydrate/data/repositories/hydration/target_hidrasi_repository.dart';

class TargetHidrasiRepositoryImpl implements TargetHidrasiRepository {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;

  TargetHidrasiRepositoryImpl({
    required DatabaseHelper dbHelper,
    required FirestoreService firestoreService,
  })  : _dbHelper = dbHelper,
        _firestoreService = firestoreService;

  @override
  Future<Map<String, dynamic>?> saveOrUpdateTargetHidrasi({
    required int localPenggunaId,
    required String tanggal,
    required double target,
    double? totalHarian,
    double? persentase,
  }) async {
    try {
      Map<String, dynamic> dataTarget = {
        'sync_id': tanggal, // Untuk target, sync_id adalah tanggal itu sendiri
        'target_hidrasi': target,
        'tanggal_hidrasi': tanggal,
        'total_hidrasi_harian': totalHarian ?? 0.0,
        'persentase_hidrasi': persentase ?? 0.0,
      };
      Map<String, dynamic> targetDisimpan = await _dbHelper.insertOrReplaceTargetHidrasi(dataTarget, localPenggunaId);

      // Langsung sinkronkan ke Firestore
      await _firestoreService.saveTargetHidrasi(targetDisimpan, tanggal);
      await _dbHelper.markAsSynced('target_hidrasi', tanggal);

      print("TargetHidrasiRepository: Target disimpan/diupdate dan disinkronkan untuk tanggal $tanggal");
      return targetDisimpan;
    } catch (e) {
      print("TargetHidrasiRepository: Error saat menyimpan target hidrasi: $e");
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getLocalTargetHidrasi(int localPenggunaId, String tanggal) async {
    return await _dbHelper.getTargetHidrasiByTanggal(localPenggunaId, tanggal);
  }
  
  @override
  Future<Map<String, dynamic>?> getTargetHidrasiHarian(int userId, String tanggal) async {
    return await getLocalTargetHidrasi(userId, tanggal);
  }

  @override
  Future<bool> checkTargetHidrasiExists(int userId, String tanggal) async {
    final target = await getLocalTargetHidrasi(userId, tanggal);
    return target != null;
  }

  @override
  Future<Map<String, dynamic>?> createTargetHidrasi(
    int userId, 
    double targetValue, 
    String tanggal, 
    double initialTotalIntake,
  ) async {
    double initialPercentage = (targetValue > 0) ? (initialTotalIntake / targetValue) * 100 : 0.0;
    
    return await saveOrUpdateTargetHidrasi(
      localPenggunaId: userId,
      tanggal: tanggal,
      target: targetValue,
      totalHarian: initialTotalIntake,
      persentase: initialPercentage.clamp(0, 100),
    );
  }

  @override
  Future<void> updateTargetHidrasiValueIfDifferent(
    int userId, 
    String tanggal, 
    double newCalculatedTarget,
  ) async {
    try {
      final existingTargetData = await getLocalTargetHidrasi(userId, tanggal);
      if (existingTargetData != null) {
        double currentDbTarget = (existingTargetData['target_hidrasi'] as num?)?.toDouble() ?? 0.0;
        if (currentDbTarget.toStringAsFixed(2) != newCalculatedTarget.toStringAsFixed(2)) { 
          double currentTotalHarian = (existingTargetData['total_hidrasi_harian'] as num?)?.toDouble() ?? 0.0;
          double newPercentage = (newCalculatedTarget > 0) ? (currentTotalHarian / newCalculatedTarget) * 100 : 0.0;
          await saveOrUpdateTargetHidrasi(
            localPenggunaId: userId,
            tanggal: tanggal,
            target: newCalculatedTarget,
            totalHarian: currentTotalHarian, 
            persentase: newPercentage.clamp(0,100),
          );
        }
      } else {
        await createTargetHidrasi(userId, newCalculatedTarget, tanggal, 0.0);
      } 
    } catch (e) {
      print("TargetHidrasiRepository: Error saat update target hidrasi: $e");
    }
  }
  
  @override
  Future<Map<String, dynamic>?> updateTotalHidrasi(
    int userId, 
    String tanggal, 
    double newTotalIntake,
  ) async {
    try {
      final targetData = await getLocalTargetHidrasi(userId, tanggal);
      if (targetData == null) {
        // Jika target belum ada, buat target default baru dengan total intake saat ini
        double defaultTargetIfNotExist = 2000.0; 
        return await createTargetHidrasi(userId, defaultTargetIfNotExist, tanggal, newTotalIntake);
      }

      double currentTarget = (targetData['target_hidrasi'] as num?)?.toDouble() ?? 0.0;
      double newPercentage = (currentTarget > 0) ? (newTotalIntake / currentTarget) * 100 : 0.0;

      return await saveOrUpdateTargetHidrasi(
        localPenggunaId: userId,
        tanggal: tanggal,
        target: currentTarget,
        totalHarian: newTotalIntake,
        persentase: newPercentage.clamp(0,100),
      );
    } catch (e) {
      print("TargetHidrasiRepository: Error updating total hidrasi: $e");
      return null;
    }
  }
}