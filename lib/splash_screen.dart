import 'package:flutter/material.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PenggunaRepository _penggunaRepository = PenggunaRepository();

  @override
  void initState() {
    super.initState();
    checkPenggunaStatus();
  }

  void checkPenggunaStatus() async {
    print("Memeriksa status pengguna...");

    try {
      bool isterdaftar = await _penggunaRepository.isPenggunaTerdaftar();
      print("Status pengguna di database: $isterdaftar");

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
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Aplikasi Kesehatan",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
