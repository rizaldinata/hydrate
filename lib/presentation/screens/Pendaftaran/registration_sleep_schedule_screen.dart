import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/controllers/registration_sleep_schedule_controller.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/widgets/registration_sleep_schedule_form.dart';

class RegistrationSleepScheduleScreen extends StatelessWidget {
  final String name;
  final String gender;
  final double weight;
  final String email;
  final String password;

  const RegistrationSleepScheduleScreen({
    super.key,
    required this.name,
    required this.gender,
    required this.weight,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrationSleepScheduleController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("HYDRATE", style: GoogleFonts.gluten(fontSize: 52, fontWeight: FontWeight.bold, color: const Color(0xFF00A6FB))),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Text("Hidrasi Tepat, Hidup Sehat", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2F2E41))),
                  ),
                  const SizedBox(height: 20),
                  SvgPicture.asset('assets/images/registrasi2.svg', width: 250),
                  const SizedBox(height: 20),
                  Text("DAFTAR", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2F2E41))),
                  Text("Isilah waktu yang sesuai sama kamu", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2F2E41))),
                  const SizedBox(height: 20),
                  
                  RegistrationSleepScheduleForm(
                    name: name,
                    gender: gender,
                    weight: weight,
                    email: email,
                    password: password,
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