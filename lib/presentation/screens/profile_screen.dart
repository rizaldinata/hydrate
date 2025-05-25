import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import 'package:hydrate/presentation/screens/edit_profile.dart'; 
import 'package:hydrate/core/utils/app_event_bus.dart';

// 1. Widget Provider (Stateless)
class ProfileScreenProvider extends StatelessWidget {
  final VoidCallback? onProfileUpdated; 
  final Key? profileScreenWidgetKey;

  const ProfileScreenProvider({super.key, this.onProfileUpdated, this.profileScreenWidgetKey});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfilPenggunaController()..loadUserProfile(),
      child: ProfileScreen(onProfileUpdated: onProfileUpdated, profileScreenWidgetKey: profileScreenWidgetKey), 
    );
  }
}

// 2. Widget Screen (UI Sebenarnya)
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  final Key? profileScreenWidgetKey;

  const ProfileScreen({
    super.key,
    this.onProfileUpdated,
    this.profileScreenWidgetKey,
  });

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();

  @override
  void initState() {
    super.initState();
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event == 'refresh_profile' || event == 'refresh_all') {
        refresh();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // Metode publik untuk memaksa refresh data dari luar (misalnya oleh MainScreen)
  void refresh() {
    print("ProfileScreenState: refresh() called, triggering controller.loadUserProfile()");
    // Panggil metode load dari controller menggunakan context.read
    if (mounted) {
      context.read<ProfilPenggunaController>().loadUserProfile();
    }
  }

  Future<void> _showEditProfile(BuildContext context) async {
    // Gunakan context.read untuk mendapatkan controller sekali saja
    final controller = context.read<ProfilPenggunaController>();

    if (controller.idPengguna == null) {
      _showSnackBar("Tidak dapat mengedit profil. Data pengguna tidak tersedia.");
      return;
    }

    final bool? updateSuccess = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => EditProfile(
        userId: controller.idPengguna!,
        initialNama: controller.namaPengguna ?? 'Belum diatur',
        initialJenisKelamin: controller.jenisKelamin ?? 'Laki-laki',
        initialBeratBadan: controller.beratBadan ?? 60.0,
        initialJamBangun: controller.jamBangun,
        initialJamTidur: controller.jamTidur,
      ),
    );

    if (updateSuccess == true && mounted) {
      // Minta controller untuk memuat ulang data dirinya
      await controller.loadUserProfile(); 
      widget.onProfileUpdated?.call();
      _eventBus.fire('refresh_all');
      _showSnackBar("Profil berhasil diperbarui.");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfilPenggunaController>();

    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double paddingTop = MediaQuery.of(context).padding.top;
    // ... (variabel ukuran Anda yang lain)
    final double titleFontSize = screenWidth * 0.04;
    final double nameFontSize = screenWidth * 0.045;
    final double infoFontSize = screenWidth * 0.038;
    final double profileImageSize = screenWidth * 0.2;

    if (controller.isLoading && controller.idPengguna == null) { // Tampilkan loading awal jika idPengguna belum ada
      return const Scaffold(
          backgroundColor: Color(0xFFE8F7FF),
          body: Center(child: CircularProgressIndicator()));
    }

    if (controller.errorMessage != null && controller.errorMessage!.isNotEmpty) {
      return Scaffold(
          backgroundColor: Color(0xFFE8F7FF),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(controller.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          )));
    }
    
    if (controller.idPengguna == null && !controller.isLoading) {
       return const Scaffold(
          backgroundColor: Color(0xFFE8F7FF),
          body: Center(child: Text("Data pengguna tidak dapat dimuat. Silakan coba lagi.", style: TextStyle(color: Colors.orange))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: Column( // Layout utama Anda
        children: [
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                 constraints: BoxConstraints(minHeight: screenHeight * 0.50), // Sesuaikan jika perlu
                 child: IntrinsicHeight(
                   child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF2AD1D1), Colors.blueAccent]),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
                        boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(4, 4), blurRadius: 10),
                            BoxShadow(color: Colors.white.withValues(alpha: 0.5), offset: const Offset(-4, -4), blurRadius: 10),
                        ]
                    ),
                    padding: EdgeInsets.only(
                        top: paddingTop + (screenHeight * 0.02),
                        left: screenWidth * 0.05,
                        right: screenWidth * 0.05,
                        bottom: screenHeight * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.01),
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.025),
                            decoration: BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle,
                                boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(4,4), blurRadius: 8),
                                    BoxShadow(color: Colors.white.withValues(alpha: 0.6), offset: const Offset(-4,-4), blurRadius: 8)
                                ]
                            ),
                            child: SvgPicture.asset('assets/images/profile.svg',
                                width: profileImageSize, height: profileImageSize, fit: BoxFit.contain),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Center(
                          child: Text(
                            controller.namaPengguna ?? 'Belum diatur', // DATA DARI CONTROLLER
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: nameFontSize, color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _profileInfo(Icons.person, "Jenis Kelamin", controller.jenisKelamin ?? 'Belum diatur', screenWidth, infoFontSize),
                        _profileInfo(Icons.fitness_center, "Berat badan", "${controller.beratBadan?.toStringAsFixed(1) ?? '0.0'} kg", screenWidth, infoFontSize),
                        _profileInfo(Icons.wb_sunny, "Jam Bangun", controller.jamBangun ?? 'Belum diatur', screenWidth, infoFontSize),
                        _profileInfo(Icons.nightlight_round, "Jam Tidur", controller.jamTidur ?? 'Belum diatur', screenWidth, infoFontSize),
                        SizedBox(height: screenHeight * 0.03),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _showEditProfile(context),
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                elevation: 5,
                                backgroundColor: Colors.white,
                                shadowColor: Colors.black.withValues(alpha: 0.2),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                                minimumSize: Size(screenWidth * 0.8, screenHeight * 0.05),
                            ),
                            child: Text("Edit Profile", style: TextStyle(color: const Color(0xFF2F2E41), fontWeight: FontWeight.w700, fontSize: titleFontSize)),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                      ],
                    ),
                  ),
                 ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _profileInfo tidak perlu diubah, karena ia menerima data sebagai argumen
  Widget _profileInfo(IconData icon, String title, String value,
      double screenWidth, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: screenWidth * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white, size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.025),
            Text(title, style: GoogleFonts.inter(fontSize: fontSize, color: Colors.white)),
          ]),
          Text(value, style: GoogleFonts.inter(fontSize: fontSize, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}