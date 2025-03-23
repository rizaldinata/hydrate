import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import 'package:hydrate/presentation/screens/edit_profile.dart';
import 'package:hydrate/core/utils/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({
    super.key,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variabel state
  int? idPengguna;
  String? namaPengguna;
  String? jenisKelamin;
  double? beratBadan;
  String? jamBangun;
  String? jamTidur;

  // Deklarasi Controller 
  final ProfilPenggunaController _profilPenggunaController = ProfilPenggunaController();

  // function editprofile
  Future<void> _showEditProfile(BuildContext context) async {
    final session = SessionManager();
    final userId = await session.getUserId();
    
    if (userId == null) return;

    final pengguna = await PenggunaRepository().getPenggunaById(userId);
    if (pengguna == null) return;

    await showDialog<bool>(
    context: context,
    builder: (context) => EditProfile(
      userId: userId,
      initialNama: pengguna.nama,
      initialJenisKelamin: jenisKelamin ?? 'Laki-laki',
      initialBeratBadan: beratBadan ?? 60.0,
    ),
    ).then((success) {
    if (success == true) {
      _loadUserData(); // Refresh data lokal
      widget.onProfileUpdated?.call();  // Belum tentu terpakai
    }
    });

  }

  @override 
  void initState() {
    super .initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final session = SessionManager();
      final userId = await session.getUserId();

      if (userId != null) {
        final pengguna = await PenggunaRepository().getPenggunaById((userId));
        final profil = await _profilPenggunaController.getProfilPengguna((userId));

        if (pengguna != null && profil != null) {
          setState(() {
            namaPengguna = pengguna.nama; 
            jenisKelamin = profil.jenisKelamin == "Laki-laki" || profil.jenisKelamin == "Perempuan" ? profil.jenisKelamin : "Laki-laki";
            beratBadan = profil.beratBadan;
            jamBangun = profil.jamBangun;
            jamTidur = profil.jamTidur;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

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
                  height: screenHeight * 0.56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A6FB),
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
                          padding: EdgeInsets.only(
                              top: screenHeight * 0.02, bottom: screenHeight * 0.015),
                          child: Center(
                            child: SvgPicture.asset('assets/images/profile.svg', width: screenWidth * 0.2, ),
                          ),
                        ),

                        Transform.translate(
                          offset: Offset(0, screenHeight * -0.005),
                          child: Center(
                            child: Text(
                              namaPengguna ?? 'Belum diatur',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Informasi Profil
                        _profileInfo(Icons.person, "Jenis Kelamin", jenisKelamin ?? 'Laki-laki'),
                        _profileInfo(Icons.fitness_center, "Berat badan", "${beratBadan?.toStringAsFixed(1) ?? '0.0'} kg"),
                        _profileInfo(Icons.wb_sunny, "Jam Bangun", jamBangun ?? 'Belum diatur'),
                        _profileInfo(Icons.nightlight_round, "Jam Tidur", jamTidur ?? 'Belum diatur'),

                        SizedBox(height: screenHeight * 0.01,),

                        // Tombol Edit Profile
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                              onPressed: () => _showEditProfile(context),
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  minimumSize: Size(
                                      screenWidth * 0.9, screenHeight * 0.05)),
                              child: const Text(
                                "Edit Profile",
                                style: TextStyle(
                                    color: Color(0xFF2F2E41),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}