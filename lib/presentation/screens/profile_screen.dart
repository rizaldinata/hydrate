import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import 'package:hydrate/presentation/screens/edit_profile.dart';
import 'package:hydrate/core/utils/session_manager.dart';
// Import event bus
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
  final ProfilPenggunaController _profilPenggunaController = ProfilPenggunaController();
  
  // Stream subscription untuk event bus
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();

  // function editprofile
  Future<void> _showEditProfile(BuildContext context) async {
    // final session = SessionManager();
    // final userId = await session.getUserId();

    // if (userId == null) return;

    // final pengguna = await PenggunaRepository().getPenggunaById(userId);
    // if (pengguna == null) return;

    // await showDialog<bool>(
    //   context: context,
    //   builder: (context) => EditProfile(
    //     userId: userId,
    //     initialNama: pengguna.nama,
    //     initialJenisKelamin: jenisKelamin ?? 'Male',
    //     initialBeratBadan: beratBadan ?? 60.0,
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
        widget.onProfileUpdated?.call();  // Callback untuk memberitahu parent widget
        
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
        // final pengguna = await PenggunaRepository().getPenggunaById((userId));
        // final profil =
        //     await _profilPenggunaController.getProfilPengguna((userId));
        setState(() => idPengguna = userId);
        
        final pengguna = await PenggunaRepository().getPenggunaById(userId);
        final profil = await _profilPenggunaController.getProfilPengguna(userId);

        if (pengguna != null) {
          setState(() {
            namaPengguna = pengguna.nama;
            // if (profil.jenisKelamin == "Female" || profil.jenisKelamin == "Perempuan") {
            //   jenisKelamin = "Perempuan";
            // } else {
            //   jenisKelamin = "Laki-laki";
            // }
            // jenisKelamin = profil.jenisKelamin == "Laki-laki" || profil.jenisKelamin == "Perempuan" ? profil.jenisKelamin : "Laki-laki";
          });
        }
        
        if (profil != null) {
          setState(() {
            jenisKelamin = profil.jenisKelamin == "Laki-laki" || profil.jenisKelamin == "Perempuan" 
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : Stack(
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
                                  right: screenWidth * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Foto Profil
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: screenHeight * 0.02, bottom: screenHeight * 0.015),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/images/profile.svg', 
                                        width: screenWidth * 0.2,
                                      ),
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
                                  _profileInfo(Icons.fitness_center, "Berat badan", "${beratBadan?.toInt() ?? '0'} kg"),
                                  _profileInfo(Icons.wb_sunny, "Jam Bangun", jamBangun ?? 'Belum diatur'),
                                  _profileInfo(Icons.nightlight_round, "Jam Tidur", jamTidur ?? 'Belum diatur'),

                                  SizedBox(height: screenHeight * 0.01),

                                  // Tombol Edit Profile
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: ElevatedButton(
                                        onPressed: () => _showEditProfile(context),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
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
                          // Widget lain bisa ditambahkan di sini
                        ],
                      ),
                    ),
                  ],
                ),
      // Tambahkan refresh indicator
      floatingActionButton: FloatingActionButton(
        onPressed: refresh,
        mini: true,
        backgroundColor: Colors.white,
        child: const Icon(Icons.refresh, color: Color(0xFF00A6FB)),
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
  
  @override
  void dispose() {
    _eventSubscription?.cancel(); // Batalkan subscription saat widget dihapus
    super.dispose();
  }
}
