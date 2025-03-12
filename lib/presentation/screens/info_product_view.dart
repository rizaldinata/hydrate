import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/registration1_view.dart';

class InfoProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF), // Warna background
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SvgPicture.asset(
                      'assets/images/registrasi1.svg',
                      width: screenWidth * 0.7,
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.02),
                
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: [
                          Text(
                            "HYDRATE",
                            style: GoogleFonts.gluten(
                              fontSize: screenWidth * 0.12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00A6FB),
                            ),
                          ),
                          
                          Transform.translate(
                            offset: Offset(0, -screenHeight * 0.02),
                            child: Text(
                              "Hidrasi Tepat, Hidup Sehat",
                              style: GoogleFonts.inter(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2F2E41),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),

                      Spacer(),
                      
                      Text(
                        "Mulai perjalanan sehatmu sekarang dan rasakan manfaatnya!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: screenWidth * 0.035),
                      ),
                      
                      SizedBox(height: screenHeight * 0.01),
                      
                      Text(
                        "Let’s stay hydrated!",
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.03),
                      
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.05),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
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
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegistrationData()),
                              );
                            },
                            child: Text(
                              "MASUK",
                              style: GoogleFonts.inter(
                                fontSize: screenWidth * 0.045,
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
          );
        },
      ),
    );
  }
}