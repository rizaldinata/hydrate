import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/widgets/nitip/addWater_modal_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/checkAndCreateTodayTarget_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/countDown_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/addWater_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/initializeTarget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final HomeController _controller;
  final PageController _pageController = PageController();
  late HydrationCalculator _hydrationCalculator;
  double target = 0;
  double currentIntake = 0;
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);
  int selectedWater = 150;
  late final PenggunaController _penggunaController;
  int? idPengguna;
  String? namaPengguna;
  final RiwayatHidrasiController _riwayatHidrasiController = RiwayatHidrasiController();
  final TargetHidrasiRepository _targetHidrasiRepository = TargetHidrasiRepository();
  final GlobalKey<AddWaterState> _addWaterKey = GlobalKey<AddWaterState>();
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  Map<double, double> _glassOffsets = {};
  static const String _endTimeKey = 'countdown_end_time';

  // Stream subscription untuk event bus
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();

  // Metode publik untuk memaksa refresh data
  void refresh() {
    print("Refreshing HomeScreen data...");
    _loadUserData();
    _loadCountdownState();
    _loadTodayIntake();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _controller = HomeController();
    _penggunaController = PenggunaController();
    _controller.initAnimation(this);
    _pageController.addListener(() => setState(() {}));
    _loadCountdownState();
    // Subscribe ke event bus untuk refresh data
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_home' || event.type == 'refresh_all') {
        refresh();
      }
    });
  }

  @override
  void dispose() {
    // Dispose AudioPlayer when widget is disposed
    _countdownTimer?.cancel();
    _eventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
      _loadCountdownState(); // Reload countdown timer when app resumes
    } else if (state == AppLifecycleState.paused) {
      // Ensure timer info is saved when app goes to background
      _saveCurrentTimerState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  // Load timer state based on absolute end time
  Future<void> _loadCountdownState() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt(_endTimeKey);

    if (endTimeMillis != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remainingMillis = endTimeMillis - now;

      if (remainingMillis > 0) {
        setState(() {
          _remainingTime = Duration(milliseconds: remainingMillis);
        });
        _startCountdownFromCurrentState();
      } else {
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
    }
  }

  // Save the absolute end time of the timer
  Future<void> _saveCurrentTimerState() async {
    if (_remainingTime > Duration.zero) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final endTimeMillis = now + _remainingTime.inMilliseconds;
      await prefs.setInt(_endTimeKey, endTimeMillis);
      // print(
      //     "Timer end time saved: ${DateTime.fromMillisecondsSinceEpoch(endTimeMillis)}");
    }
  }

  // Start countdown from the current remaining time
  void _startCountdownFromCurrentState() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > Duration.zero) {
          _remainingTime -= const Duration(seconds: 1);
          _saveCurrentTimerState();
        } else {
          timer.cancel();
        }
      });
    });
  }

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

          await InitializeTarget();
          await _loadTodayIntake(); // Load today's intake
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // Initialize hydration target based on user data
  // Future<void> _initializeTarget() async {
  //   if (idPengguna == null) return;
  //   try {
  //     // Gunakan HydrationCalculator untuk mendapatkan nilai target
  //     await _hydrationCalculator.initializeData(idPengguna!);
  //     final targetHidrasi =
  //         _hydrationCalculator.calculateDailyWaterIntake() * 1000;
  //     setState(() {
  //       // Selalu gunakan nilai dari algoritma, jangan ada default
  //       target = targetHidrasi;
  //     });
  //     // Cek apakah target hidrasi untuk hari ini sudah ada
  //     await CheckAndCreateTodayTargetWidget();
  //     print("Target hidrasi diinisialisasi: $target mL berdasarkan algoritma");
  //   } catch (e) {
  //     print("Error initializing target: $e");
  //     // Jika terjadi error, tetap coba hitung dengan nilai default dalam HydrationCalculator
  //     // yang akan menggunakan berat badan default dll.
  //     try {
  //       final calculator = HydrationCalculator(penggunaId: idPengguna!);
  //       final targetHidrasi = calculator.calculateDailyWaterIntake() * 1000;
  //       setState(() {
  //         target = targetHidrasi;
  //       });
  //       print("Target hidrasi (fallback): $target mL");
  //     } catch (e2) {
  //       print("Error saat menghitung target hidrasi (fallback): $e2");
  //     }
  //   }
  // }

  // Update fungsi _loadTodayIntake() untuk menggunakan persentase dari database
  Future<void> _loadTodayIntake() async {
    if (idPengguna == null) return;

    try {
      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(idPengguna!, todayDate);

      if (targetHarian != null) {
        double targetHidrasi = targetHarian['target_hidrasi'] ?? 0.0;
        double totalHidrasi = targetHarian['total_hidrasi_harian'] ?? 0.0;
        double persentaseHidrasi = targetHarian['persentase_hidrasi'] ?? 0.0;

        setState(() {
          target = targetHidrasi;
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi;
        });

        print(
            "Data hidrasi dimuat: $totalHidrasi mL dari target $targetHidrasi mL (${persentaseHidrasi.toStringAsFixed(1)}%)");

        if (totalHidrasi > 0 && _remainingTime.inSeconds <= 0) {
          Countdown();
        }
      } else {
        await CheckAndCreateTodayTargetWidget();

        final riwayatHariIni = await _riwayatHidrasiController
            .getRiwayatHidrasiHariIni(idPengguna!);

        double totalIntake = 0;
        for (var riwayat in riwayatHariIni) {
          totalIntake += riwayat.jumlahHidrasi;
        }

        if (totalIntake > 0) {
          await _targetHidrasiRepository.updateTotalHidrasi(
              idPengguna!, todayDate, totalIntake);

          final updatedTarget = await _targetHidrasiRepository
              .getTargetHidrasiHarian(idPengguna!, todayDate);

          if (updatedTarget != null) {
            setState(() {
              currentIntake = totalIntake;
              _valueNotifier.value = updatedTarget['persentase_hidrasi'] ?? 0.0;
            });
          } else {
            setState(() {
              currentIntake = totalIntake;
              _valueNotifier.value = min(100, (currentIntake / target) * 100);
            });
          }

          if (_remainingTime.inSeconds <= 0) {
            Countdown();
          }
        }
      }
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");

      try {
        await _hydrationCalculator.initializeData(idPengguna!);
        final targetHidrasi =
            _hydrationCalculator.calculateDailyWaterIntake() * 1000;

        setState(() {
          target = targetHidrasi;
          _valueNotifier.value = min(100, (currentIntake / target) * 100);
        });

        print("Menggunakan target hidrasi fallback: $targetHidrasi mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (fallback): $e2");
      }
    }
  }

  // Function to format time for countdown
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
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
      backgroundColor: const Color(0xFFE8F7FF),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            AddWater(key: _addWaterKey),
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
                  Text(
                    currentIntake >= target ? "Pencapaianmu hari ini telah selesai" : "Ayo selesaikan pencapaianmu hari ini",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentIntake >= target ? Color(0xFF2AD1D1) : Colors.black54,
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
                      width: screenWidth * 0.75,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _remainingTime > Duration.zero
                              ? [
                                  Color(0xFF2AD1D1),
                                  Color(0xFF2AD1D1),
                                  // Color(0xFF15C3DC),
                                ] // Gradasi Biru ke Merah
                              : [
                                  Color(0xFF4EE9BD),
                                  Color(0xFF07BAE4),
                                ], // Full Merah saat harus minum
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _remainingTime > Duration.zero
                            ? "Hidrasi selanjutnya ${_formatTime(_remainingTime)}"
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2F2E41)
                              .withOpacity(0.1), // Warna bayangan
                          blurRadius: 12, // Seberapa jauh bayangan menyebar
                          offset: Offset(1, 2), // Posisi bayangan (X, Y)
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDrinkOption(
                            'assets/images/glass/100.svg', 100, 28),
                        _buildDrinkOption(
                            'assets/images/glass/150.svg', 150, 24),
                        _buildDrinkOption(
                            'assets/images/glass/200.svg', 200, 24),
                        GestureDetector(
                          onTap: () => AddWaterModal(),
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
                                  AddWaterModal();
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

  Widget _buildDrinkOption(String gambar, double amount, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Supaya ukuran sesuai isi
      children: [
        GestureDetector(
          onTap: () => _addWaterKey.currentState?.animateGlass(context, amount),
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            transform:
                Matrix4.translationValues(0, _glassOffsets[amount] ?? 0, 0),
            child: SvgPicture.asset(
              gambar,
              fit: BoxFit.scaleDown,
              width: size,
            ),
          ),
        ),
        const SizedBox(height: 5), // Beri sedikit jarak
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
