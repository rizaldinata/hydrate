import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/registration2_view.dart';

class RegistrationData extends StatefulWidget {
  @override
  _RegistrationDataState createState() => _RegistrationDataState();
}

class _RegistrationDataState extends State<RegistrationData> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerWeight = TextEditingController();

  // Mengubah ke format yang konsisten dengan database
  String selectedGender = "Perempuan"; // Default gender

  // Validasi input
  bool _isFormValid() {
    return controllerName.text.isNotEmpty &&
        selectedGender.isNotEmpty &&
        controllerWeight.text.isNotEmpty &&
        double.tryParse(controllerWeight.text) != null;
  }

  // Fungsi untuk menampilkan modal peringatan
  Future<void> _showWarningDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                        backgroundColor: const Color(0XFFFFB830),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
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

                // Pilihan Jenis Kelamin - Format konsisten dengan database
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFF00A6FB), width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Background animasi bergerak
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: selectedGender == "Perempuan"
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2 - 20,
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
                                  selectedGender = "Perempuan";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(50)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    selectedGender == "Perempuan"
                                        ? SvgPicture.asset(
                                            'assets/images/women.svg',
                                            height: 22,
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/women.svg',
                                            height: 22,
                                            colorFilter: ColorFilter.mode(
                                                const Color(0xFF2F2E41)
                                                    .withOpacity(0.5),
                                                BlendMode.srcIn),
                                          ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Perempuan",
                                      style: TextStyle(
                                        color: selectedGender == "Perempuan"
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
                                  selectedGender = "Laki-laki";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(50)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    selectedGender == "Laki-laki"
                                        ? SvgPicture.asset(
                                            'assets/images/man.svg',
                                            height: 22,
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/man.svg',
                                            height: 22,
                                            colorFilter: ColorFilter.mode(
                                                const Color(0xFF2F2E41)
                                                    .withOpacity(0.5),
                                                BlendMode.srcIn),
                                          ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Laki-laki",
                                      style: TextStyle(
                                        color: selectedGender == "Laki-laki"
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
                  keyboardType: TextInputType.number,
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
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        if (_isFormValid()) {
                          double? weight = double.tryParse(controllerWeight.text);

                          if (weight != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationTime(
                                  name: controllerName.text,
                                  gender: selectedGender, // Menggunakan format yang konsisten dengan database
                                  weight: weight,
                                ),
                              ),
                            );
                          }
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