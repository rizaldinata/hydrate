import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/screens/registration/first_page_view.dart';
import 'package:hydrate/presentation/screens/home/home_screen.dart';
import 'package:hydrate/presentation/screens/profile/profile_screen.dart';
import 'package:hydrate/presentation/screens/statistic/statistic_page_screen.dart';
import 'dart:async';

import 'package:lottie/lottie.dart';

import 'package:provider/provider.dart';

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
        child:
            const MyApp(), // isPenggunaTerdaftarFuture akan dihandle di dalam MyApp
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF00A6FB),
          selectionColor: const Color(0xFF00A6FB).withValues(alpha: 0.5),
          selectionHandleColor: const Color(0xFF00A6FB),
        ),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00A6FB),
            primary: const Color(0xFF00A6FB)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
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
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  final _eventBus = AppEventBus();

  final GlobalKey<StatisticPageScreenState> _statisticsKey = GlobalKey();
  final GlobalKey<HomeScreensState> _homeKey = GlobalKey();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();

  StreamSubscription? _eventSubscription;
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
      } else if (event.type == 'refresh_all_pages') {
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
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    _appEventBusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentPage();
    }
  }

  void _refreshPage(int index) {
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

  void _refreshCurrentPage() {
    _refreshPage(_selectedIndex);
  }

  void _handlePageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _refreshPage(index);
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 1) {
      setState(() {
        _selectedIndex = 1;
      });
      _refreshPage(1);
      return false;
    }
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
            Text('Keluar Aplikasi',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StatisticPageScreen(key: _statisticsKey),
      HomeScreens(key: _homeKey),
      ProfileScreen(
        key: _profileKey,
        onProfileUpdated: () {
          _eventBus.fire('refresh_all_pages');
        },
      ),
    ];

    // ignore: deprecated_member_use
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
          onTap: _handlePageChanged,
        ),
        body: IndexedStack(
          // IndexedStack mempertahankan state halaman
          index: _selectedIndex,
          children: pages,
        ),
      ),
    );
  }
}
