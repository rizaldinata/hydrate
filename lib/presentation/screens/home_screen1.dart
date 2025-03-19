import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'dart:async';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/widgets/navigation.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';

class HomeScreens extends StatefulWidget {
  // final String name;
  // final int penggunaId;

  // const HomeScreens({super.key, required this.name, required this.penggunaId});

  const HomeScreens({
    super.key,
  });

  @override
  State<HomeScreens> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreens>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
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
  int? idPengguna;
  String? namaPengguna;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _loadSession().then((_) {
      if (idPengguna != null) {
        _hydrationCalculator = HydrationCalculator(penggunaId: idPengguna!);
        _initializeTarget();
      }
    });
    _controller.initAnimation(this);
    _pageController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadSession() async {
    int? id = await SessionManager.getSession();

    if (id != null) {
      setState(() {
        idPengguna = id;
      });
      _loadPenggunaById(id);
    } else {
      print("Session data is null");
    }
  }

  Future<void> _loadPenggunaById(int id) async {
    try {
      var penggunaData = await PenggunaRepository().getPenggunaById(id);
      print("Data Pengguna: $penggunaData"); // Debugging

      if (penggunaData != null) {
        setState(() {
          idPengguna = penggunaData['id'];
          namaPengguna = penggunaData['nama_pengguna'] ?? 'Nama Tidak Tersedia';
        });
      } else {
        print("Pengguna data is null");
      }
    } catch (e) {
      print("Error saat mengambil data pengguna: $e");
    }
  }

  // Initialize hydration target based on user data
  Future<void> _initializeTarget() async {
    await _hydrationCalculator.initializeData(idPengguna!);
    setState(() {
      target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
      if (target <= 0) {
        target = 2000; // Default value if target is 0 or negative
      }
    });
  }

  // Function to add water intake
  void _addWater(double amount) {
    if (target <= 0) {
      print("Target is not set or invalid");
      return;
    }

    setState(() {
      if (currentIntake + amount <= target) {
        currentIntake += amount;
      } else {
        currentIntake = target; // Max limit
      }
      _valueNotifier.value = (currentIntake / target) * 100;
    });
    _startCoutdown();
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
                          if (currentIntake + selectedWater <= target) {
                            currentIntake += selectedWater;
                          } else {
                            currentIntake =
                                target; // If exceeds target, set to max target
                          }
                          _valueNotifier.value = (currentIntake / target) * 100;
                        });
                        _startCoutdown();
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
                const Text("HYDRATE",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten")),
                Transform.translate(
                  offset: const Offset(0, -5),
                  child: Text(
                    namaPengguna != null
                        ? "Hai, $namaPengguna"
                        : "Hai, Pengguna!",
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
                Padding(
                  padding: const EdgeInsets.all(42.0),
                  child: Center(
                    child: DashedCircularProgressBar.aspectRatio(
                      aspectRatio: 1,
                      valueNotifier: _valueNotifier,
                      progress: _valueNotifier.value,
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
                                '${value.ceil()}%',
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
                                    '${currentIntake.toInt()} mL',
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
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    width: screenWidth * 0.6,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _remainingSeconds > 0
                          ? "NEXT DRINK IN ${_formatTime(_remainingSeconds)}"
                          : "TAP TO DRINK!",
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
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
                              child: const Icon(Icons.add, color: Colors.white),
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
          const Navigasi(),
        ],
      ),
    );
  }

  Widget _buildDrinkOption(double amount) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _addWater(amount),
          child: Image.asset(
            "assets/images/glass.png",
            fit: BoxFit.contain,
            width: 30,
            height: 30,
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
