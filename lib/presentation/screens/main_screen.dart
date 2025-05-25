import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';

// Import halaman-halaman Anda
import 'package:hydrate/presentation/screens/statistic_screen.dart';
import 'package:hydrate/presentation/screens/home_screen.dart';
import 'package:hydrate/presentation/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1; // Default ke tab Home
  final _eventBus = AppEventBus();

  // Keys untuk refresh halaman. Ini adalah pola yang bagus dan bisa dipertahankan.
  final GlobalKey<StatisticScreenState> _statisticsKey = GlobalKey<StatisticScreenState>();
  final GlobalKey<HomeScreensState> _homeKey = GlobalKey<HomeScreensState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("MainScreen: initState - Memulai sinkronisasi data awal");

    // Lakukan sinkronisasi saat halaman pertama kali dimuat
    // Gunakan Future.microtask agar context tersedia
    Future.microtask(() => _syncOfflineData());

    // Subscribe ke event bus untuk refresh
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event == 'refresh_all') {
        print("MainScreen: Event 'refresh_all' diterima");
        _refreshAllPages();
      }
    });
  }
  
  // FUNGSI BARU: Menggunakan Provider untuk sinkronisasi data
  Future<void> _syncOfflineData() async {
    // Dapatkan PenggunaRepository dari Provider. Inilah cara baru kita mengaksesnya.
    final penggunaRepo = context.read<PenggunaRepository>();
    
    try {
      if (penggunaRepo.currentUser != null) {
        print("MainScreen: Memulai sinkronisasi data offline...");
        await penggunaRepo.syncOfflineData();
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
      // Sinkronisasi data saat aplikasi kembali aktif dari background
      _syncOfflineData();
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
    // Logika refresh dengan GlobalKey sudah benar.
    switch (index) {
      case 0:
        _statisticsKey.currentState?.refresh();
        break;
      case 1:
        _homeKey.currentState?.refresh();
        break;
      case 2:
        _profileKey.currentState?.refresh();
        break;
    }
  }

  void _refreshAllPages() {
    print("MainScreen: Merefresh semua halaman");
    for (int i = 0; i < 3; i++) {
      _refreshPage(i);
    }
  }

  void _refreshCurrentPage() {
    _refreshPage(_selectedIndex);
  }

  void _handlePageChanged(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
      print("MainScreen: Pindah ke tab $index");
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 1) {
      if (mounted) {
        // Kembali ke halaman home (indeks 1) jika tidak sedang di home
        setState(() => _selectedIndex = 1);
      }
      return false; // Mencegah aplikasi keluar
    }
    // Jika sudah di home, tampilkan dialog konfirmasi keluar
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
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?',
                style: TextStyle(fontSize: 16)),
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
                  // Jangan panggil pop di sini jika ingin menutup aplikasi
                  SystemNavigator.pop(); 
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StatisticScreen(key: _statisticsKey),
      HomeScreenProvider(key: _homeKey),
      ProfileScreenProvider(
        key: _profileKey,
        onProfileUpdated: () {
          _eventBus.fire('refresh_all');
        },
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // backgroundColor tidak perlu di sini karena sudah di-set di tema MaterialApp
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          height: 60.0,
          items: <Widget>[
            Image.asset('assets/images/navigasi/stats.png', width: 25, height: 25, color: Colors.white),
            Image.asset('assets/images/navigasi/home.png', width: 25, height: 25, color: Colors.white),
            Image.asset('assets/images/navigasi/user.png', width: 25, height: 25, color: Colors.white),
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