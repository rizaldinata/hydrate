import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/login_view.dart';
// Ganti RegistrationData dengan nama file/kelas Anda untuk input nama,gender,berat (misal, Registration1View)
import 'package:hydrate/presentation/screens/Pendaftaran/registration1_view.dart';
import 'package:hydrate/presentation/widgets/alert_widget.dart';
import 'package:hydrate/presentation/widgets/alert_widget.dart' as AlertWidget;
// Hapus import AuthServices jika tidak lagi membuat user Firebase di sini
// import 'package:hydrate/services/auth_services.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key}); // Tambahkan const

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPass = TextEditingController();
  TextEditingController controllerPassConfirm = TextEditingController();
  bool isFormFilled = false;
  bool _obscurePassword = true;
  bool _isLoading = false; // Untuk loading state

  void _checkForm() {
    if (mounted) { // Pastikan widget masih ada di tree
      setState(() {
        isFormFilled = controllerEmail.text.isNotEmpty &&
            controllerPass.text.isNotEmpty &&
            controllerPassConfirm.text.isNotEmpty;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    controllerEmail.addListener(_checkForm);
    controllerPass.addListener(_checkForm);
    controllerPassConfirm.addListener(_checkForm);
  }

  @override
  void dispose() {
    controllerEmail.removeListener(_checkForm); // Hapus listener
    controllerPass.removeListener(_checkForm);
    controllerPassConfirm.removeListener(_checkForm);
    controllerEmail.dispose();
    controllerPass.dispose(); // Jangan lupa dispose semua controller
    controllerPassConfirm.dispose();
    super.dispose();
  }

  Future<void> _handleNextButton() async {
    String email = controllerEmail.text.trim();
    String pass = controllerPass.text.trim();
    String confirmPass = controllerPassConfirm.text.trim();

    bool isEmailValid = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);

    if (!isEmailValid) {
      AlertWidget.showWarningDialog(context, "Masukkan email yang valid");
      return;
    }
    if (pass.length < 6) {
      AlertWidget.showWarningDialog(context, "Password minimal harus 6 karakter.");
      return;
    }
    if (pass != confirmPass) {
      AlertWidget.showWarningDialog(context, "Konfirmasi password tidak cocok");
      return;
    }

    // Jika semua validasi sisi klien lolos, kita tidak membuat akun Firebase Auth di sini.
    // Kita akan meneruskan email dan password ke langkah berikutnya.
    // Akun Firebase Auth akan dibuat secara terpusat oleh PenggunaRepository
    // bersamaan dengan penyimpanan data profil.

    if (mounted) {
      setState(() { _isLoading = true; }); // Aktifkan loading
    }

    // Simulate a small delay if needed, or directly navigate
    // For now, we just navigate and pass the data
    // No async operation here yet, so loading might be very brief or not noticeable
    // unless the next screen has heavy build.

    print("RegistrationView: Navigasi ke RegistrationData dengan email: $email");
    // Password juga diteruskan untuk digunakan nanti oleh PenggunaRepository
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationData( // Ini adalah Registration1View Anda
          email: email,
          password: pass, // Teruskan password juga
        ),
      ),
    );

    if (mounted) {
      setState(() { _isLoading = false; }); // Nonaktifkan loading jika masih di halaman ini
    }
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
                // ... (UI Anda untuk gambar, judul, dll. tetap sama) ...
                const SizedBox(height: 20),
                SvgPicture.asset('assets/images/registrasi2.svg', width: MediaQuery.of(context).size.width * 0.7),
                const SizedBox(height: 20),
                Text("DAFTAR SEKARANG", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2F2E41))),
                Text("Isilah sesuai dengan data diri kamu", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2F2E41))),
                const SizedBox(height: 20),

                // Input Email
                TextField(
                  controller: controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  // ... (style dekorasi Anda)
                   decoration: InputDecoration(hintText: "Masukkan Alamat Email", hintStyle: TextStyle(color: const Color(0xFF2F2E41).withOpacity(0.5)), filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2), borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2), borderRadius: BorderRadius.circular(16)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
                const SizedBox(height: 20),

                // Input Password
                TextField(
                  controller: controllerPass,
                  obscureText: _obscurePassword,
                  // ... (style dekorasi Anda dengan suffixIcon)
                  decoration: InputDecoration(hintText: "Masukkan Kata Sandi", hintStyle: TextStyle(color: const Color(0xFF2F2E41).withOpacity(0.5)), filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2), borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2), borderRadius: BorderRadius.circular(16)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF2F2E41)), onPressed: () {setState(() {_obscurePassword = !_obscurePassword;});})),
                ),
                const SizedBox(height: 20),

                // Input Konfirmasi Password
                TextField(
                  controller: controllerPassConfirm,
                  obscureText: _obscurePassword,
                  // ... (style dekorasi Anda dengan suffixIcon)
                   decoration: InputDecoration(hintText: "Konfirmasi Kata Sandi", hintStyle: TextStyle(color: const Color(0xFF2F2E41).withOpacity(0.5)), filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2), borderRadius: BorderRadius.circular(16)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2), borderRadius: BorderRadius.circular(16)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF2F2E41)), onPressed: () {setState(() {_obscurePassword = !_obscurePassword;});})),
                ),
                const SizedBox(height: 50),

                // Tombol DAFTAR (Sebelumnya Tombol Selanjutnya)
                GestureDetector( // Menggunakan GestureDetector agar bisa menampung ElevatedButton di dalamnya
                  onTap: isFormFilled && !_isLoading ? _handleNextButton : null,
                  child: Container(
                    height: 55,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom:10),
                    decoration: BoxDecoration(
                      gradient: isFormFilled && !_isLoading
                          ? const LinearGradient(
                              colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isFormFilled && !_isLoading
                          ? null
                          : Colors.grey[400], // Warna abu-abu saat tidak aktif atau loading
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center( // Menggunakan Center untuk ElevatedButton
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,))
                          : Text(
                              "SELANJUTNYA", // Teks diubah menjadi Selanjutnya
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                // ... (UI "Atau" dan "Masuk Sekarang" Anda tetap sama,
                // pastikan tombol "Masuk Sekarang" menavigasi ke LoginView)
                Text("Atau", style: GoogleFonts.inter(fontSize: 14, color: Color(0xFF2F2E41))),
                const SizedBox(height: 10),
                // Container untuk Google Sign In (komentari jika belum ada)
                // Container(...),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement( // Ganti ke pushReplacement agar tidak bisa kembali
                      context,
                      MaterialPageRoute(builder: (context) => LoginView()), // Navigasi ke LoginView
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Sudah punya akun?", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2F2E41), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 5),
                      Text("Masuk Sekarang", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF00A6FB), fontWeight: FontWeight.bold)),
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