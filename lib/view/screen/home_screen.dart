import 'package:flutter/material.dart';
import 'package:hydrate/controller/home_controller.dart';
import 'package:hydrate/view/screen/navigation.dart';
import 'package:hydrate/view/screen/water_indicator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
            padding: EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 60.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("HYDRATE",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten")),
                Text(
                  "Hai, ${widget.name}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  // style: GoogleFonts.poppins(
                  //   fontSize: 18,
                  //   fontWeight: FontWeight.w600,
                  //   color: Colors.black87,
                  // ),
                ),
                SizedBox(height: 4),
                Text(
                  "Selesaikan pencapaianmu hari ini",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                  // style: GoogleFonts.poppins(
                  //   fontSize: 14,
                  //   fontWeight: FontWeight.w500,
                  //   color: Colors.black54,
                  // ),
                ),
              ],
            ),
          ),

          // Animasi tombol geser ke samping
          Positioned(
            top: 190,
            right: 1,
            child: AnimatedBuilder(
              animation: _controller.animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _controller.animation,
                  child: SizedBox(
                    width: 200,
                    child: FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: Colors.blue,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Hidrasi Selanjutnya",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              // style: GoogleFonts.poppins(
                              //   fontSize: 12,
                              //   fontWeight: FontWeight.w600,
                              //   color: Colors.white,
                              // ),
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
                const SizedBox(
                  height: 200,
                ),
                SizedBox(
                  height: 100,
                  child: CustomPaint(
                    size: const Size(200, 100),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: 140,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "100 ml",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Gluten"),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Colors.blue,
                    dotColor: Colors.grey[300]!,
                    dotHeight: 10,
                    dotWidth: 10,
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
