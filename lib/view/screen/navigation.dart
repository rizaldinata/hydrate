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
        icon: const Icon(CupertinoIcons.chart_bar_alt_fill),
        title: const Text('Statistics'),
        selectedColor: const Color.fromARGB(255, 0, 170, 255)),
    SalomonBottomBarItem(
        icon: const Icon(CupertinoIcons.house_fill),
        title: const Text('Home'),
        selectedColor: const Color.fromARGB(255, 0, 170, 255)),
    SalomonBottomBarItem(
        icon: const Icon(CupertinoIcons.bell_fill),
        title: const Text('Notivication'),
        selectedColor: const Color.fromARGB(255, 0, 170, 255)),
    SalomonBottomBarItem(
        icon: const Icon(CupertinoIcons.person_solid),
        title: const Text('Profile'),
        selectedColor: const Color.fromARGB(255, 0, 170, 255)),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: SalomonBottomBar(
        duration: Duration(milliseconds: 500),
        items: _items,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
        }),
      ),
    );
  }
}
