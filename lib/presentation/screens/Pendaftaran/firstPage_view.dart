import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/splash_view.dart';

class InfoProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.1),

                  SvgPicture.asset(
                    'assets/images/registrasi1.svg',
                    width: screenWidth * 0.7,
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  Text(
                    "HYDRATE",
                    style: GoogleFonts.gluten(
                      fontSize: screenWidth * 0.12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00A6FB),
                    ),
                  ),

                  Text(
                    "Hidrasi Tepat, Hidup Sehat",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F2E41),
                    ),
                  ),

                  // Tambahan dan gk keliatan biar layoutnya rapi
                  AbsorbPointer(
                    absorbing: true,
                    child: Opacity(
                      opacity: 0.0,
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      children: [
                        Text(
                          "Mulai perjalanan sehatmu sekarang dan rasakan manfaatnya",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          "Ayo mulai penuhi hidrasi harianmu!",
                          style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  SizedBox(
                    // width: screenWidth * 0.8,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 50),
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00A6FB).withOpacity(0.25),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OnboardingScreen()),
                          );
                        },
                        child: Text(
                          "MULAI SEKARANG",
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
