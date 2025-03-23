import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';

class EditProfile extends StatefulWidget {
  final String initialNama;
  final String initialJenisKelamin;
  final double initialBeratBadan;
  final int userId;

  const EditProfile({
    super.key,
    required this.initialNama,
    required this.initialJenisKelamin,
    required this.initialBeratBadan,
    required this.userId,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController nameController = TextEditingController();
  late TextEditingController weightController = TextEditingController();
  late String selectedGender;
  final ProfilPenggunaController _controller = ProfilPenggunaController();

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
    weightController =
        TextEditingController(text: widget.initialBeratBadan.toString());

    // Konversi "Male" / "Female" ke "Laki-laki" / "Perempuan"
    selectedGender = reverseGenderMap[widget.initialJenisKelamin] ?? 
                  (widget.initialJenisKelamin == "Male" ? "Laki-laki" : "Perempuan");
    selectedGender = reverseGenderMap[widget.initialJenisKelamin] ?? 
                  (widget.initialJenisKelamin == "Laki-laki" ? "Laki-laki" : "Perempuan");

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

    final success = await _controller.updateProfilDanNama(
      userId: widget.userId,
      nama: nama,
      jenisKelamin: selectedGender,
      beratBadan: berat,
    );

    if (success && mounted) {
      // Simpan data terbaru ke static class
      ProfileData.nama = nama;
      ProfileData.beratBadan = berat;

      Navigator.pop(context, true);
      _showOverlaySuccess("Profil berhasil diperbarui!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // Responsive width
        padding: const EdgeInsets.all(20),
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
            _buildTextField(nameController, "Nama Baru", Icons.person),

            const SizedBox(height: 15),

            // Jenis Kelamin (Dropdown)
            _buildDropdown(),

            const SizedBox(height: 15),

            // Berat Badan
            _buildTextField(
                weightController, "Berat Badan (kg)", Icons.fitness_center,
                isNumber: true),

            const SizedBox(height: 20),

            // Row untuk Tombol Batal & Simpan
            Row(
              children: [
                Expanded(
                    child: _buildButton(
                        "Batal", Colors.grey, () => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildButton(
                        "Simpan", Color(0xFF00A6FB), _saveProfile)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk input text
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF00A6FB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
        prefixIcon: const Icon(Icons.wc, color: Color(0xFF00A6FB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
    _showOverlay(message, Colors.green);
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
                    color: Colors.white,
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

class ProfileData {
  static String? nama;
  static double? beratBadan;
}
