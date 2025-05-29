import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/screens/registration/firstPage_view.dart';
import 'package:hydrate/presentation/screens/home/home_screen.dart';
import 'package:hydrate/presentation/screens/profile/profile_screen.dart';
import 'package:hydrate/presentation/screens/statistic/statistic_page_screen.dart';
import 'dart:async';

// Lottie untuk animasi loading
import 'package:lottie/lottie.dart';

// Import Provider package
import 'package:provider/provider.dart';

// Import Controllers
import 'package:hydrate/presentation/controllers/hydration_stats_controller.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart'; 

import 'package:intl/date_symbol_data_local.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null); 

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(
      // Membungkus MyApp dengan MultiProvider
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HydrationStatsController()),
          ChangeNotifierProvider(create: (_) => TargetHidrasiController()),
        ],
        child: const MyApp(), // isPenggunaTerdaftarFuture akan dihandle di dalam MyApp
      ),
    );
  });
}

Future<bool> _checkInitialUserStatus() async {
  try {
    final penggunaRepository = PenggunaRepository();
    bool isRegistered = await penggunaRepository.isPenggunaTerdaftar();
    return isRegistered;
  } catch (e) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF00A6FB),
          selectionColor: const Color(0xFF00A6FB).withOpacity(0.5),
          selectionHandleColor: const Color(0xFF00A6FB),
        ),
        // Pertimbangkan untuk memindahkan warna utama ke colorScheme
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00A6FB),
            primary: const Color(0xFF00A6FB)
        ),
        useMaterial3: true, // Dianjurkan untuk project baru
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        // Panggil _checkInitialUserStatus di sini
        future: _checkInitialUserStatus(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color(0xFFE8F7FF),
              body: Center(
                child: Lottie.asset('assets/loading.json',
                    width: 200, height: 200),
              ),
            );
          }
          if (snapshot.hasError) {
            return InfoProduct();
          }

          bool isRegistered = snapshot.data ?? false;
          return isRegistered ? const MainScreen() : InfoProduct();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key); // Tambahkan Key
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  final _eventBus = AppEventBus();

  // Key tidak harus GlobalKey<NamaStateWidget> jika hanya untuk refresh umum
  // Cukup GlobalKey() jika metode refresh diimplementasikan secara konsisten
  final GlobalKey<StatisticPageScreenState> _statisticsKey = GlobalKey();
  final GlobalKey<HomeScreensState> _homeKey = GlobalKey();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();

  StreamSubscription? _eventSubscription; // Ini sepertinya tidak digunakan, bisa dihapus jika _appEventBusSubscription cukup
  StreamSubscription<AppEvent>? _appEventBusSubscription;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appEventBusSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_statistics_page') {
          _refreshPage(0);
      } else if (event.type == 'refresh_home_page') {
          _refreshPage(1);
      } else if (event.type == 'refresh_profile_page') {
          _refreshPage(2);
          _refreshPage(0);
          _refreshPage(1);
          _refreshPage(2);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshPage(_selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    print("[INFO] MainScreen dispose: Observer dilepas, subscription dibatalkan.");
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel(); // Batalkan jika masih ada
    _appEventBusSubscription?.cancel(); // Jangan lupa batalkan subscription ini
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state); // Panggil super
    print("[LIFECYCLE] App lifecycle state berubah: $state");
    if (state == AppLifecycleState.resumed) {
      print("[LIFECYCLE] Aplikasi dibuka kembali (resumed). Merefresh halaman saat ini.");
      _refreshCurrentPage();
    }
  }

  void _refreshPage(int index) {
    print("[REFRESH] Mencoba merefresh halaman dengan index: $index");
    switch (index) {
      case 0:
        _statisticsKey.currentState?.refresh();
        print("[REFRESH] Perintah refresh untuk Statistik dikirim.");
        break;
      case 1:
        _homeKey.currentState?.refresh();
        print("[REFRESH] Perintah refresh untuk Home dikirim.");
        break;
      case 2:
        _profileKey.currentState?.refresh();
        print("[REFRESH] Perintah refresh untuk Profile dikirim.");
        break;
    }
  }

  void _refreshCurrentPage() {
    print("[REFRESH] Merefresh halaman saat ini dengan index: $_selectedIndex");
    _refreshPage(_selectedIndex);
  }

  void _handlePageChanged(int index) {
    print("[NAVIGATION] Halaman diubah ke index: $index. Index sebelumnya: $_selectedIndex");
    // Tidak perlu refresh jika index sama, karena bottom nav bar tidak akan memanggil onTap jika index tidak berubah
    // Namun, jika ada cara lain _selectedIndex berubah tanpa onTap (jarang terjadi), maka kondisi ini relevan.
    // if (_selectedIndex == index) {
    //   print("[NAVIGATION] Index sama, merefresh halaman saat ini.");
    //   _refreshCurrentPage();
    //   return;
    // }

    setState(() {
      _selectedIndex = index;
    });
    print("[NAVIGATION] State diubah, memanggil refresh untuk halaman baru yang dipilih.");
    // Refresh halaman yang baru dipilih.
    // Ini penting jika halaman tidak mempertahankan state atau perlu data baru setiap kali aktif.
    _refreshPage(index);
  }

  Future<bool> _onWillPop() async {
    print("[NAVIGATION] Tombol kembali ditekan. Index saat ini: $_selectedIndex");
    if (_selectedIndex != 1) {
      setState(() {
        _selectedIndex = 1;
      });
      _refreshPage(1); // Refresh halaman Home setelah kembali
      print("[NAVIGATION] Kembali ke halaman Home (index 1).");
      return false;
    }
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
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop(); // Tutup aplikasi
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("[BUILD] Membangun MainScreen. Index saat ini: $_selectedIndex");
    
    // Inisialisasi _pages di dalam build atau pastikan GlobalKey sudah terpasang dengan benar
    // jika halaman di-cache oleh IndexedStack.
    final List<Widget> pages = [
      StatisticPageScreen(key: _statisticsKey), // Riwayat Hidrasi / Statistik
      HomeScreens(key: _homeKey),
      ProfileScreen(
        key: _profileKey,
        onProfileUpdated: () {
          print("[EVENT] Profile diperbarui. Mengirim event 'refresh_all_pages'.");
          // Mengirim tipe event sebagai String, sesuai dengan error yang dilaporkan
          _eventBus.fire('refresh_all_pages'); 
        },
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // extendBody: true,
        backgroundColor: const Color(0xFFE8F7FF),
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: const Color(0xFFE8F7FF), //warna backgruond navbar
          color: Colors.blue, // Warna utama CurvedNavigationBar
          buttonBackgroundColor: Colors.blue, // Warna tombol aktif
          height: 75.0,
          items: const <Widget>[
            Image(image: AssetImage('assets/images/navigasi/stats.png'), width: 25, height: 25, color: Colors.white),
            Image(image: AssetImage('assets/images/navigasi/home.png'), width: 25, height: 25, color: Colors.white),
            Image(image: AssetImage('assets/images/navigasi/user.png'), width: 25, height: 25, color: Colors.white),
          ],
          onTap: _handlePageChanged,
        ),
        body: IndexedStack( // IndexedStack mempertahankan state halaman
          index: _selectedIndex,
          children: pages,
        ),
      ),
    );
  }
}