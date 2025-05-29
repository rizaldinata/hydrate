import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/controllers/profil_pengguna_controller.dart';
import 'package:hydrate/presentation/screens/registration/firstPage_view.dart';
import 'package:hydrate/presentation/screens/profile/edit_profile.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:hydrate/services/notification_settings_service.dart';

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
  bool _areNotificationsEnabled = false;

  // Instance NotificationSettingsService
  final NotificationSettingsService _notificationSettingsService =
      NotificationSettingsService();

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

  // Function untuk logout
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Konfirmasi Logout',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBackgroundPermissionGuidanceDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Pengguna harus memilih salah satu aksi
      builder: (BuildContext dialogContext) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            double dialogWidth;
            if (screenWidth < 600) {
              dialogWidth = screenWidth * 0.9;
            } else if (screenWidth < 900) {
              dialogWidth = screenWidth * 0.7;
            } else {
              dialogWidth = 500;
            }

            final maxHeight = screenHeight * (isLandscape ? 0.8 : 0.7);

            return Center(
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minWidth: 280,
                  maxWidth: 600,
                ),
                child: AlertDialog(
                  titlePadding: EdgeInsets.all(16),
                  contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Row(
                    children: [
                      Icon(
                        Icons.settings_backup_restore,
                        color: Theme.of(context).primaryColor,
                        size: screenWidth < 600 ? 20 : 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Optimalkan Pengingat',
                          style: TextStyle(
                            fontSize: screenWidth < 600 ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Agar pengingat minum Anda lebih andal dan tidak terganggu oleh sistem HP:',
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 14 : 16,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.05),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInstructionItem(
                                    context,
                                    '1.',
                                    'Pastikan optimasi baterai untuk Hydrate dimatikan (pilih "Tanpa Batasan").',
                                    screenWidth,
                                  ),
                                  SizedBox(height: 8),
                                  _buildInstructionItem(
                                    context,
                                    '2.',
                                    'Jika tersedia, izinkan "Mulai Otomatis" (Autostart) untuk Hydrate.',
                                    screenWidth,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sentuh "Buka Pengaturan" untuk diarahkan ke info aplikasi Hydrate.',
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 13 : 14,
                              fontStyle: FontStyle.italic,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    if (screenWidth < 600 && !isLandscape)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              AppSettings.openAppSettings();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Buka Pengaturan',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Nanti Saja',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text(
                              'Nanti Saja',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 13 : 14,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              AppSettings.openAppSettings();
                            },
                            child: Text(
                              'Buka Pengaturan',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 13 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstructionItem(
      BuildContext context, String number, String text, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 600 ? 13 : 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: screenWidth < 600 ? 13 : 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2AD1D1)),
          ),
        ),
      );

      final session = SessionManager();
      await session.clearSession();

      Navigator.of(context).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => InfoProduct()),
        (Route<dynamic> route) => false,
      );

      _showSnackBar("Berhasil logout");
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar("Gagal logout: ${e.toString()}");
    }
  }

  void _showRatingDialog() {
    int selectedRating = 0;
    String reviewText = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Beri Rating',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bagaimana pengalaman Anda menggunakan aplikasi ini?',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan Anda (opsional)',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF2AD1D1)),
                      ),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      reviewText = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2AD1D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: selectedRating > 0
                      ? () {
                          Navigator.of(context).pop();
                          _submitRating(selectedRating, reviewText);
                        }
                      : null,
                  child: Text(
                    'Kirim',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitRating(int rating, String review) {
    print("Rating: $rating, Review: $review");
    _showSnackBar("Terima kasih atas rating Anda! ⭐");
  }

  void refresh() {
    print("Refreshing Profile data...");
    _loadUserData();
    _loadNotificationPreference();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationPreference();

    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_profile' || event.type == 'refresh_all') {
        refresh();
      }
    });
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _areNotificationsEnabled =
            prefs.getBool('notifications_enabled') ?? false;
      });
    }
  }

  Future<void> _onNotificationToggleChanged(bool newValue) async {
    setState(() {
      _areNotificationsEnabled = newValue;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', newValue);

    if (newValue) {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        isAllowed =
            await NotificationController.requestNotificationPermission();
      }

      if (isAllowed) {
        int currentIntervalSeconds =
            await _notificationSettingsService.getNotificationInterval();

        await NotificationController.cancelScheduledNotifications();
        await NotificationController.schedulePeriodicHydrationNotification(
            intervalInSeconds: currentIntervalSeconds);
        _showSnackBar(
            "Pengingat notifikasi diaktifkan setiap ${currentIntervalSeconds ~/ 60} menit.");

        if (mounted) {
          _showBackgroundPermissionGuidanceDialog();
        }
      } else {
        _showSnackBar(
            "Izin notifikasi ditolak. Tidak dapat mengaktifkan pengingat.");
        setState(() {
          _areNotificationsEnabled = false;
        });
        await prefs.setBool('notifications_enabled', false);
      }
    } else {
      await NotificationController.cancelScheduledNotifications();
      _showSnackBar("Pengingat notifikasi dinonaktifkan.");
    }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double paddingTop = MediaQuery.of(context).padding.top;

    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;

    final double titleFontSize = screenWidth * 0.04;
    final double nameFontSize = screenWidth * 0.045;
    final double infoFontSize = screenWidth * 0.038;
    final double profileImageSize = screenWidth * 0.2;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  // Ini adalah perubahan utama: Membungkus Column utama dengan SingleChildScrollView
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Bagian profil pengguna (tidak lagi di dalam Flexible/SingleChildScrollView terpisah)
                      Container(
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
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.025),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: Offset(4, 4),
                                      blurRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.6),
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
                                overflow: TextOverflow.ellipsis,
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
                                "${beratBadan?.toInt().toString() ?? '0'} kg",
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
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: screenWidth * 0.02,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _onNotificationToggleChanged(
                                        !_areNotificationsEnabled);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: ElevatedButton(
                                onPressed: () => _showEditProfile(context),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 5,
                                  backgroundColor: Colors.white,
                                  shadowColor: Colors.black.withOpacity(0.2),
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
                            SizedBox(height: screenHeight * 0.01),
                          ],
                        ),
                      ),

                      // Bagian navigasi di bawah background biru hijau
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2AD1D1).withOpacity(
                                        0.1), // Warna diubah agar konsisten
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons
                                        .settings_applications, // Icon diubah agar lebih relevan
                                    color: Color(0xFF2AD1D1), // Warna diubah
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  'Pengaturan Notifikasi', // Judul diubah
                                  style: GoogleFonts.inter(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2F2E41),
                                  ),
                                ),
                                subtitle: Text(
                                  'Aktifkan perizinan notifikasi Anda!', // Subtitle diubah
                                  style: GoogleFonts.inter(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Switch(
                                  value: _areNotificationsEnabled,
                                  onChanged: _onNotificationToggleChanged,
                                  activeColor: Colors.white,
                                  activeTrackColor:
                                      Colors.lightBlueAccent.withOpacity(0.5),
                                  inactiveThumbColor: Colors.blueGrey,
                                  inactiveTrackColor:
                                      Colors.white.withOpacity(0.2),
                                ),
                                // onTap: () {
                                //   // Aksi diubah untuk panduan izin
                                //   _showBackgroundPermissionGuidanceDialog();
                                // },
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(
                                        0.1), // Warna disesuaikan dengan icon
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.star, // Icon disesuaikan
                                    color: Colors.amber, // Warna disesuaikan
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  'Rating & Ulasan',
                                  style: GoogleFonts.inter(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2F2E41),
                                  ),
                                ),
                                subtitle: Text(
                                  'Beri rating dan ulasan',
                                  style: GoogleFonts.inter(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                                onTap: _showRatingDialog,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  'Logout Akun', // Judul disesuaikan dari Hapus Akun ke Logout
                                  style: GoogleFonts.inter(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2F2E41),
                                  ),
                                ),
                                subtitle: Text(
                                  'Keluar dari sesi aplikasi ini', // Subtitle disesuaikan
                                  style: GoogleFonts.inter(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                                onTap: _showLogoutDialog,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

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
    _eventSubscription?.cancel();
    super.dispose();
  }
}
