import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/main.dart';
import 'package:hydrate/presentation/widgets/alert_widget.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPass = TextEditingController();
  bool isFormFilled = false;
  bool _obscurePassword = true; 

  void _checkForm() {
    setState(() {
      isFormFilled =
          controllerEmail.text.isNotEmpty && controllerPass.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();

    controllerEmail.addListener(_checkForm);
    controllerPass.addListener(_checkForm);
  }

  @override
  void dispose() {
    controllerEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Gambar
                SvgPicture.asset(
                  'assets/images/registrasi2.svg',
                  width: MediaQuery.of(context).size.width * 0.7,
                ),

                const SizedBox(height: 20),

                // Teks "DAFTAR"
                Text(
                  "MASUK",
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: controllerEmail,
                      cursorColor: const Color(0xFF00A6FB),
                      buildCounter: (
                        BuildContext context, {
                        required int currentLength,
                        required int? maxLength,
                        required bool isFocused,
                      }) =>
                          const SizedBox(), // Sembunyikan counter bawaan
                      decoration: InputDecoration(
                        hintText: "Masukkan Alamat Email",
                        hintStyle: TextStyle(
                            color: const Color(0xFF2F2E41).withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF00A6FB), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF00A6FB), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Input Password
                TextField(
                  controller: controllerPass,
                  obscureText: _obscurePassword,
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Masukkan Kata Sandi",
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: const Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: const Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF2F2E41),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Tombol Selanjutnya
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isFormFilled
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF4ACCFF),
                                Color(0xFF00A6FB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isFormFilled
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
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: isFormFilled
                          ? () {
                              String email = controllerEmail.text.trim();
                              String pass = controllerPass.text.trim();

                              if (email == '@gmail.com') {
                                showWarningDialog(
                                    context, "Masukkan email yang valid");
                              } else {
                                // Semua valid, lanjut ke halaman berikutnya
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MainScreen(),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        "MASUK",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                Text(
                  "Atau",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Color(0xFF2F2E41),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric( vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/splash/google.png',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Masuk dengan Google",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Masuk
                GestureDetector(
                  onTap: () {
                    // Aksi saat tombol "Masuk" ditekan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Belum punya akun?",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF2F2E41),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Daftar Sekarang",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF00A6FB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
