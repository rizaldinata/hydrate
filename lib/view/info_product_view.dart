import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/view/registration1_view.dart';

class InfoProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF), // Warna background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SvgPicture.asset(
                  'assets/images/registrasi1.svg',
                  width: 275,
                ),
              ),
            ),

            const SizedBox(height: 20), 

            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Column(
                    children: [

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
                        offset:
                            const Offset(0, -16), // Mengurangi jarak vertikal
                        child: Text(
                          "Hidrasi Tepat, Hidup Sehat",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2F2E41),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),

                  const Spacer(), // Spasi agar tombol ke bawah

                  // Deskripsi
                  Text(
                    "Mulai perjalanan sehatmu sekarang dan rasakan manfaatnya!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Let’s stay hydrated!",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20.0,
                  ),

                  // Button Masuk
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
                        RegistrationData();
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
          ],
        ),
      ),
    );
  }
}
