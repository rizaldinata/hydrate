import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/main.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/services/notification_settings_service.dart'; 


class RegistrationTime extends StatefulWidget {
  final String name;
  final String gender;
  final double weight;

  const RegistrationTime({
    super.key,
    required this.name,
    required this.gender,
    required this.weight,
  });

  @override
  RegistrationTimeState createState() => RegistrationTimeState();
}

class RegistrationTimeState extends State<RegistrationTime> {
  final PenggunaController _penggunaController = PenggunaController();
  TextEditingController controllerWakeUpTime = TextEditingController();
  TextEditingController controllerSleepTime = TextEditingController();
  TextEditingController timeController = TextEditingController();
  bool isFinalFormFilled = false;

  final NotificationSettingsService _notificationSettingsService = NotificationSettingsService();

  @override
  void initState() {
    super.initState();

    controllerWakeUpTime.addListener(_checkForm);
    controllerSleepTime.addListener(_checkForm);
  }

  void _checkForm() {
    setState(() {
      isFinalFormFilled = controllerWakeUpTime.text.isNotEmpty &&
          controllerSleepTime.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    controllerWakeUpTime.removeListener(_checkForm);
    controllerSleepTime.removeListener(_checkForm);
    controllerWakeUpTime.dispose();
    controllerSleepTime.dispose();
    timeController.dispose();
    super.dispose();
  }

  // Alert dialog jika belum mengisi
  Future<void> _showWarningDialog() async {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Jangan bisa menutup modal dengan klik di luar
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: AnimatedScale(
            duration: Duration(milliseconds: 300),
            scale: 1.0,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: const Color(0XFFFFB830),
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Harap isi jam bangun dan jam tidur terlebih dahulu!",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F2E41),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0XFFFFB830), // Background color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Menutup modal
                      },
                      child: Text(
                        "Kembali",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo HYDRATE
                const SizedBox(height: 20),
                Text(
                  "HYDRATE",
                  style: GoogleFonts.gluten(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00A6FB),
                  ),
                ),

                // Slogan
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Text(
                    "Hidrasi Tepat, Hidup Sehat",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F2E41),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Gambar
                SvgPicture.asset(
                  'assets/images/registrasi2.svg',
                  width: 250,
                ),

                const SizedBox(height: 20),

                // Teks "DAFTAR"
                Text(
                  "DAFTAR",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                // Sub-judul
                Text(
                  "Isilah waktu yang sesuai sama kamu",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                const SizedBox(height: 20),

                TimePickerInput(
                    label: "Jam Bangun", controller: controllerWakeUpTime),
                const SizedBox(height: 20),
                TimePickerInput(
                    label: "Jam Tidur", controller: controllerSleepTime),

                // Tambahan dan gk keliatan biar layoutnya rapi
                Opacity(
                  opacity: 0.0,
                  child: IgnorePointer(
                    child: TimePickerInput(
                      label: "Gk Keliatan",
                      controller: timeController,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // Validasi apakah form sudah diisi

                // Tombol Lanjut
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isFinalFormFilled
                          ? const LinearGradient(
                              colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isFinalFormFilled
                          ? null
                          : Colors.grey[400], // warna abu-abu saat tidak aktif
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: isFinalFormFilled
                          ? () async {
                              String nama = widget.name;
                              String jenisKelamin = widget.gender;
                              double beratBadan = widget.weight;
                              String jamBangun = controllerWakeUpTime.text.trim();
                              String jamTidur = controllerSleepTime.text.trim();

                              if (nama.isEmpty ||
                                  jenisKelamin.isEmpty ||
                                  beratBadan <= 0 ||
                                  jamBangun.isEmpty ||
                                  jamTidur.isEmpty) {
                                _showWarningDialog();
                                return;
                              }

                              TimeOfDay? wakeUpForValidation = _parseTimeStringToTimeOfDay(jamBangun);
                              TimeOfDay? sleepForValidation = _parseTimeStringToTimeOfDay(jamTidur);

                              if (wakeUpForValidation != null && 
                                  sleepForValidation != null &&
                                  wakeUpForValidation.hour == sleepForValidation.hour &&
                                  wakeUpForValidation.minute == sleepForValidation.minute) {
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Jam bangun dan jam tidur tidak boleh sama persis!"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                                return; 
                              }

                              print("[RegistrationTime] Tombol DAFTAR ditekan. Data: Nama=$nama, Gender=$jenisKelamin, Berat=$beratBadan, Bangun=$jamBangun, Tidur=$jamTidur. Jam: ${DateTime.now()}");

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Center(child: CircularProgressIndicator());
                                },
                              );

                              try {
                                print("[RegistrationTime] Memanggil _penggunaController.tambahPengguna...");
                                int userId =
                                    await _penggunaController.tambahPengguna(
                                  nama,
                                  jenisKelamin,
                                  beratBadan,
                                  jamBangun,
                                  jamTidur,
                                );

                                print("[RegistrationTime] Hasil dari tambahPengguna, userId: $userId");

                                if (mounted) Navigator.of(context).pop();

                                if (userId > 0) {
                                  final session = SessionManager();
                                  print("[RegistrationTime] AKAN menyimpan UserId $userId ke session...");
                                  await session.saveUserId(userId);
                                  print("[RegistrationTime] UserId $userId SELESAI disimpan ke session.");

                                  TimeOfDay? wakeUpToSave = _parseTimeStringForService(jamBangun);
                                  TimeOfDay? sleepToSave = _parseTimeStringForService(jamTidur);

                                  if (wakeUpToSave != null) {
                                    await _notificationSettingsService.setWakeUpTime(wakeUpToSave);
                                    print("[RegistrationTime] Jam bangun ${wakeUpToSave.format(context)} disimpan ke settings service.");
                                  }
                                  if (sleepToSave != null) {
                                    await _notificationSettingsService.setSleepTime(sleepToSave);
                                    print("[RegistrationTime] Jam tidur ${sleepToSave.format(context)} disimpan ke settings service.");
                                  }
                                  
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MainScreen(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Gagal mendaftar. Coba lagi."))
                                    );
                                  }
                                }
                              } catch (e) {
                                Navigator.of(context).pop();
                                print("[RegistrationTime] Error saat menambahkan pengguna: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}"))
                                  );
                                }
                              }
                            }
                          : null,
                      child: Text(
                        "DAFTAR",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TimeOfDay? _parseTimeStringToTimeOfDay(String? timeString) {
  if (timeString == null || timeString.isEmpty) return null;
  try {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  } catch (e) {
    print("Error parsing time string for validation: '$timeString' - $e");
  }
  return null;
}

TimeOfDay? _parseTimeStringForService(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      print("Error parsing time string for service: '$timeString' - $e");
    }
    return null;
  }

class TimePickerInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const TimePickerInput({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  TimePickerInputState createState() => TimePickerInputState();
}

class TimePickerInputState extends State<TimePickerInput> {
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input, 
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: Color(0xFF00A6FB), // Warna utama biru
            hintColor: Color(0xFF00A6FB),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00A6FB), // Warna utama
              onPrimary: Colors.white, // Warna teks di atas warna utama
              onSurface: Color(0xFF2F2E41), // Warna teks utama
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Color(0xFF00A6FB)
                      : Color(0xFFE8F7FF)),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : Color(0xFF2F2E41)),
              dialHandColor: Color(0xFF00A6FB),
              dialBackgroundColor: Color(0xFFE8F7FF),
              entryModeIconColor: Color(0xFF00A6FB),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        widget.controller.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            readOnly: true,
            textAlign: TextAlign.left,
            style:
                TextStyle(fontSize: 16, color: Color(0xFF2F2E41)),
            onTap: () =>
                _selectTime(context),
            decoration: InputDecoration(
              hintText: widget.label,
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xFF00A6FB), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xFF00A6FB), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0xFF00A6FB),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/images/clock.svg',
              height: 24,
            ),
          ),
        ),
      ],
    );
  }
}
