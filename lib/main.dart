import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrate/presentation/screens/home_screen1.dart';
import 'package:hydrate/presentation/screens/info_product_view.dart';
import 'package:hydrate/presentation/screens/profile_screen.dart';
import 'package:hydrate/presentation/screens/statistic_screen.dart';
// import 'package:hydrate/presentation/widgets/circular.dart';
// import 'package:hydrate/presentation/screens/coba_air.dart';
// // import 'package:hydrate/view/info_product_view.dart';
// import 'package:hydrate/presentation/screens/home_screen.dart';
// import 'package:hydrate/presentation/screens/home_screen1.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]).then((_) {
      runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(),
      debugShowCheckedModeBanner: false,
      home: InfoProduct(),
      // home:  StatisticScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String name;
  final int penggunaId;
  const MainScreen({super.key, required this.name, required this.penggunaId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default halaman utama (Home)

  // Data yang harus diteruskan ke HomeScreens
  // final String _userName = ;
  // final int _penggunaId = ;

  Future<bool> _onWillPop() async {
    // Menampilkan konfirmasi keluar hanya di homescreen
    if (_selectedIndex != 1) {
      setState(() {
        _selectedIndex = 1; // Kembali ke HomeScreen jika bukan di halaman Home
      });
      return false; // Mencegah keluar dari aplikasi
    } else {
      return await _showExitConfirmation(); // Menampilkan konfirmasi keluar saat di halaman Home
    }
  }

  // Future<bool> _onWillPop() async {
  //   // Menampilkan konfirmasi keluar di setiap halaman
  //   return await _showExitConfirmation();
  // }

  Future<bool> _showExitConfirmation() async {
    //Styling konfirmasi keluar di sini
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Text(
                  'Keluar Aplikasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Apakah Anda yakin ingin keluar?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(), // Keluar dari aplikasi
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Keluar'),
              ),
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
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
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
            StatisticScreen(),
            HomeScreens(
                name: widget.name,
                penggunaId: widget.penggunaId), // Kirim data ke HomeScreens
            const ProfileScreen(),
          ],
        ),
      ),
    );
  }
}
