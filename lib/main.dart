// File: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Services dan Repositories
import 'package:hydrate/services/app_services.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:shared_preferences/shared_preferences.dart';

// UI Screens
import 'package:hydrate/presentation/screens/Pendaftaran/login_view.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/firstPage_view.dart';
import 'package:hydrate/presentation/screens/home_screen1.dart';
import 'package:hydrate/presentation/screens/statistic_screen.dart';
import 'package:hydrate/presentation/screens/profile_screen.dart';

// UI Utilities
import 'package:lottie/lottie.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';



void main() async {
  // 1. Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Inisialisasi semua service dan repository melalui AppServices
  await AppServices.initialize();

  // 4. Atur orientasi perangkat
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF00A6FB),
          selectionColor: Color(0xFF00A6FB),
          selectionHandleColor: Color(0xFF00A6FB),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AppServices.instance.firebaseAuth.authStateChanges(),
      builder: (context, authSnapshot) {
        // Tampilkan loading saat memeriksa status autentikasi
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          print("AuthWrapper: Memeriksa status autentikasi...");
          return const SplashScreenWidget();
        }

        // Jika user sudah login
         if (authSnapshot.hasData && authSnapshot.data != null) {
      final firebaseUser = authSnapshot.data!;
      print("AuthWrapper: User terautentikasi (UID: ${firebaseUser.uid}). Memanggil handleUserLoginInitialization...");

          // Cek apakah user sudah terdaftar di sistem lokal
          return FutureBuilder<bool>(
            future: AppServices.instance.penggunaRepository.handleUserLoginInitialization(firebaseUser),
            builder: (context, initSnapshot) {
              if (initSnapshot.connectionState == ConnectionState.waiting) {
                print("AuthWrapper: Memeriksa registrasi user...");
                return const SplashScreenWidget();
              }

              if (initSnapshot.hasError) {
                print("AuthWrapper: Error checking registration: ${initSnapshot.error}");
                return LoginView();
              }

              // Jika user sudah terdaftar, inisialisasi data
              if (initSnapshot.data == true) {
                return FutureBuilder<bool>(
                  future: _initializeUserData(firebaseUser),
                  builder: (context, initSnapshot) {
                    if (initSnapshot.connectionState == ConnectionState.waiting) {
                      print("AuthWrapper: Menginisialisasi data user...");
                      return const SplashScreenWidget();
                    }

                    if (initSnapshot.hasError || initSnapshot.data == false) {
                      print("AuthWrapper: Gagal inisialisasi data user: ${initSnapshot.error}");
                      return LoginView();
                    }

                    print("AuthWrapper: Inisialisasi berhasil, mengarahkan ke MainScreen");
                    return const MainScreen();
                  },
                );
              } else {
                // User belum terdaftar, arahkan ke halaman info produk
                print("AuthWrapper: User belum terdaftar, mengarahkan ke InfoProduct");
                return InfoProduct();
              }
            },
          );
        } else {
          // User belum login
          print("AuthWrapper: User tidak terautentikasi, mengarahkan ke InfoProduct");
          return InfoProduct();
        }
      },
    );
  }

  Future<bool> _checkUserRegistration(User firebaseUser) async {
  try {
    print("AuthWrapper/Helper: Memanggil handleUserLoginInitialization untuk UID: ${firebaseUser.uid}");
    // Panggil metode dari repository yang sudah di-inject melalui AppServices
    bool success = await AppServices.instance.penggunaRepository.handleUserLoginInitialization(firebaseUser);
    return success; // <-- Titik koma ditambahkan dan return value eksplisit
  } catch (e, s) {
    print("AuthWrapper/Helper: Error saat _checkUserRegistration (handleUserLoginInitialization): $e");
    print("Stacktrace: $s");
    return false; // Kembalikan false jika ada error selama inisialisasi
  }
}

  Future<bool> _initializeUserData(User firebaseUser) async {
    try {
      // Replace with your initialization method if it exists
      // return await AppServices.instance.penggunaRepository.handleUserLoginInitialization(firebaseUser);
      
      // Temporary implementation - replace with your actual method
      return true; // This should be replaced with actual initialization logic
    } catch (e) {
      print("Error initializing user data: $e");
      return false;
    }
  }
}

