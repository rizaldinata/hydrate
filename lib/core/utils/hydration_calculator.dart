import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import '../../presentation/controllers/pengguna_controller.dart';

class HydrationCalculator {
  final PenggunaController _penggunaController = PenggunaController();
  final ProfilPenggunaController _profilPenggunaController =
      ProfilPenggunaController();

  late String jenisKelamin;
  late double beratBadan;
  late int wakeUpTime;
  late int sleepTime;

  HydrationCalculator({
    required int penggunaId,
  }) {
    initializeData(penggunaId);
  }

  Future<void> initializeData(int penggunaId) async {
    try {

      Pengguna? penggunaData =
          await _penggunaController.getPenggunaById(penggunaId);

      ProfilPengguna? profilPenggunaData =
          await _profilPenggunaController.getProfilPengguna(penggunaId);

      if (penggunaData == null) {
        throw Exception("Pengguna tidak ditemukan");
      }
      jenisKelamin = profilPenggunaData?.jenisKelamin ?? 'Laki-laki';
      beratBadan = profilPenggunaData?.beratBadan ?? 70.0;
      
      String jamBangunStr = profilPenggunaData?.jamBangun ?? '';
      String jamTidurStr = profilPenggunaData?.jamTidur ?? '';
      
      wakeUpTime = _parseHour(jamBangunStr, 6); 
      sleepTime = _parseHour(jamTidurStr, 22);

      if (beratBadan <= 0) {
        beratBadan = 70.0; 
      }
    } catch (e) {
      jenisKelamin = 'Laki-laki';
      beratBadan = 70.0; 
      wakeUpTime = 6;
      sleepTime = 22;
    }
  }
  
  int _parseHour(String timeString, int defaultValue) {
    if (timeString == 'Belum diatur' || timeString.isEmpty) {
      return defaultValue;
    }
    
    try {
      if (timeString.contains(':')) {
        return int.parse(timeString.split(':')[0]);
      }
      return int.parse(timeString);
    } catch (e) {
      return defaultValue;
    }
  }

  double calculateDailyWaterIntake() {
    if (beratBadan <= 0) {
      beratBadan = 70.0; 
    }
    if (jenisKelamin == "Laki-laki") {
      return beratBadan * 35 / 1000; 
    } else {
      return beratBadan * 31 / 1000; 
    }
  }

  Map<String, double> calculateWaterDistribution() {
    double totalIntake = calculateDailyWaterIntake();
    int totalHours = sleepTime - wakeUpTime;
    if (totalHours <= 0) totalHours += 24;

    double hourlyIntake = totalIntake / totalHours;

    Map<String, double> schedule = {};
    for (int i = wakeUpTime; i < sleepTime; i++) {
      schedule["$i:00"] = hourlyIntake;
    }

    return schedule;
  }
}