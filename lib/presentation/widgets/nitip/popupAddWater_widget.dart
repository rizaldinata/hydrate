import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Popupaddwater extends StatefulWidget {
  const Popupaddwater();

  @override
  State<Popupaddwater> createState() => PopupaddwaterState();
}

class PopupaddwaterState extends State<Popupaddwater> {
  

  @override
  void initState() {
    super.initState();
  }

  void showAddedWaterPopup(BuildContext context, double amount) {
    OverlayEntry overlayEntry;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 500),
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: const Offset(0, 0),
            ).animate(CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOut,
            )),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      // color: const Color(0xFF69CE6C).withOpacity(0.9), // Warna hijau
                      color: Colors.white.withOpacity(0.90), // Warna hijau
                      borderRadius: BorderRadius.circular(
                          10), // Border radius agar rounded
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/berhasil.svg',
                          color: const Color(0xFF3EDAC0),
                          width: 24, // Ukuran ikon
                          height: 24,
                        ),
                        const SizedBox(width: 16), // Jarak antara ikon dan teks
                        const Text(
                          "Berhasil menambahkan air !",
                          style: TextStyle(
                              // color: Colors.white,
                              color: const Color(0xFF2F2E41),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    // Hapus snackbar setelah beberapa detik
    Future.delayed(const Duration(seconds: 2), () {
      animationController.reverse().then((value) {
        overlayEntry.remove();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }
}
