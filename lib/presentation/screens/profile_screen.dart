import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/widgets/navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 242, 253),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Kontainer Profil
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.58,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: screenHeight * 0.05,
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04), // Top 60px untuk status bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto Profil
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02),
                          child: Center(
                            child: Container(
                              clipBehavior: Clip.hardEdge,
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1000)),
                              child: Image.asset(
                                "assets/images/navigasi/user.png",
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            "Hilmi Afifi",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Informasi Profil
                        _profileInfo(
                            Icons.person, "Jenis Kelamin", "Laki - Laki"),
                        _profileInfo(
                            Icons.fitness_center, "Berat badan", "60 kg"),
                        _profileInfo(
                            Icons.nightlight_round, "Jam Tidur", "22:00 WIB"),
                        _profileInfo(Icons.wb_sunny, "Jam Bangun", "05:00 WIB"),

                        const SizedBox(height: 30),

                        // Tombol Edit Profile
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  minimumSize: Size(
                                      screenWidth * 0.9, screenHeight * 0.05)),
                              child: const Text(
                                "Edit Profile",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk informasi profil
  Widget _profileInfo(IconData icon, String title, String value) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02, vertical: screenHeight * 0.015),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
