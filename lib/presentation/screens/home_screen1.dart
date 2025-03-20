import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/widgets/navigation.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart'; // Ensure this import is correct

class HomeScreens extends StatefulWidget {
  final String name;
  final int penggunaId;

  const HomeScreens({super.key, required this.name, required this.penggunaId});

  @override
  State<HomeScreens> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreens>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  List<Map<String, dynamic>> waterHistory = [];
  final PageController _pageController = PageController();
  late HydrationCalculator
      _hydrationCalculator; // Ensure HydrationCalculator is defined
  double target = 0; // Target hydration dynamically calculated
  double currentIntake = 0; // Initial water intake in mL
  final ValueNotifier<double> _valueNotifier =
      ValueNotifier<double>(0); // Progress percentage
  int selectedWater = 150; // Default water selection is 150mL

  Timer? _coutdownTimer;
  int _remainingSeconds = 0; // Initial countdown timer value

  Map<double, double> _glassOffsets = {}; // Posisi awal

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.initAnimation(this);

    // Initialize HydrationCalculator with correct user ID
    _hydrationCalculator = HydrationCalculator(penggunaId: widget.penggunaId);
    _initializeTarget(); // Initialize the hydration target dynamically based on user data

    _pageController.addListener(() {
      setState(() {});
    });
  }

  // Initialize hydration target based on user data
  Future<void> _initializeTarget() async {
    await _hydrationCalculator
        .initializeData(widget.penggunaId); // Ensure this method works
    setState(() {
      target = _hydrationCalculator.calculateDailyWaterIntake() *
          1000; // Calculate target in mL
    });
  }

  // Animasi Gerakan Buatan Gelas
  void _animateGlass(double amount) {
    setState(() {
      _glassOffsets[amount] = -40; // posisi gerakan Naik
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _glassOffsets[amount] = 0; // Kembali ke posisi awal
      });
    });

    _addWater(amount);
  }

  // Function to add water intake
  void _addWater(double amount) {
    setState(() {
      currentIntake += amount; // Tetap menambah intake tanpa batas

      // Batasi progress agar tidak lebih dari 100%
      _valueNotifier.value = min(100, (currentIntake / target) * 100);
    });
    _startCoutdown();
    _showAddedWaterPopup(context, amount);
  }

  // Start countdown timer
  void _startCoutdown() {
    _coutdownTimer?.cancel();
    setState(() {
      _remainingSeconds = 3600;
    });
    _coutdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Function to format time for countdown
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  // Show snack bar to indicate added water
  void _showAddedWaterPopup(BuildContext context, double amount) {
    OverlayEntry overlayEntry;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: Duration(milliseconds: 500),
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 50, // Posisi awal di bagian atas
          left: 0,
          right: 0, // Pastikan berada di tengah horizontal
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, -0.5), // Muncul dari atas
              end: Offset(0, 0), // Turun ke bawah
            ).animate(CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOut,
            )),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 64, 186, 137),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5)
                      ],
                    ),
                    child: Text(
                      "Berhasil menambahkan ${amount.toInt()}  mL air!",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Masukkan overlay ke layar
    overlay.insert(overlayEntry);
    animationController.forward(); // Mulai animasi

    // Hapus overlay setelah 2 detik dengan animasi naik ke atas
    Future.delayed(Duration(seconds: 2), () {
      animationController.reverse().then((_) {
        overlayEntry.remove();
      });
    });
  }

  // Show the modal bottom sheet for custom water intake selection
  void _showAddWaterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempSelectedWater = selectedWater;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 420,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Pilih Ukuran Air",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(
                    color: Colors.blue,
                    thickness: 1,
                    height: 20,
                  ),
                  SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(
                            initialItem: (selectedWater ~/ 50) - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              tempSelectedWater = (index + 1) * 50;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 20,
                            builder: (context, index) {
                              int waterValue = (index + 1) * 50;
                              return Center(
                                child: Text(
                                  "$waterValue",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: tempSelectedWater == waterValue
                                        ? const Color(0xFF00A6FB)
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width - 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A6FB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.water_drop,
                              size: 24, color: Color(0xFF4ACCFF)),
                          Text(
                            "mL",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2F2E41),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedWater = tempSelectedWater;
                          currentIntake +=
                              selectedWater; // Selalu menambah intake

                          // Pastikan progress tidak lebih dari 100%
                          _valueNotifier.value =
                              min(100, (currentIntake / target) * 100);
                        });

                        _startCoutdown();
                        _showAddedWaterPopup(context, selectedWater.toDouble());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Pilih",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 242, 253),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("HYDRATE",
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue,
                          fontFamily: "Gluten")),
                  Transform.translate(
                    offset: Offset(0, screenHeight * -0.008),
                    child: Text(
                      "Hai, ${widget.name}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
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
                  SizedBox(
                    height: screenHeight * 0.2,
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.1),
                    child: Center(
                        child: DashedCircularProgressBar.aspectRatio(
                      aspectRatio: 1,
                      valueNotifier: _valueNotifier,
                      progress:
                          _valueNotifier.value, // Pastikan progress max 100%
                      startAngle: 230,
                      sweepAngle: 260,
                      foregroundColor: const Color(0xFF00A6FB),
                      backgroundColor: const Color(0xFFA1E3F9),
                      foregroundStrokeWidth: 15,
                      backgroundStrokeWidth: 15,
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
                                '${value.ceil()}%', // Tetap menampilkan maksimal 100%
                                style: const TextStyle(
                                  color: Color(0xFF2F2E41),
                                  fontWeight: FontWeight.w300,
                                  fontSize: 40,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${currentIntake.toInt()} mL', // Tetap menampilkan jumlah air yang dikonsumsi sebenarnya
                                    style: TextStyle(
                                      color: currentIntake >= target
                                          ? Colors.blue
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    ' / ${target.toInt()} mL',
                                    style: const TextStyle(
                                      color: Color(0xFF2F2E41),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ),
                  Transform.translate(
                    offset: Offset(0, screenHeight * -0.05),
                    child: Container(
                      width: screenWidth * 0.7,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _remainingSeconds > 0
                            ? const Color(0XFFFFB831)
                            : const Color(
                                0XFFEF9651), // Ubah warna berdasarkan kondisi
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _remainingSeconds > 0
                            ? "Hydrasi selanjutnya ${_formatTime(_remainingSeconds)}"
                            : "SAATNYA MINUM!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth * (0.8 + 0.04),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDrinkOption(100),
                        _buildDrinkOption(150),
                        _buildDrinkOption(200),
                        GestureDetector(
                          onTap: () => _showAddWaterModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: FloatingActionButton(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                onPressed: () {
                                  _showAddWaterModal(context);
                                },
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            //Positioning the navbar at the bottom
            // const Navigasi(),
          ],
        ),
      ),
      // bottomNavigationBar: Navigasi(),
    );
  }

  Widget _buildDrinkOption(double amount) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _animateGlass(amount),
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            transform: Matrix4.translationValues(0, _glassOffsets[amount] ?? 0,
                0), // Hanya gelas yang diklik bergerak
            child: SvgPicture.asset(
              'assets/images/glass.svg',
              fit: BoxFit.contain,
              width: 30,
              height: 30,
            ),
          ),
        ),
        Text(
          '${amount.toInt()} mL',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
