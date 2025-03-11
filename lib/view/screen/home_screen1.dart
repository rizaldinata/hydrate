import 'package:flutter/material.dart';
import 'package:hydrate/controller/home_controller.dart';
import 'package:hydrate/view/screen/navigation.dart';
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
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);

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

  // Fungsi untuk menambah jumlah air
  void _addWater(double amount) {
    setState(() {
      if (currentIntake + amount <= target) {
        currentIntake += amount;
      } else {
        currentIntake = target;
      }
      _valueNotifier.value = (currentIntake / target) * 100;
    });

    print("Air ditambahkan: $amount ml, Total: $currentIntake ml");
  }

  // Menampilkan modal untuk memilih jumlah air
  void _showAddWaterModal() {
    print("Tombol + ditekan");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        print("Modal muncul");
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 10,
            children: [
              _buildWaterButton(100),
              _buildWaterButton(200),
              _buildWaterButton(300),
              _buildWaterButton(500),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Stack(
        children: [

          // Bagian atas
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                const Text("HYDRATE",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten")),
                // Nama user
                Text(
                  "Hai, ${widget.name}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Kata-kata pencapaian
                const Text(
                  "Ayo selesaikan pencapaianmu hari ini!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.all(42.0),
                  child: Center(
                    // Likaran progress
                    child: DashedCircularProgressBar.aspectRatio(
                      aspectRatio: 1,
                      valueNotifier: _valueNotifier,
                      progress: _valueNotifier.value,
                      startAngle: 250,
                      sweepAngle: 222,
                      foregroundColor: Color(0xFF00A6FB),
                      backgroundColor: const Color(0xFFA1E3F9),
                      foregroundStrokeWidth: 16,
                      backgroundStrokeWidth: 12,
                      animation: true,
                      seekSize: 10,
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
                                  color: const Color(0xFF2F2E41),
                                  fontWeight: FontWeight.w300,
                                  fontSize: 60,
                                ),
                              ),
                              Text(
                                '${currentIntake.toInt()} ml / ${target.toInt()} ml',
                                style: const TextStyle(
                                  color: const Color(0xFF2F2E41),
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 350,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),

                      // bagian tambah air default
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDrinkOption(100),
                          _buildDrinkOption(150),
                          _buildDrinkOption(200),
                          _buildDrinkOption(250),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -30,
                      left: 150,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: FloatingActionButton(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          onPressed: _showAddWaterModal,
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Navigasi(),
        ],
      ),
    );
  }

  Widget _buildWaterButton(double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _addWater(amount);
          Navigator.pop(context); // Tutup modal setelah memilih
        },
        child: Text("+ ${amount.toInt()} ml",
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDrinkOption(double amount) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.local_drink, color: Colors.blue),
          onPressed: () => _addWater(amount),
        ),
        Text('${amount.toInt()} ml',
            style: const TextStyle(fontSize: 12, color: const Color(0xFF2F2E41), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
