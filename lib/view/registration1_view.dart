import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/view/registration2_view.dart';

class RegistrationData extends StatefulWidget {
  @override
  _RegistrationDataState createState() => _RegistrationDataState();
}

class _RegistrationDataState extends State<RegistrationData> {
<<<<<<< HEAD
  TextEditingController controllerName = TextEditingController();
=======
  final TextEditingController controllerName = TextEditingController();
  TextEditingController controllerHeight = TextEditingController();
>>>>>>> 39f783e (memperbaiki beberapa kode alert)
  TextEditingController controllerWeight = TextEditingController();

  String? _gender = "Female";
  String selectedGender = "Perempuan"; // Default gender
  // bool _showWarning = false;

  // Validasi input
  bool _isFormValid() {
    return controllerName.text.isNotEmpty &&
        _gender != null &&
        controllerWeight.text.isNotEmpty &&
        double.tryParse(controllerWeight.text) !=
            null; // Validasi angka untuk berat badan
  }

  // Fungsi untuk menampilkan modal peringatan
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
                      "Harap lengkapi semua data terlebih dahulu!",
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
      backgroundColor: const Color(0xFFE8F7FF), // Warna background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Logo HYDRATE
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
                      fontWeight: FontWeight.w800,
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
                  "Isilah sesuai dengan data diri kamu",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                const SizedBox(height: 20),

                // Input Nama Lengkap
                TextField(
                  controller: controllerName,
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Nama Lengkap",
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 10),

                // Pilihan Jenis Kelamin
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border:
                        Border.all(color: const Color(0xFF00A6FB), width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Background animasi bergerak
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: _gender == "Female"
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2 -
                              20, // Lebar setengah dari container
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A6FB),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Tombol Perempuan
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gender = "Female";
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(50)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.woman,
                                      color: _gender == "Female"
                                          ? Colors.white
                                          : const Color(0xFF2F2E41)
                                              .withOpacity(0.5),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Perempuan",
                                      style: TextStyle(
                                        color: _gender == "Female"
                                            ? Colors.white
                                            : const Color(0xFF2F2E41)
                                                .withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Tombol Laki-laki
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gender = "Male";
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(50)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.man,
                                      color: _gender == "Male"
                                          ? Colors.white
                                          : const Color(0xFF2F2E41)
                                              .withOpacity(0.5),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Laki - Laki",
                                      style: TextStyle(
                                        color: _gender == "Male"
                                            ? Colors.white
                                            : const Color(0xFF2F2E41)
                                                .withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Input Berat Badan (Only numbers)
                TextField(
                  controller: controllerWeight,
                  keyboardType:
                      TextInputType.number, // Ensuring only numbers are allowed
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Berat Badan",
                    suffixText: "kg",
                    suffixStyle:
                        TextStyle(color: const Color(0xFF2F2E41), fontSize: 16),
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: const Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: const Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 50),

                // Tombol Selanjutnya
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4ACCFF),
                          Color(0xFF00A6FB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00A6FB).withOpacity(0.25),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        if (_isFormValid()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationTime(
                                name: controllerName.text,
                                gender: _gender ?? "Belum dipilih",
                                weight: controllerWeight.text,
                              ),
                            ),
                          );
                        } else {
                          _showWarningDialog();
                        }
                      },
                      child: Text(
                        "SELANJUTNYA",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
