import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationData extends StatefulWidget {
  @override
  _RegistrationDataState createState() => _RegistrationDataState();
}

class _RegistrationDataState extends State<RegistrationData> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerHeight = TextEditingController();
  TextEditingController controllerWeight = TextEditingController();

  // Tambahkan state untuk menyimpan jenis kelamin
  String? _gender = "Female";

// Fungsi untuk mengirim data
  void kirimData() {
    AlertDialog alertDialog = AlertDialog(
      content: Container(
        height: 200.0,
        padding: EdgeInsets.all(10.0),
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            Text("Nama Lengkap : ${controllerName.text}"),
            Text("Tinggi Badan : ${controllerHeight.text} cm"),
            Text("Berat Badan : ${controllerWeight.text} kg"),
            Text(
                "Jenis Kelamin : ${_gender ?? 'Belum dipilih'}"), // Menampilkan gender
            Padding(padding: EdgeInsets.only(top: 20.0)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Kembali", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    showDialog(context: context, builder: (context) => alertDialog);
  }

  String selectedGender = "Perempuan"; // Default gender

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF), // Warna background
      body: SafeArea(
        child: SingleChildScrollView(
          // Agar bisa discroll saat keyboard muncul
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

                // Sub-judul
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
                  controller: controllerName,
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Nama Lengkap",
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true, // Aktifkan pengisian warna latar belakang
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF00A6FB),
                          width: 2), // Warna border saat tidak fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF00A6FB),
                          width: 2), // Warna border saat fokus
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
                  child: Row(
                    children: [
                      // Tombol Perempuan
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGender = "Female";
                              _gender = "Female";
                            });
                          },

                          // Simpan nilai
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _gender == "Female"
                                  ? const Color(0xFF00A6FB)
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(50),
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
                                  textAlign: TextAlign.center,
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
                              selectedGender = "Male";
                              _gender = "Male";
                            });
                          },
                          // Simpan nilai
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _gender == "Male"
                                  ? const Color(0xFF00A6FB)
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(50),
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
                                  textAlign: TextAlign.center,
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
                ),

                const SizedBox(height: 10),

                // Input Tinggi Badan
                TextField(
                  controller: controllerHeight,
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Tinggi Badan",
                    suffixText: "cm",
                    suffixStyle: TextStyle(
                      color: const Color(0xFF2F2E41),
                      fontSize: 16,
                    ),
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true, // Aktifkan pengisian warna latar belakang
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF00A6FB),
                          width: 2), // Warna border saat tidak fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF00A6FB),
                          width: 2), // Warna border saat fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 10),

                // Input Berat Badan
                TextField(
                  controller: controllerWeight,
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Berat Badan",
                    suffixText: "kg",
                    suffixStyle:
                        TextStyle(color: const Color(0xFF2F2E41), fontSize: 16),
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true, // Aktifkan pengisian warna latar belakang
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF00A6FB),
                          width: 2), // Warna border saat tidak fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF00A6FB),
                          width: 2), // Warna border saat fokus
                      borderRadius: BorderRadius.circular(50),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Lanjut
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4ACCFF),
                          Color(0xFF00A6FB),
                        ], // Warna gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00A6FB)
                              .withOpacity(0.25), // Warna bayangan
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                        // Aksi saat tombol diklik ke halaman selanjutnya
                        kirimData();
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
