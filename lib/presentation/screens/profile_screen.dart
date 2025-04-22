import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import 'package:hydrate/presentation/screens/edit_profile.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({
    super.key,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  // Variabel state
  int? idPengguna;
  String? namaPengguna;
  String? jenisKelamin;
  double? beratBadan;
  String? jamBangun;
  String? jamTidur;
  bool _isLoading = true;
  String _errorMessage = '';

  // Deklarasi Controller
  final ProfilPenggunaController _profilPenggunaController =
      ProfilPenggunaController();

  // Stream subscription untuk event bus
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();

  // function editprofile
  Future<void> _showEditProfile(BuildContext context) async {
    if (idPengguna == null) {
      _showSnackBar("Tidak dapat mengedit profil. ID pengguna tidak tersedia.");
      return;
    }

    // Gunakan data yang sudah diambil pada state untuk inisialisasi dialog
    await showDialog<bool>(
      context: context,
      builder: (context) => EditProfile(
        userId: idPengguna!,
        initialNama: namaPengguna ?? 'Belum diatur',
        initialJenisKelamin: jenisKelamin ?? 'Laki-laki',
        initialBeratBadan: beratBadan ?? 60.0,
        initialJamBangun: jamBangun,
        initialJamTidur: jamTidur,
      ),
    ).then((success) {
      if (success == true) {
        _loadUserData(); // Refresh data lokal
        widget.onProfileUpdated
            ?.call(); // Callback untuk memberitahu parent widget

        // Trigger refresh pada halaman lain
        _eventBus.fire('refresh_all');
      }
    });
  }

  // Metode publik untuk memaksa refresh data
  void refresh() {
    print("Refreshing Profile data...");
    _loadUserData();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Subscribe ke event bus untuk refresh data
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_profile' || event.type == 'refresh_all') {
        refresh();
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final session = SessionManager();
      final userId = await session.getUserId();

      if (userId != null) {
        setState(() => idPengguna = userId);

        final pengguna = await PenggunaRepository().getPenggunaById(userId);
        final profil =
            await _profilPenggunaController.getProfilPengguna(userId);

        if (pengguna != null) {
          setState(() {
            namaPengguna = pengguna.nama;
          });
        }

        if (profil != null) {
          setState(() {
            jenisKelamin = profil.jenisKelamin == "Laki-laki" ||
                    profil.jenisKelamin == "Perempuan"
                ? profil.jenisKelamin
                : "Laki-laki";
            beratBadan = profil.beratBadan;
            jamBangun = profil.jamBangun;
            jamTidur = profil.jamTidur;
          });
        }
      } else {
        setState(() => _errorMessage = 'Pengguna belum login');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat data: ${e.toString()}');
      print("Error loading user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get device metrics for responsive layout
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double paddingTop = MediaQuery.of(context).padding.top;

    // Adjust profile container height based on screen size
    final double profileContainerHeight = screenHeight * 0.58;

    // Adjust padding and spacing based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;

    // Adjust font sizes based on screen width
    final double titleFontSize = screenWidth * 0.04;
    final double nameFontSize = screenWidth * 0.045;
    final double infoFontSize = screenWidth * 0.038;

    // Adjust profile image size
    final double profileImageSize = screenWidth * 0.2;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // Bagian profil pengguna dengan scroll
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: screenHeight * 0.50,
                          ),
                          child: IntrinsicHeight(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2AD1D1),
                                    Colors.blueAccent,
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: Offset(4, 4),
                                    blurRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    offset: Offset(-4, -4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.only(
                                top: paddingTop + verticalPadding,
                                left: horizontalPadding,
                                right: horizontalPadding,
                                bottom: verticalPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: screenHeight * 0.01),
                                  // ... isi kontainer profil tetap sama
                                  Center(
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.025),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            offset: Offset(4, 4),
                                            blurRadius: 8,
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.white.withOpacity(0.6),
                                            offset: Offset(-4, -4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/profile.svg',
                                        width: profileImageSize,
                                        height: profileImageSize,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Center(
                                    child: Text(
                                      namaPengguna ?? 'Belum diatur',
                                      style: GoogleFonts.inter(
                                        fontSize: nameFontSize,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  _profileInfo(
                                      Icons.person,
                                      "Jenis Kelamin",
                                      jenisKelamin ?? 'Laki-laki',
                                      screenWidth,
                                      infoFontSize),
                                  _profileInfo(
                                      Icons.fitness_center,
                                      "Berat badan",
                                      "${beratBadan?.toStringAsFixed(1) ?? '0.0'} kg",
                                      screenWidth,
                                      infoFontSize),
                                  _profileInfo(
                                      Icons.wb_sunny,
                                      "Jam Bangun",
                                      jamBangun ?? 'Belum diatur',
                                      screenWidth,
                                      infoFontSize),
                                  _profileInfo(
                                      Icons.nightlight_round,
                                      "Jam Tidur",
                                      jamTidur ?? 'Belum diatur',
                                      screenWidth,
                                      infoFontSize),
                                  // Tambahkan jarak sebelum tombol
                                  SizedBox(height: screenHeight * 0.03),

                                  // Tombol edit profile
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _showEditProfile(context),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        elevation: 5,
                                        backgroundColor: Colors.white,
                                        shadowColor:
                                            Colors.black.withOpacity(0.2),
                                        padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.015,
                                        ),
                                        minimumSize: Size(
                                          screenWidth * 0.8,
                                          screenHeight * 0.05,
                                        ),
                                      ),
                                      child: Text(
                                        "Edit Profile",
                                        style: TextStyle(
                                          color: Color(0xFF2F2E41),
                                          fontWeight: FontWeight.w700,
                                          fontSize: titleFontSize,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Spacer bawah biar enggak mentok
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

  // Widget untuk informasi profil dengan parameter responsif
  Widget _profileInfo(IconData icon, String title, String value,
      double screenWidth, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: screenWidth * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: screenWidth * 0.05),
              SizedBox(width: screenWidth * 0.025),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel(); // Batalkan subscription saat widget dihapus
    super.dispose();
  }
}
