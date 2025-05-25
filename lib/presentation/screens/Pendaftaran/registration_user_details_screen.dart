import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/controllers/registration_user_details_controller.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/widgets/registration_user_details_form.dart';

class RegistrationUserDetailsScreen extends StatelessWidget {
  final String email;
  final String password;

  const RegistrationUserDetailsScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationUserDetailsController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("HYDRATE", style: GoogleFonts.gluten(fontSize: 52, fontWeight: FontWeight.bold, color: const Color(0xFF00A6FB))),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Text("Hidrasi Tepat, Hidup Sehat", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF2F2E41))),
                  ),
                  const SizedBox(height: 20),
                  SvgPicture.asset('assets/images/registrasi2.svg', width: 250),
                  const SizedBox(height: 20),
                  Text("DAFTAR", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2F2E41))),
                  Text("Isilah sesuai dengan data diri kamu", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2F2E41))),
                  const SizedBox(height: 20),
                  
                  // Panggil widget form dan teruskan email & password
                  RegistrationUserDetailsForm(
                    email: email,
                    password: password,
                  ),
                  
                  const SizedBox(height: 50), // Margin bawah
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}