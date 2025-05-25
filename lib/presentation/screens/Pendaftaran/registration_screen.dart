import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:hydrate/presentation/controllers/registration_controller.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/login_view.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/widgets/registration_form.dart';

class RegistrationView extends StatelessWidget {
  const RegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Sediakan controller untuk widget di bawahnya
    return ChangeNotifierProvider(
      create: (_) => RegistrationController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  SvgPicture.asset('assets/images/registrasi2.svg', width: MediaQuery.of(context).size.width * 0.7),
                  const SizedBox(height: 20),
                  Text("DAFTAR SEKARANG", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2F2E41))),
                  Text("Isilah sesuai dengan data diri kamu", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2F2E41))),
                  const SizedBox(height: 20),
                  
                  // Panggil widget form yang sudah terpisah
                  const RegistrationForm(),
                  
                  const SizedBox(height: 30),
                  Text("Atau", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2F2E41))),
                  const SizedBox(height: 10),
                  // ... Tombol Google Sign In
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginView()),
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
      ),
    );
  }
}