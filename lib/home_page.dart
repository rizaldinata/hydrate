import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Halaman Utama")),
      body: Center(child: Text("Selamat datang di aplikasi!")),
    );
  }
}
