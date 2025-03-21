import 'package:flutter/material.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/widgets/navigation.dart';
import 'package:hydrate/presentation/widgets/water_indicator.dart';
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
  int _currentPage = 0; // Indeks halaman saat ini

  // Daftar jumlah ml sesuai gelas
  final List<int> glassSizes = [100, 300, 500];
  final List<String> glassImages = [
    "assets/images/gelas3.png",
    "assets/images/gelas1.png",
    "assets/images/gelas4.png"
  ];

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

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round(); // Update halaman
      });
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
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // judul dari aplikasi
                const Text("HYDRATE",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten")),
                // memanggil usename dari registrasi
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Text(
                    "Hai, ${widget.name}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // entah deskripsi
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: const Text(
                    "Selesaikan pencapaianmu hari ini",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 200),
                // SizedBox(
                //   height: 100,
                //   child: CustomPaint(
                //     size: const Size(200, 100),
                //     painter: WaterIndicatorPainter(_controller.waterProgress),
                //   ),
                // ),
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: glassImages.length,
                    itemBuilder: (context, index) {
                      return Image.asset(glassImages[index]);
                    },
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
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "${glassSizes[_currentPage]} ml",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Gluten"),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SmoothPageIndicator(
                  controller: _pageController,
                  count: glassImages.length,
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
