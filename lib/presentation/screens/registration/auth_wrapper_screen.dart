import 'package:flutter/material.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/screens/registration/firstPage_view.dart';
import 'package:hydrate/main.dart'; 
import 'package:lottie/lottie.dart';

class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({Key? key}) : super(key: key);

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final penggunaRepository = PenggunaRepository();
    bool isRegistered = false;
    try {
      isRegistered = await penggunaRepository.isPenggunaTerdaftar();
    } catch (e) {
      print("Error di AuthWrapperScreen saat cek status pengguna: $e");
      isRegistered = false;
    }

    if (!mounted) return;

    if (isRegistered) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => InfoProduct()), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: Center(
        child: Lottie.asset('assets/loading.json', width: 200, height: 200),
      ),
    );
  }
}