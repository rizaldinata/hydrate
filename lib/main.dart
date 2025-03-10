import 'package:flutter/material.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart'; // Ganti import ke repository
import 'package:hydrate/home_page.dart';
import 'package:hydrate/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hydrate',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: SplashScreen(),
        routes: {
          '/home': (context) => HomePage(),
          '/register': (context) => RegisterPage(),
        });
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PenggunaRepository _penggunaRepository =
      PenggunaRepository();

  @override
  void initState() {
    super.initState();
    checkPenggunaStatus();
  }

  void checkPenggunaStatus() async {
    print("Memeriksa status pengguna...");

    try {
      bool isterdaftar = await _penggunaRepository.isPenggunaTerdaftar();
      print("Status pengguna: $isterdaftar");

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          print("Navigasi ke halaman: ${isterdaftar ? '/home' : '/register'}");
          Navigator.pushReplacementNamed(
              context, isterdaftar ? '/home' : '/register');
        }
      });
    } catch (e) {
      print("Error saat memeriksa status pengguna: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
