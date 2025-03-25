import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/screens/home_screen1.dart';
import 'package:hydrate/presentation/screens/info_product_view.dart';
import 'package:hydrate/presentation/screens/profile_screen.dart';
import 'package:hydrate/presentation/screens/statistic_screen.dart';
import 'dart:async';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: PenggunaRepository().isPenggunaTerdaftar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true ? MainScreen() : InfoProduct();
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
  int _selectedIndex = 1;
  final _eventBus = AppEventBus();
  
  // Keys untuk memaksa refresh pada widget
  final GlobalKey<StatisticScreenState> _statisticsKey = GlobalKey();
  final GlobalKey<HomeScreensState> _homeKey = GlobalKey();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();
  
  // Stream subscription untuk event bus
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Subscribe ke event bus untuk refresh data
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_all') {
        _refreshAllPages();
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh semua halaman ketika aplikasi dibuka kembali
      _refreshCurrentPage();
    }
  }

  // Metode untuk refresh semua halaman
  void _refreshAllPages() {
    _refreshPage(0);
    _refreshPage(1);
    _refreshPage(2);
  }
  
  // Metode untuk menandai bahwa halaman tertentu perlu direfresh
  void _refreshPage(int index) {
    switch (index) {
      case 0:
        if (_statisticsKey.currentState != null) {
          _statisticsKey.currentState!.refresh();
        }
        break;
      case 1:
        if (_homeKey.currentState != null) {
          _homeKey.currentState!.refresh();
        }
        break;
      case 2:
        if (_profileKey.currentState != null) {
          _profileKey.currentState!.refresh();
        }
        break;
    }
  }
  
  // Metode untuk refresh halaman yang sedang aktif
  void _refreshCurrentPage() {
    _refreshPage(_selectedIndex);
  }
  
  // Handler untuk perubahan halaman
  void _handlePageChanged(int index) {
    // Jika memilih halaman yang sudah dipilih, refresh halaman tersebut
    if (_selectedIndex == index) {
      _refreshCurrentPage();
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Refresh halaman yang baru dipilih untuk mendapatkan data terbaru
    _refreshCurrentPage();
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 1) {
      setState(() => _selectedIndex = 1);
      return false;
    }
    return await _showExitConfirmation();
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Keluar Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?',
                style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white),
                  child: const Text('Batal')),
              ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      overlayColor: MaterialStateProperty.all(
                          Colors.red.withOpacity(0.2))),
                  child: const Text('Keluar',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 227, 242, 253),
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: const Color.fromARGB(255, 227, 242, 253),
          color: Colors.blue,
          onTap: (index) {
            _handlePageChanged(index);
          },
          items: const [
            Image(
                image: AssetImage('assets/images/navigasi/stats.png'),
                width: 25,
                height: 25,
                color: Colors.white),
            Image(
                image: AssetImage('assets/images/navigasi/home.png'),
                width: 25,
                height: 25,
                color: Colors.white),
            Image(
                image: AssetImage('assets/images/navigasi/user.png'),
                width: 25,
                height: 25,
                color: Colors.white),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            StatisticScreen(key: _statisticsKey),
            HomeScreens(key: _homeKey),
            ProfileScreen(key: _profileKey, onProfileUpdated: () {
              // Ketika profile diperbarui, refresh semua halaman
              _eventBus.fire('refresh_all');
            }),
          ],
        ),
      ),
    );
  }
}