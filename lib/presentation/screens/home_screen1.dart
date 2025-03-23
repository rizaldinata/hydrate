import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/pengguna_model.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({
    super.key,
  });

  @override
  State<HomeScreens> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreens>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  List<Map<String, dynamic>> waterHistory = [];
  final PageController _pageController = PageController();
  late HydrationCalculator _hydrationCalculator;
  double target = 0;
  double currentIntake = 0;
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);
  int selectedWater = 150;
  late final PenggunaController _penggunaController;
  int? idPengguna;
  String? namaPengguna;
  final RiwayatHidrasiController _riwayatHidrasiController =
      RiwayatHidrasiController();
  final TargetHidrasiRepository _targetHidrasiRepository = TargetHidrasiRepository();
  // Menggunakan WIB (UTC+7)
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));

  Timer? _coutdownTimer;
  int _remainingSeconds = 0;

  Map<double, double> _glassOffsets = {
    100: 0,
    150: 0,
    200: 0,
  }; // Posisi awal

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _penggunaController = PenggunaController();
    _controller.initAnimation(this);
    _pageController.addListener(() => setState(() {}));
    _loadUserData();
  }

// Load user data
  Future<void> _loadUserData() async {
    try {
      final session = SessionManager();
      final userId = await session.getUserId();

      if (userId != null) {
        final pengguna = await _penggunaController.getPenggunaById(userId);

        if (pengguna != null) {
          _hydrationCalculator = HydrationCalculator(penggunaId: userId);

          setState(() {
            idPengguna = userId;
            namaPengguna = pengguna.nama;
          });

          await _initializeTarget();
          await _loadTodayIntake(); // Load today's intake
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // Initialize hydration target based on user data
  Future<void> _initializeTarget() async {
    if (idPengguna == null) return;

    try {
      await _hydrationCalculator.initializeData(idPengguna!);
      setState(() {
        target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        target = target > 0 ? target : 2000;
      });
      
      // Cek apakah target hidrasi untuk hari ini sudah ada
      await _checkAndCreateTodayTarget();
    } catch (e) {
      print("Error initializing target: $e");
    }
  }

  // Fungsi baru untuk memeriksa dan membuat target hidrasi hari ini jika belum ada
  Future<void> _checkAndCreateTodayTarget() async {
    if (idPengguna == null) return;
    
    try {
      final targetExists = await _targetHidrasiRepository.checkTargetHidrasiExists(
        idPengguna!,
        todayDate
      );
      
      if (!targetExists) {
        await _targetHidrasiRepository.createTargetHidrasi(
          idPengguna!,
          target,
          todayDate,
          0.0 // Total hidrasi awal adalah 0
        );
        print("Target hidrasi baru dibuat untuk tanggal $todayDate");
      } else {
        print("Target hidrasi untuk tanggal $todayDate sudah ada");
      }
    } catch (e) {
      print("Error saat memeriksa/membuat target hidrasi: $e");
    }
  }

  // Fungsi baru untuk memuat jumlah hidrasi hari ini
  Future<void> _loadTodayIntake() async {
    if (idPengguna == null) return;
    
    try {
      // Ambil data dari tabel riwayat_hidrasi untuk hari ini
      final riwayatHariIni = await _riwayatHidrasiController.getRiwayatHidrasiHariIni(idPengguna!);
      
      // Hitung total hidrasi
      double totalIntake = 0;
      for (var riwayat in riwayatHariIni) {
        totalIntake += riwayat.jumlahHidrasi;
      }
      
      setState(() {
        currentIntake = totalIntake;
        _valueNotifier.value = min(100, (currentIntake / target) * 100);
      });
      
      // Perbarui juga data di tabel target_hidrasi
      await _targetHidrasiRepository.updateTotalHidrasi(idPengguna!, todayDate, totalIntake);
      
      // Jika total hidrasi sudah ada, set countdown timer
      if (riwayatHariIni.isNotEmpty) {
        _startCoutdown();
      }
      
      print("Total hidrasi hari ini: $totalIntake dari ${riwayatHariIni.length} catatan");
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");
    }
  }

  // Animasi Gerakan Buat Gelas
  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User tidak teridentifikasi!")));
      return;
    }

    try {
      // Simpan riwayat hidrasi
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
      );
      
      // Perbarui total hidrasi di tabel target_hidrasi
      double newTotalIntake = currentIntake + amount;
      await _targetHidrasiRepository.updateTotalHidrasi(
        idPengguna!, 
        todayDate, 
        newTotalIntake
      );
    } catch (e) {
      print("Gagal menyimpan riwayat: $e");
    }

    setState(() {
      _glassOffsets[amount] = -40;
    });
  

    Future.delayed( Duration(milliseconds: 300), () {
      setState(() {
        _glassOffsets[amount] = 0;
      });
    });

    _addWater(amount); // Tetap panggil untuk update progress
  }

  // Function to add water intake
  void _addWater(double amount) {
    if (target <= 0) {
      print("Target is not set or invalid");
      return;
    }

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
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} WIB";
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
          top: 50,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, -0.5),
              end: Offset(0, 0),
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

    overlay.insert(overlayEntry);
    animationController.forward();

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
                      onPressed: () async {
                        if (idPengguna == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User tidak teridentifikasi!"),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          selectedWater = tempSelectedWater;
                        });

                        // Simpan riwayat hidrasi
                        await _riwayatHidrasiController.tambahRiwayatHidrasi(
                          fkIdPengguna: idPengguna!,
                          jumlahHidrasi: selectedWater.toDouble(),
                        );
                        
                        // Perbarui total hidrasi di tabel target_hidrasi
                        double newTotalIntake = currentIntake + selectedWater;
                        await _targetHidrasiRepository.updateTotalHidrasi(
                          idPengguna!, 
                          todayDate, 
                          newTotalIntake
                        );

                        setState(() {
                          currentIntake += selectedWater;
                          _valueNotifier.value = min(100, (currentIntake / target) * 100);
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

  // Fungsi untuk overflow nama
  String truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;

    int lastSpace = name.substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace == -1) {
      return "${name.substring(0, maxLength)}..."; // Jika tidak ada spasi, potong langsung
    } else {
      return "${name.substring(0, lastSpace)}..."; // Jika ada spasi, potong di spasi terakhir
    }
  }
  @override
  Widget build(BuildContext context) {
    if (namaPengguna == null) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
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
                  const Text(
                    "HYDRATE",
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten"),
                  ),
                  Transform.translate(
                    offset: Offset(0, screenHeight * -0.008),
                    child: Text(
                      "Hai, $namaPengguna",
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
          ],
        ),
      ),
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

  @override
  void dispose() {
    _coutdownTimer?.cancel();
    super.dispose();
  }
}
