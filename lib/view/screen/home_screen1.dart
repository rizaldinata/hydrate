import 'package:flutter/material.dart';
import 'package:hydrate/controller/home_controller.dart';
import 'package:hydrate/view/screen/navigation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';

class HomeScreens extends StatefulWidget {
  final String name;
  const HomeScreens({super.key, required this.name});

  @override
  State<HomeScreens> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreens>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final double target = 1500; // Target harian air
  double currentIntake = 0; // Nilai awal air dalam ml
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0); // Persentase progress

  // Fungsi untuk menambahkan jumlah air
  void _addWater(double amount) {
    setState(() {
      if (currentIntake + amount <= target) {
        currentIntake += amount;
      } else {
        currentIntake = target; // Batas maksimal
      }
      _valueNotifier.value = (currentIntake / target) * 100; // Hitung progress
    });
  }

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
        _currentPage = _pageController.page!.round();
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
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("HYDRATE",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten")),
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
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: const Text(
                    "Selesaikan pencapaianmu hari ini segera",
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
                // const SizedBox(height: 200),
                Padding(
                  padding: const EdgeInsets.all(42.0),
                  child: Center(
                    child: DashedCircularProgressBar.aspectRatio(
                      aspectRatio: 1,
                      valueNotifier: _valueNotifier,
                      progress: _valueNotifier.value,
                      startAngle: 250,
                      sweepAngle: 225,
                      foregroundColor: Colors.blue,
                      backgroundColor: Color(0xFFA1E3F9),
                      foregroundStrokeWidth: 15,
                      backgroundStrokeWidth: 15,
                      animation: true,
                      seekSize: 6,
                      seekColor: const Color(0xffeeeeee),
                      child: Center(
                        child: ValueListenableBuilder(
                          valueListenable: _valueNotifier,
                          builder: (_, double value, __) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 60,
                                ),
                              ),
                              Text(
                                '${currentIntake.toInt()} ml / ${target.toInt()} ml',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Row untuk tombol minum air
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWaterButton(100), // Tombol untuk menambah 100ml
                    // _buildWaterButton(300), // Tombol untuk menambah 300ml
                    // _buildWaterButton(500), // Tombol untuk menambah 500ml
                  ],
                ),

                const SizedBox(height: 20),

                // SmoothPageIndicator(
                //   controller: _pageController,
                //   count: 3,
                //   effect: ExpandingDotsEffect(
                //     activeDotColor: Colors.blue,
                //     dotColor: Colors.grey[300]!,
                //     dotHeight: 10,
                //     dotWidth: 10,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Navigasi(),
    );
  }

  // Widget tombol untuk menambah jumlah air
  Widget _buildWaterButton(double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _addWater(amount),
        child: Text("+ ${amount.toInt()} ml", style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
