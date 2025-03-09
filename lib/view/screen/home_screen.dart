import 'package:flutter/material.dart';
import 'package:hydrate/controller/home_controller.dart';
import 'package:hydrate/view/screen/navigation.dart';
import 'package:hydrate/view/screen/water_indicator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.initAnimation(this);

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {});
    });

    Future.delayed(const Duration(seconds: 5), () {
      _controller.startAnimation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo HYDRATE
                      Text(
                        "HYDRATE",
                        style: GoogleFonts.gluten(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00A6FB),
                        ),
                      ),
                SizedBox(height: 8),
                Text(
                  "Hai, ${widget.name}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,  // Teks hitam untuk keterbacaan
                    fontFamily: "Roboto", // Font utama yang mudah dibaca
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Selesaikan pencapaianmu hari ini",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,  // Teks dengan kontras rendah untuk informasi sekunder
                    fontFamily: "OpenSans",  // Font sekunder yang lebih elegan
                  ),
                ),
              ],
            ),
          ),
          // Animasi tombol geser ke samping
          Positioned(
            top: 190,
            right: 20,
            child: AnimatedBuilder(
              animation: _controller.animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _controller.animation,
                  child: SizedBox(
                    width: 250,
                    child: FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: Colors.blueAccent,  // Warna utama yang cerah
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),  // Sudut lebih lembut
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop, color: Colors.white, size: 32),
                            SizedBox(width: 8),
                            Text(
                              "Hidrasi Selanjutnya",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Gelas air bisa digeser + indikator titik
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 200),
                SizedBox(
                  height: 100,
                  child: CustomPaint(
                    size: const Size(250, 100),  // Lebar yang lebih besar
                    painter: WaterIndicatorPainter(_controller.waterProgress),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: PageView(
                    controller: _pageController,
                    children: [
                      Image.asset("assets/images/gelas3.png"),
                      Image.asset("assets/images/gelas1.png"),
                      Image.asset("assets/images/gelas2.png"),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 160,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],  // Biru yang lebih lembut
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "100 ml",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Colors.blueAccent,  // Biru cerah untuk dot aktif
                    dotColor: Colors.grey[300]! ,
                    dotHeight: 12,  // Ukuran dot sedikit lebih besar
                    dotWidth: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Navigasi(),
    );
  }
}
