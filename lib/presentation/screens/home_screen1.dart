import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:intl/intl.dart';
// Import event bus
import 'package:hydrate/core/utils/app_event_bus.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({
    super.key,
  });

  @override
  State<HomeScreens> createState() => HomeScreensState();
}

class HomeScreensState extends State<HomeScreens>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  final RiwayatHidrasiController _riwayatHidrasiController =
      RiwayatHidrasiController();
  final TargetHidrasiRepository _targetHidrasiRepository =
      TargetHidrasiRepository();
  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7)));

  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  
  // Konstanta untuk timer
  static const int _countdownDurationInSeconds = 3600; // 1 jam
  static const String _endTimeKey = 'countdown_end_time';

  Map<double, double> _glassOffsets = {};

   // Stream subscription untuk event bus
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();

  // Metode publik untuk memaksa refresh data
  void refresh() {
    print("Refreshing HomeScreen data...");
    _loadUserData();
    _loadCountdownState();
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
      print("Timer end time saved: ${DateTime.fromMillisecondsSinceEpoch(endTimeMillis)}");
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
      // Gunakan HydrationCalculator untuk mendapatkan nilai target
      await _hydrationCalculator.initializeData(idPengguna!);
      final targetHidrasi =
          _hydrationCalculator.calculateDailyWaterIntake() * 1000;

      setState(() {
        // Selalu gunakan nilai dari algoritma, jangan ada default
        target = targetHidrasi;
      });

      // Cek apakah target hidrasi untuk hari ini sudah ada
      await _checkAndCreateTodayTarget();

      print("Target hidrasi diinisialisasi: $target mL berdasarkan algoritma");
    } catch (e) {
      print("Error initializing target: $e");

      // Jika terjadi error, tetap coba hitung dengan nilai default dalam HydrationCalculator
      // yang akan menggunakan berat badan default dll.
      try {
        final calculator = HydrationCalculator(penggunaId: idPengguna!);
        final targetHidrasi = calculator.calculateDailyWaterIntake() * 1000;

        setState(() {
          target = targetHidrasi;
        });

        print("Target hidrasi (fallback): $target mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (fallback): $e2");
      }
    }
  }

  // Update fungsi _checkAndCreateTodayTarget() untuk menggunakan nilai target dari calculator
  Future<void> _checkAndCreateTodayTarget() async {
    if (idPengguna == null) return;
    
    try {
      final targetExists = await _targetHidrasiRepository.checkTargetHidrasiExists(
        idPengguna!,
        todayDate
      );
      
      if (!targetExists) {
        if (target <= 0) {
          await _hydrationCalculator.initializeData(idPengguna!);
          target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        }
        
        await _targetHidrasiRepository.createTargetHidrasi(
          idPengguna!,
          target,
          todayDate,
          0.0
        );
        print("Target hidrasi baru dibuat untuk tanggal $todayDate: $target mL");
      } else {
        await _targetHidrasiRepository.updateTargetHidrasiValue(idPengguna!, todayDate);
        print("Target hidrasi untuk tanggal $todayDate sudah ada dan diperbarui");
        
        final updatedTarget = await _targetHidrasiRepository.getTargetHidrasiHarian(
          idPengguna!, 
          todayDate
        );
        
        if (updatedTarget != null && (updatedTarget['target_hidrasi'] ?? 0) > 0) {
          setState(() {
            target = updatedTarget['target_hidrasi'];
          });
          print("Target hidrasi diperbarui: $target mL");
        }
      }
    } catch (e) {
      print("Error saat memeriksa/membuat target hidrasi: $e");
      
      try {
        await _hydrationCalculator.initializeData(idPengguna!);
        target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        print("Target hidrasi (recovery): $target mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (recovery): $e2");
      }
    }
  }

  // Update fungsi _loadTodayIntake() untuk menggunakan persentase dari database
  Future<void> _loadTodayIntake() async {
    if (idPengguna == null) return;
    
    try {
      final targetHarian = await _targetHidrasiRepository.getTargetHidrasiHarian(
        idPengguna!, 
        todayDate
      );

      if (targetHarian != null) {
        double targetHidrasi = targetHarian['target_hidrasi'] ?? 0.0;
        double totalHidrasi = targetHarian['total_hidrasi_harian'] ?? 0.0;
        double persentaseHidrasi = targetHarian['persentase_hidrasi'] ?? 0.0;
        
        setState(() {
          target = targetHidrasi;
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi;
        });
        
        print("Data hidrasi dimuat: $totalHidrasi mL dari target $targetHidrasi mL (${persentaseHidrasi.toStringAsFixed(1)}%)");
        
        if (totalHidrasi > 0 && _remainingTime.inSeconds <= 0) {
          _startCountdown();
        }
      } else {
        await _checkAndCreateTodayTarget();
        
        final riwayatHariIni = await _riwayatHidrasiController.getRiwayatHidrasiHariIni(idPengguna!);
        
        double totalIntake = 0;
        for (var riwayat in riwayatHariIni) {
          totalIntake += riwayat.jumlahHidrasi;
        }
        
        if (totalIntake > 0) {
          await _targetHidrasiRepository.updateTotalHidrasi(idPengguna!, todayDate, totalIntake);
          
          final updatedTarget = await _targetHidrasiRepository.getTargetHidrasiHarian(
            idPengguna!, 
            todayDate
          );
          
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
            _startCountdown();
          }
        }
      }
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");
      
      try {
        await _hydrationCalculator.initializeData(idPengguna!);
        final targetHidrasi = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        
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

  // animasi gelas
  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User tidak teridentifikasi!")));
      return;
    }

    try {
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
      );
      
      double newTotalIntake = currentIntake + amount;
      await _targetHidrasiRepository.updateTotalHidrasi(
        idPengguna!, 
        todayDate, 
        newTotalIntake
      );
      
      final targetHarian = await _targetHidrasiRepository.getTargetHidrasiHarian(
        idPengguna!, 
        todayDate
      );
      
      if (targetHarian != null) {
        double persentase = targetHarian['persentase_hidrasi'] ?? 0.0;
        setState(() {
          currentIntake = newTotalIntake;
          _valueNotifier.value = persentase;
        });
        print("Persentase hidrasi diperbarui dari database: $persentase%");
      } else {
        setState(() {
          currentIntake = newTotalIntake;
          _valueNotifier.value = min(100, (currentIntake / target) * 100);
        });
      }
      
      // Notifikasi halaman lain tentang perubahan data hidrasi
      _eventBus.fire('refresh_statistics');
      
    } catch (e) {
      print("Gagal menyimpan riwayat: $e");
      
      setState(() {
        currentIntake += amount;
        _valueNotifier.value = min(100, (currentIntake / target) * 100);
      });
    }

    setState(() {
      _glassOffsets[amount] = -40;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _glassOffsets[amount] = 0;
      });
    });

    _startCountdown();
    _showAddedWaterPopup(context, amount);
  }

