import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/firstPage_view.dart';
import 'package:hydrate/presentation/screens/home_screen1.dart';
import 'package:hydrate/presentation/screens/profile_screen.dart';
import 'package:hydrate/presentation/screens/statistic_page_screen.dart';
import 'dart:async';

// Lottie untuk animasi loading
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool penggunaSudahTerdaftar = false;
  try {
    final penggunaRepository = PenggunaRepository();
    penggunaSudahTerdaftar = await penggunaRepository.isPenggunaTerdaftar();
    print("[DEBUG] Proses pengecekan pengguna di main selesai. Status: $penggunaSudahTerdaftar");
  } catch (e) {
    print("[ERROR] Error saat pengecekan pengguna di main(): $e");
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp(isPenggunaAwalTerdaftar: penggunaSudahTerdaftar));
  });
}

class MyApp extends StatelessWidget {
  final bool isPenggunaAwalTerdaftar;

  const MyApp({Key? key, required this.isPenggunaAwalTerdaftar}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFF00A6FB), // Warna kursor
          selectionColor:
              Color(0xFF00A6FB).withOpacity(0.5), // Warna seleksi teks
          selectionHandleColor: Color(0xFF00A6FB), // Warna titik pemilih teks
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: PenggunaRepository().isPenggunaTerdaftar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color(0xFFE8F7FF),
              body: Center(
                // child: CircularProgressIndicator()
                child: Lottie.asset('assets/loading.json',
                    width: 200, height: 200),
              ),
            );
          }
          return snapshot.data == true ? MainScreen() : StatisticPageScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1; // Default ke Home
  final _eventBus = AppEventBus(); // Pastikan AppEventBus sudah didefinisikan

  // Keys untuk memaksa refresh pada widget
  // Pastikan StatisticScreenState, HomeScreensState, dan ProfileScreenState ada dan memiliki metode refresh()
  final GlobalKey<StatisticPageScreenState> _statisticsKey = GlobalKey();
  final GlobalKey<HomeScreensState> _homeKey = GlobalKey();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();

  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("[INFO] MainScreen initState: Observer ditambahkan.");

    _eventSubscription = _eventBus.stream.listen((event) {
    });
  }

  @override
  void dispose() {
    print("[INFO] MainScreen dispose: Observer dilepas, subscription dibatalkan.");
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("[LIFECYCLE] App lifecycle state berubah: $state");
    if (state == AppLifecycleState.resumed) {
      print("[LIFECYCLE] Aplikasi dibuka kembali (resumed). Merefresh halaman saat ini.");
      _refreshCurrentPage();
    }
  }

  void _refreshAllPages() {
    print("[REFRESH] Memulai _refreshAllPages.");
    _refreshPage(0); // Statistics
    _refreshPage(1); // Home
    _refreshPage(2); // Profile
  }

  void _refreshPage(int index) {
    print("[REFRESH] Mencoba merefresh halaman dengan index: $index");
    switch (index) {
      case 0:
        if (_statisticsKey.currentState != null) {
          _statisticsKey.currentState!.refresh();
          print("[REFRESH] Halaman Statistik direfresh.");
        } else {
          print("[REFRESH] Gagal merefresh Statistik: currentState is null.");
        }
        break;
      case 1:
        if (_homeKey.currentState != null) {
          _homeKey.currentState!.refresh();
          print("[REFRESH] Halaman Home direfresh.");
        } else {
          print("[REFRESH] Gagal merefresh Home: currentState is null.");
        }
        break;
      case 2:
        if (_profileKey.currentState != null) {
          _profileKey.currentState!.refresh();
          print("[REFRESH] Halaman Profile direfresh.");
        } else {
          print("[REFRESH] Gagal merefresh Profile: currentState is null.");
        }
        break;
    }
  }

  void _refreshCurrentPage() {
    print("[REFRESH] Merefresh halaman saat ini dengan index: $_selectedIndex");
    _refreshPage(_selectedIndex);
  }

  void _handlePageChanged(int index) {
    print("[NAVIGATION] Halaman diubah ke index: $index. Index sebelumnya: $_selectedIndex");
    if (_selectedIndex == index) {
      print("[NAVIGATION] Index sama, merefresh halaman saat ini.");
      _refreshCurrentPage();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
    print("[NAVIGATION] State diubah, merefresh halaman baru yang dipilih.");
    _refreshCurrentPage(); // Refresh halaman yang baru dipilih
  }

  Future<bool> _onWillPop() async {
    print("[NAVIGATION] Tombol kembali ditekan. Index saat ini: $_selectedIndex");
    if (_selectedIndex != 1) { // Jika bukan di halaman Home (index 1)
      setState(() => _selectedIndex = 1); // Kembali ke halaman Home
      print("[NAVIGATION] Kembali ke halaman Home (index 1).");
      _refreshCurrentPage(); // Refresh halaman Home setelah kembali
      return false; // Jangan keluar aplikasi
    }
    // Jika sudah di halaman Home, tampilkan dialog konfirmasi keluar
    print("[NAVIGATION] Sudah di halaman Home. Menampilkan dialog konfirmasi keluar.");
    return await _showExitConfirmationDialog() ?? false;
  }

  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Jangan keluar
            style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Konfirmasi keluar
              SystemNavigator.pop(); // Tutup aplikasi
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("[BUILD] Membangun MainScreen. Index saat ini: $_selectedIndex");
    // Pastikan semua halaman (StatisticScreen, HomeScreens, ProfileScreen) sudah ada
    // dan menerima GlobalKey serta memiliki metode refresh() jika diperlukan.
    final List<Widget> _pages = [
      StatisticPageScreen(key: _statisticsKey),
      HomeScreens(key: _homeKey),
      ProfileScreen(
        key: _profileKey,
        onProfileUpdated: () {
          print("[EVENT] Profile diperbarui. Mengirim event 'refresh_all'.");
          // Pastikan AppEventBus().fire() mengirim Map atau object yang dikenali oleh listener
        },
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: const Color(0xFFE8F7FF), // Warna background area di belakang bar
          color: Colors.blue, // Warna CurvedNavigationBar itu sendiri
          buttonBackgroundColor: Colors.blue, // Warna tombol aktif (jika ada efek khusus)
          height: 60.0, // Sesuaikan tinggi jika perlu
          items: const <Widget>[
            Image(image: AssetImage('assets/images/navigasi/stats.png'), width: 25, height: 25, color: Colors.white),
            Image(image: AssetImage('assets/images/navigasi/home.png'), width: 25, height: 25, color: Colors.white),
            Image(image: AssetImage('assets/images/navigasi/user.png'), width: 25, height: 25, color: Colors.white),
          ],
          onTap: _handlePageChanged,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
    );
  }
}

