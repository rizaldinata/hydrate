import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';

class EditProfile extends StatefulWidget {
  final String initialNama;
  final String initialJenisKelamin;
  final double initialBeratBadan;
  final String? initialJamBangun;
  final String? initialJamTidur;
  final int userId;

  const EditProfile({
    super.key,
    required this.initialNama,
    required this.initialJenisKelamin,
    required this.initialBeratBadan,
    this.initialJamBangun,
    this.initialJamTidur,
    required this.userId,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController nameController;
  late TextEditingController weightController;
  late String selectedGender;
  late TimeOfDay? wakeUpTime;
  late TimeOfDay? sleepTime;

  final ProfilPenggunaController _controller = ProfilPenggunaController();
  bool _isLoading = false;

  final Map<String, String> genderMap = {
    "Laki-laki": "Male",
    "Perempuan": "Female",
  };

  final Map<String, String> reverseGenderMap = {
    "Male": "Laki-laki",
    "Female": "Perempuan",
  };

  @override
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialNama);
    // weightController =
    //     TextEditingController(text: widget.initialBeratBadan.toString());

    // // Konversi "Male" / "Female" ke "Laki-laki" / "Perempuan"
    // selectedGender = reverseGenderMap[widget.initialJenisKelamin] ??
    //               (widget.initialJenisKelamin == "Male" ? "Laki-laki" : "Perempuan");
    // selectedGender = reverseGenderMap[widget.initialJenisKelamin] ??
    //               (widget.initialJenisKelamin == "Laki-laki" ? "Laki-laki" : "Perempuan");

    weightController =
        TextEditingController(text: widget.initialBeratBadan.toString());
    selectedGender = widget.initialJenisKelamin;

    // Parse jam bangun dan tidur jika tersedia
    wakeUpTime = _parseTimeString(widget.initialJamBangun);
    sleepTime = _parseTimeString(widget.initialJamTidur);
  }