// Fungsi animasi gelas (dipisahkan dari fungsi utama agar tidak mengganggu setState)
  void _animateGlassMovement(double amount) {
    setState(() {
      _glassOffsets[amount] = -40;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _glassOffsets[amount] = 0;
      });
    });
  }

  // Function to add water intake (tidak lagi digunakan langsung, hanya sebagai fallback)
  void _addWater(double amount) {
    if (target <= 0) {
      print("Target is not set or invalid");
      return;
    }

    setState(() {
      currentIntake += amount;
      _valueNotifier.value = min(100, (currentIntake / target) * 100);
    });
    _startCountdown();
    _showAddedWaterPopup(context, amount);
  }

  // Start countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingTime = const Duration(seconds: _countdownDurationInSeconds);
    });
    
    // Save absolute end time
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimeMillis = now + _remainingTime.inMilliseconds;
    
    // Save immediately to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_endTimeKey, endTimeMillis);
      print("Timer end time saved: ${DateTime.fromMillisecondsSinceEpoch(endTimeMillis)}");
    });
    
    // Start the counter
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > Duration.zero) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          timer.cancel();
        }
      });
    });
  }

  // Function to format time for countdown
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Show snack bar to indicate added water
  void _showAddedWaterPopup(BuildContext context, double amount) {
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

                        try {
                          // Simpan riwayat hidrasi
                          await _riwayatHidrasiController.tambahRiwayatHidrasi(
                            fkIdPengguna: idPengguna!,
                            jumlahHidrasi: selectedWater.toDouble(),
                          );

                          // Perbarui total hidrasi di tabel target_hidrasi
                          double newTotalIntake = currentIntake + selectedWater;
                          await _targetHidrasiRepository.updateTotalHidrasi(
                              idPengguna!, todayDate, newTotalIntake);

                          // Dapatkan persentase terbaru dari database
                          final targetHarian = await _targetHidrasiRepository
                              .getTargetHidrasiHarian(idPengguna!, todayDate);

                          if (targetHarian != null) {
                            // Gunakan persentase yang disimpan di database
                            double persentase =
                                targetHarian['persentase_hidrasi'] ?? 0.0;
                            setState(() {
                              currentIntake = newTotalIntake;
                              _valueNotifier.value = persentase;
                            });
                            print(
                                "Modal: Persentase hidrasi diperbarui dari database: $persentase%");
                          } else {
                            setState(() {
                              currentIntake = newTotalIntake;
                              _valueNotifier.value =
                                  min(100, (currentIntake / target) * 100);
                            });
                          }
                        } catch (e) {
                          print("Error saat menambah air: $e");
                          // Fallback jika gagal mengakses database
                          setState(() {
                            currentIntake += selectedWater;
                            _valueNotifier.value =
                                min(100, (currentIntake / target) * 100);
                          });
                        }

                        _startCountdown();
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
                          color: const Color(0xFF2F2E41).withOpacity(0.1), // Warna bayangan
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

  Widget _buildDrinkOption(String gambar, double amount, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Supaya ukuran sesuai isi
      children: [
        GestureDetector(
          onTap: () => _animateGlass(amount),
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
