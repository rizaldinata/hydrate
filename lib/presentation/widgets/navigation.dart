import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Navigasi extends StatefulWidget {
  const Navigasi({super.key});

  @override
  State<Navigasi> createState() => _NavigasiState();
}

class _NavigasiState extends State<Navigasi> {
  int _currentIndex = 0;
  final _items = [
    SalomonBottomBarItem(
      icon: const Icon(CupertinoIcons.chart_bar_alt_fill, size: 30),  // Ukuran ikon lebih besar
      title: const Text('Statistics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),  // Ukuran teks lebih besar
      selectedColor: const Color.fromARGB(255, 0, 170, 255),
    ),
    SalomonBottomBarItem(
      icon: const Icon(CupertinoIcons.house_fill, size: 30),  // Ukuran ikon lebih besar
      title: const Text('Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      selectedColor: const Color.fromARGB(255, 0, 170, 255),
    ),
    SalomonBottomBarItem(
      icon: const Icon(CupertinoIcons.bell_fill, size: 30),  // Ukuran ikon lebih besar
      title: const Text('Notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      selectedColor: const Color.fromARGB(255, 0, 170, 255),
    ),
    SalomonBottomBarItem(
      icon: const Icon(CupertinoIcons.person_solid, size: 30),  // Ukuran ikon lebih besar
      title: const Text('Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      selectedColor: const Color.fromARGB(255, 0, 170, 255),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,  // Meningkatkan bayangan untuk efek lebih dramatis
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),  // Menambah margin untuk memberikan ruang
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 3,
              offset: Offset(0, -4),  // Menambahkan efek bayangan yang lebih halus
            ),
          ],
        ),
        child: SalomonBottomBar(
          duration: const Duration(milliseconds: 400),
          items: _items,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() {
            _currentIndex = index;
          }),
        ),
      ),
    );
  }
}