  TimeOfDay? _parseTimeString(String? timeString) {
    if (timeString == null || timeString == 'Belum diatur') return null;

    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Belum diatur';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isWakeUpTime) async {
  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: isWakeUpTime
        ? wakeUpTime ?? TimeOfDay(hour: 6, minute: 0)
        : sleepTime ?? TimeOfDay(hour: 22, minute: 0),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData(
          primaryColor: const Color(0xFF00A6FB), // Warna utama biru
          hintColor: const Color(0xFF00A6FB),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF00A6FB), // Warna utama
            onPrimary: Colors.white, // Warna teks di atas warna utama
            onSurface: Color(0xFF2F2E41), // Warna teks utama
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected)
                    ? const Color(0xFF00A6FB)
                    : const Color(0xFFE8F7FF)),
            hourMinuteTextColor: MaterialStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected)
                    ? Colors.white
                    : const Color(0xFF2F2E41)),
            dialHandColor: const Color(0xFF00A6FB),
            dialBackgroundColor: const Color(0xFFE8F7FF),
            entryModeIconColor: const Color(0xFF00A6FB),
          ),
        ),
        child: child!,
      );
    },
  );

  if (pickedTime != null) {
    setState(() {
      if (isWakeUpTime) {
        wakeUpTime = pickedTime;
      } else {
        sleepTime = pickedTime;
      }
    });
  }
}


  void _saveProfile() async {
    // Validasi input
    if (nameController.text.isEmpty ||
        selectedGender.isEmpty ||
        weightController.text.isEmpty) {
      _showOverlayError("Harap isi semua data!");
      return;
    }

    final nama = nameController.text;
    final berat = double.tryParse(weightController.text) ?? 0.0;

    // final success = await _controller.updateProfilDanNama(
    //   userId: widget.userId,
    //   nama: nama,
    //   jenisKelamin: selectedGender,
    //   beratBadan: berat,
    // );

    if (berat <= 0) {
      _showOverlayError("Berat badan harus lebih dari 0 kg!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _controller.updateProfilPenggunaLengkap(
        userId: widget.userId,
        nama: nama,
        jenisKelamin: selectedGender,
        beratBadan: berat,
        jamBangun: _formatTimeOfDay(wakeUpTime),
        jamTidur: _formatTimeOfDay(sleepTime),
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        _showOverlaySuccess("Profil berhasil diperbarui!");
      } else if (mounted) {
        _showOverlayError("Gagal memperbarui profil!");
      }
    } catch (e) {
      if (mounted) {
        _showOverlayError("Terjadi kesalahan: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2E41),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nama
                    _buildTextField(nameController, "Nama", "assets/images/profile/profile.svg"),

                    const SizedBox(height: 15),

                    // Jenis Kelamin (Dropdown)
                    _buildDropdown(),

                    const SizedBox(height: 15),

                    // Berat Badan
                    _buildTextField(weightController, "Berat Badan (kg)",
                        "assets/images/profile/weight.svg",
                        isNumber: true),

                    const SizedBox(height: 15),

                    // Jam Bangun
                    _buildTimeSelector(
                      "Jam Bangun",
                      "assets/images/profile/waketime.svg",
                      wakeUpTime,
                      () => _selectTime(context, true),
                    ),

                    const SizedBox(height: 15),

                    // Jam Tidur
                    _buildTimeSelector(
                      "Jam Tidur",
                      "assets/images/profile/sleeptime.svg",
                      sleepTime,
                      () => _selectTime(context, false),
                    ),

                    const SizedBox(height: 20),

                    // Row untuk Tombol Batal & Simpan
                    Row(
                      children: [
                        Expanded(
                          child: _buildButton(
                            "Batal",
                            Colors.grey,
                            () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildButton(
                            "Simpan",
                            Color(0xFF00A6FB),
                            _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Widget untuk input text
  Widget _buildTextField(
      TextEditingController controller, String label, String icon,
      {bool isNumber = false}) {
    return TextField(
      cursorColor: const Color(0xFF00A6FB),
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF00A6FB)),
        prefixIcon: Padding(
          padding:
              const EdgeInsets.all(12.0), // Sesuaikan padding agar ikon pas
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Widget Dropdown untuk Jenis Kelamin
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value:
          selectedGender, // Pastikan nilainya dalam format "Laki-laki" atau "Perempuan"
      decoration: InputDecoration(
        labelText: "Jenis Kelamin",
        labelStyle: const TextStyle(color: Color(0xFF00A6FB)),
        prefixIcon: Padding(
            padding:
                const EdgeInsets.all(12.0), // Sesuaikan padding agar ikon pas
            child: SvgPicture.asset(
              "assets/images/profile/gender.svg",
              width: 24,
              height: 24,
            ),
          ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: genderMap.keys.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedGender = newValue!;
        });
        print("Jenis Kelamin Dipilih: $selectedGender");
      },
    );
  }

  // Widget untuk Pemilih Waktu
  Widget _buildTimeSelector(
      String label, String icon, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF00A6FB)),
          prefixIcon: Padding(
            padding:
                const EdgeInsets.all(12.0), // Sesuaikan padding agar ikon pas
            child: SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time == null
                ? 'Belum diatur'
                : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  // Widget untuk Tombol
  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

// Fungsi untuk menampilkan Overlay Error
  void _showOverlayError(String message) {
    _showOverlay(message, Colors.red);
  }

  // Fungsi untuk menampilkan Overlay Sukses
  void _showOverlaySuccess(String message) {
    _showOverlay(message, Colors.white.withOpacity(0.90));
  }

  // Fungsi umum untuk menampilkan overlay
  void _showOverlay(String message, Color color) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Overlay",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 50),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message,
                style: const TextStyle(
                    color: Color(0xFF2F2E41),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}



// class ProfileData {
//   static String? nama;
//   static double? beratBadan;
// }
// }
