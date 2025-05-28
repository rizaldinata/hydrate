import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import 'package:flutter/services.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart'; // Pastikan import ini ada

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
  late TargetHidrasiController _targetHidrasiController; // Deklarasi
  bool _isLoading = false;

  final Map<String, String> genderMap = {
    "Laki-laki": "Male",
    "Perempuan": "Female",
  };

  // Tidak perlu reverseGenderMap jika selectedGender sudah dalam format "Laki-laki" / "Perempuan"
  // final Map<String, String> reverseGenderMap = {
  //   "Male": "Laki-laki",
  //   "Female": "Perempuan",
  // };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialNama);
    weightController =
        TextEditingController(text: widget.initialBeratBadan.toInt().toString());

    // Pastikan initialJenisKelamin adalah "Laki-laki" atau "Perempuan"
    // Jika dari database adalah "Male" atau "Female", perlu dikonversi di sini
    if (widget.initialJenisKelamin == "Male") {
      selectedGender = "Laki-laki";
    } else if (widget.initialJenisKelamin == "Female") {
      selectedGender = "Perempuan";
    } else {
      selectedGender = widget.initialJenisKelamin; // Asumsikan sudah format yang benar
    }

    wakeUpTime = _parseTimeString(widget.initialJamBangun);
    sleepTime = _parseTimeString(widget.initialJamTidur);

    // Inisialisasi TargetHidrasiController
    _targetHidrasiController = TargetHidrasiController();
  }

  TimeOfDay? _parseTimeString(String? timeString) {
    if (timeString == null || timeString == 'Belum diatur' || timeString.isEmpty) return null;

    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      print('Error parsing time: $e for string: $timeString');
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
          ? wakeUpTime ?? const TimeOfDay(hour: 6, minute: 0)
          : sleepTime ?? const TimeOfDay(hour: 22, minute: 0),
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

    if (berat <= 0) {
      _showOverlayError("Berat badan harus lebih dari 0 kg!");
      return;
    }
    if (berat > 300) { // Batasan berat badan
        _showOverlayError("Berat badan tidak boleh lebih dari 300 kg. Silakan masukkan berat yang sesuai.");
        return;
    }


    setState(() {
      _isLoading = true;
    });

    try {
      // Pastikan selectedGender dikirim sebagai "Male" atau "Female" jika itu yang diharapkan controller
      String genderForController = genderMap[selectedGender] ?? selectedGender;

      final success = await _controller.updateProfilPenggunaLengkap(
        userId: widget.userId,
        nama: nama,
        jenisKelamin: genderForController, // Menggunakan genderMap untuk konversi
        beratBadan: berat,
        jamBangun: _formatTimeOfDay(wakeUpTime),
        jamTidur: _formatTimeOfDay(sleepTime),
        targetController: _targetHidrasiController, // Menyediakan instance TargetHidrasiController
      );

      if (success && mounted) {
        Navigator.pop(context, true); // Mengirim true untuk menandakan ada perubahan
        _showOverlaySuccess("Profil berhasil diperbarui!");
      } else if (mounted) {
        _showOverlayError("Gagal memperbarui profil!");
      }
    } catch (e) {
      if (mounted) {
        // Lebih spesifik menangani error jika memungkinkan, atau tampilkan pesan umum
        _showOverlayError("Terjadi kesalahan: ${e.toString()}");
        print("Error saving profile: $e");
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
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A6FB)),
                ),
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
                        color: const Color(0xFF2F2E41),
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
                            Colors.grey.shade600, // Sedikit lebih gelap untuk kontras
                            () => Navigator.pop(context, false), // Mengirim false jika tidak ada perubahan
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildButton(
                            "Simpan",
                            const Color(0xFF00A6FB),
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
  Widget _buildTextField(TextEditingController controller, String label, String icon, {bool isNumber = false}) {
    return TextField(
      cursorColor: const Color(0xFF00A6FB),
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))] // Memperbolehkan satu digit desimal
          : [],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF00A6FB)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Color(0xFF00A6FB), BlendMode.srcIn), // Mewarnai ikon SVG
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Widget Dropdown untuk Jenis Kelamin
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: "Jenis Kelamin",
        labelStyle: const TextStyle(color: Color(0xFF00A6FB)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            "assets/images/profile/gender.svg",
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Color(0xFF00A6FB), BlendMode.srcIn),
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: genderMap.keys.map((String value) { // Menggunakan keys dari genderMap ("Laki-laki", "Perempuan")
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
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFF00A6FB), BlendMode.srcIn),
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2.5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTimeOfDay(time), // Menggunakan _formatTimeOfDay
              style: TextStyle(
                fontSize: 16,
                color: time == null ? Colors.grey.shade600 : const Color(0xFF2F2E41),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
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
        padding: const EdgeInsets.symmetric(vertical: 14), // Sedikit lebih tinggi
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3, // Menambah sedikit bayangan
      ),
      child: Text(
        text,
        style: GoogleFonts.inter( // Menggunakan GoogleFonts
            fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Fungsi untuk menampilkan Overlay Error
  void _showOverlayError(String message) {
    _showOverlay(message, Colors.red.shade400, Colors.white); // Warna teks putih untuk kontras
  }

  // Fungsi untuk menampilkan Overlay Sukses
  void _showOverlaySuccess(String message) {
    _showOverlay(message, const Color(0xFF00A6FB), Colors.white); // Warna teks putih
  }

  // Fungsi umum untuk menampilkan overlay
  void _showOverlay(String message, Color backgroundColor, Color textColor) {
    if (!mounted) return; // Pastikan widget masih ter-mount

    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry; 

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, 
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                .animate(CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOut)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Simpan referensi overlayEntry agar bisa diakses di dalam Future.delayed
    final OverlayEntry? currentOverlayEntry = overlayEntry;

    Future.delayed(const Duration(seconds: 3), () {
      // Gunakan null-aware operators untuk memanggil remove dan mengakses mounted
      if (currentOverlayEntry?.mounted ?? false) {
        currentOverlayEntry?.remove();
      }
      // Set overlayEntry ke null setelah dihapus atau jika tidak lagi mounted
      // Ini penting jika _showOverlay bisa dipanggil lagi sebelum Future selesai
      if (overlayEntry == currentOverlayEntry) {
          overlayEntry = null;
      }
    });
  }
}
