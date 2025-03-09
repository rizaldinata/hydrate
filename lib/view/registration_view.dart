import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {

  TextEditingController controllerNama = TextEditingController();
  TextEditingController controllerPass = TextEditingController();
  TextEditingController controllerMoto = TextEditingController();

  String selectedGender = "Perempuan"; // Default gender

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF), // Warna background
      body: SafeArea(
        child: SingleChildScrollView( // Agar bisa discroll saat keyboard muncul
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

                // Subtitle
                Transform.translate(
                  offset: const Offset(0, -16), // Mengurangi jarak vertikal
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

                // Sub-teks
                Text(
                  "Isilah sesuai dengan data diri sama kamu",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                const SizedBox(height: 20),

                // Input Nama Lengkap
                TextField(
                  decoration: InputDecoration(
                    hintText: "Nama Lengkap",
                    labelText: "Nama Lengkap",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2), // Warna border saat tidak fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: const Color(0xFF00A6FB), width: 2), // Warna border saat fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),




                const SizedBox(height: 10),

                // Pilihan Jenis Kelamin
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
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
                            decoration: BoxDecoration(
                              color: selectedGender == "Perempuan" ? Colors.blue : Color(0xFFE8F7FF),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              
                              "Perempuan",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedGender == "Perempuan" ? Color(0xFFE8F7FF) : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tombol Laki-laki
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGender = "Laki - Laki";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedGender == "Laki - Laki" ? Colors.blue : const Color(0xFFE8F7FF),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              "Laki - Laki",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedGender == "Laki - Laki" ? const Color(0xFFE8F7FF) : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Input Tinggi Badan
                TextField(
                  decoration: InputDecoration(
                    hintText: "Tinggi Badan",
                    labelText: "Tinggi Badan",
                    suffixText: "cm",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 10),

                // Input Berat Badan
                TextField(
                  decoration: InputDecoration(
                    hintText: "Berat Badan",
                    labelText: "Berat Badan",
                    suffixText: "Kg",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Lanjut
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A6FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      // Aksi saat tombol diklik
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