class SplashScreenWidget extends StatelessWidget {
  const SplashScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: Center(
        child: Lottie.asset(
          'assets/loading.json',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1; // Default ke tab Home
  final _eventBus = AppEventBus();

  // Keys untuk refresh halaman
  final GlobalKey<StatisticScreenState> _statisticsKey = GlobalKey<StatisticScreenState>();
  final GlobalKey<HomeScreensState> _homeKey = GlobalKey<HomeScreensState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("MainScreen: initState - Memulai sinkronisasi data awal");

    // Sinkronisasi data offline saat app dimulai
    _syncOfflineDataOnStartOrResume();

    // Subscribe ke event bus
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_all') {
        print("MainScreen: Event 'refresh_all' diterima");
        _refreshAllPages();
      }
    });
  }

  Future<void> _syncOfflineDataOnStartOrResume() async {
    try {
      if (AppServices.instance.firebaseAuth.currentUser != null) {
        print("MainScreen: Memulai sinkronisasi data offline...");
        
        // Replace with your sync method if it exists
        // await AppServices.instance.penggunaRepository.syncOfflineData();
        
        print("MainScreen: Sinkronisasi data offline selesai");
        // Refresh UI setelah sinkronisasi
        _refreshCurrentPage();
      } else {
        print("MainScreen: User tidak login, skip sinkronisasi");
      }
    } catch (e) {
      print("MainScreen: Error saat sinkronisasi data: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("MainScreen: AppLifecycleState changed to $state");
    
    if (state == AppLifecycleState.resumed) {
      // Refresh dan sinkronisasi saat app kembali aktif
      _refreshCurrentPage();
      _syncOfflineDataOnStartOrResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    print("MainScreen: dispose called");
    super.dispose();
  }

  void _refreshPage(int index) {
    print("MainScreen: Merefresh halaman indeks $index");
    switch (index) {
      case 0: // Statistik
        // _statisticsKey.currentState?.refreshData(); // Comment out if method doesn't exist
        _statisticsKey.currentState?.refresh(); // Use refresh() method instead
        break;
      case 1: // Home
        // _homeKey.currentState?.refreshData(); // Comment out if method doesn't exist  
        _homeKey.currentState?.refresh(); // Use refresh() method instead
        break;
      case 2: // Profil
        // _profileKey.currentState?.refreshData(); // Comment out if method doesn't exist
        _profileKey.currentState?.refresh(); // Use refresh() method instead
        break;
    }
  }

  void _refreshAllPages() {
    print("MainScreen: Merefresh semua halaman");
    _refreshPage(0);
    _refreshPage(1);
    _refreshPage(2);
  }

  void _refreshCurrentPage() {
    _refreshPage(_selectedIndex);
  }

  void _handlePageChanged(int index) {
    // Jika tap halaman yang sama, refresh halaman tersebut
    if (_selectedIndex == index && ModalRoute.of(context)?.isCurrent == true) {
      print("MainScreen: Tab yang sama diklik lagi, refresh halaman");
      _refreshCurrentPage();
      return;
    }

    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
      print("MainScreen: Pindah ke tab $index");
      _refreshCurrentPage();
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 1) {
      if (mounted) {
        setState(() => _selectedIndex = 1);
      }
      return false;
    }
    return await _showExitConfirmationDialog();
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Keluar Aplikasi', 
                     style: TextStyle(fontWeight: FontWeight.bold))
              ],
            ),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
              style: TextStyle(fontSize: 16)
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                  SystemNavigator.pop();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StatisticScreen(key: _statisticsKey),
      HomeScreens(key: _homeKey),
      ProfileScreen(
        key: _profileKey,
        onProfileUpdated: () {
          // _eventBus.fire(AppEvent('refresh_all', data: null)); // Comment out if AppEvent doesn't exist
          _eventBus.fire('refresh_all'); // Use simple string event
        },
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          height: 60.0,
          items: const <Widget>[
            Image(
              image: AssetImage('assets/images/navigasi/stats.png'),
              width: 25,
              height: 25,
              color: Colors.white,
            ),
            Image(
              image: AssetImage('assets/images/navigasi/home.png'),
              width: 25,
              height: 25,
              color: Colors.white,
            ),
            Image(
              image: AssetImage('assets/images/navigasi/user.png'),
              width: 25,
              height: 25,
              color: Colors.white,
            ),
          ],
          color: Colors.blue.shade600,
          buttonBackgroundColor: Colors.blue.shade700,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 400),
          onTap: _handlePageChanged,
          letIndexChange: (index) => true,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
    );
  }
}