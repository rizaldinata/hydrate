import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
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
  late AudioPlayer _audioPlayer;
  late final HomeController _controller;
  final PageController _pageController = PageController();
  late HydrationCalculator _hydrationCalculator;
  double target = 0;
  double currentIntake = 0;
  double previousIntake = 0;
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);
  int selectedWater = 250;
  late final PenggunaController _penggunaController;
  int? idPengguna;
  String? namaPengguna;
  final RiwayatHidrasiController _riwayatHidrasiController =
      RiwayatHidrasiController();
  final TargetHidrasiRepository _targetHidrasiRepository =
      TargetHidrasiRepository();
  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7)));

  DateTime? _endTime;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  bool _isCountdownActive = false;

  // Konstanta untuk timer
  static const int _countdownDurationInSeconds = 10;
  static const String _endTimeKey = 'countdown_end_time';

  Map<double, double> _glassOffsets = {};
  // bool _canAddWater = true;
  // final ValueNotifier<bool> _canAddWater = ValueNotifier<bool>(true);
   bool _hasInitializedTarget = false;

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
    // inisialisasi notifikasi
    NotificationController.initializeLocalNotifications();
    _loadUserData();
    _controller = HomeController();
    _penggunaController = PenggunaController();
    _controller.initAnimation(this);
    _pageController.addListener(() => setState(() {}));
    _loadCountdownState();
    _audioPlayer = AudioPlayer();
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
    _audioPlayer.dispose();
    _countdownTimer?.cancel();
    _eventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _playDrinkingSound() async {
    try {
      print("Attempting to play drinking sound...");
      // Reset the player to ensure it can play again
      await _audioPlayer.stop();
      print("AudioPlayer stopped successfully");

      // Play the sound
      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
      print("Sound playing started successfully");
    } catch (e) {
      print("Error playing sound: $e");
      // Add more detailed error info
      print("Error details: ${e.toString()}");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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

  void _startTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > Duration.zero) {
          _remainingTime -= Duration(seconds: 1);
        } else {
          timer.cancel();
          // NotificationController.createNewNotification();
        }
      });
    });
  }

  // void _startCountdownIfNotRunning() async {
  //   if (_countdownTimer != null && _countdownTimer!.isActive) return;
  //   final now = DateTime.now();
  //   _endTime = now.add(Duration(seconds: _countdownDurationInSeconds));
  //   final prefs = await SharedPreferences.getInstance();
  //   prefs.setInt(_endTimeKey, _endTime!.millisecondsSinceEpoch);
  //   _remainingTime = Duration(seconds: _countdownDurationInSeconds);
  //   _startTimer();
  // }

  // Load timer state based on absolute end time
  Future<void> _loadCountdownState() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt(_endTimeKey);
    final hasStartedTimer = prefs.getBool('timer_has_started') ?? false;

    if (!hasStartedTimer) {
      // Timer has never been started, keep everything at zero
      setState(() {
        _remainingTime = Duration.zero;
        _isCountdownActive = false;
      });
      return;
    }

    if (endTimeMillis != null) {
      _endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final now = DateTime.now();

      if (_endTime!.isAfter(now)) {
        // Timer still running
        setState(() {
          _remainingTime = _endTime!.difference(now);
          _isCountdownActive = true;
        });
        _startTimer(); // Only start if it should be running
      } else {
        // Timer expired
        setState(() {
          _remainingTime = Duration.zero;
          _isCountdownActive = false;
        });
      }
    } else {
      // No saved timer, but check if user has had water today
      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(idPengguna!, todayDate);

      if (targetHarian != null &&
          (targetHarian['total_hidrasi_harian'] ?? 0) > 0) {
        // User has had water but timer expired, show "SAATNYA MINUM!"
        setState(() {
          _remainingTime = Duration.zero;
          _isCountdownActive =
              false; // Don't run timer, but show "SAATNYA MINUM!"
        });
      } else {
        // No water yet today, don't show any timer
        setState(() {
          _remainingTime = Duration.zero;
          _isCountdownActive = false;
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
  // void _startCountdownFromCurrentState() {
  //   _countdownTimer?.cancel();
  //   _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     setState(() {
  //       if (_remainingTime > Duration.zero) {
  //         _remainingTime -= const Duration(seconds: 1);
  //         _saveCurrentTimerState();
  //       } else {
  //         timer.cancel();
  //       }
  //     });
  //   });
  // }

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
    if (_hasInitializedTarget || idPengguna == null) return;
    _hasInitializedTarget = true;

    try {
      await _hydrationCalculator.initializeData(idPengguna!);
      final targetHidrasi =
          _hydrationCalculator.calculateDailyWaterIntake() * 1000;

      setState(() {
        target = targetHidrasi;
      });

      await _checkAndCreateTodayTarget();

      print("Target hidrasi diinisialisasi: $target mL");
    } catch (e) {
      print("Error initializing target: $e");
    }
  }

  // Update fungsi _checkAndCreateTodayTarget() untuk menggunakan nilai target dari calculator
  Future<void> _checkAndCreateTodayTarget() async {
    if (idPengguna == null) return;

    try {
      final targetExists = await _targetHidrasiRepository
          .checkTargetHidrasiExists(idPengguna!, todayDate);

      if (!targetExists) {
        if (target <= 0) {
          await _hydrationCalculator.initializeData(idPengguna!);
          target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
        }

        await _targetHidrasiRepository.createTargetHidrasi(
            idPengguna!, target, todayDate, 0.0);
        print(
            "Target hidrasi baru dibuat untuk tanggal $todayDate: $target mL");
      } else {
        await _targetHidrasiRepository.updateTargetHidrasiValue(
            idPengguna!, todayDate);
        print(
            "Target hidrasi untuk tanggal $todayDate sudah ada dan diperbarui");

        final updatedTarget = await _targetHidrasiRepository
            .getTargetHidrasiHarian(idPengguna!, todayDate);

        if (updatedTarget != null &&
            (updatedTarget['target_hidrasi'] ?? 0) > 0) {
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

// Update fungsi _loadTodayIntake() untuk menggunakan persentase dari database secara konsisten
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

        // Only check if there should be a "SAATNYA MINUM!" message
        if (totalHidrasi > 0) {
          SharedPreferences.getInstance().then((prefs) {
            final hasStartedTimer = prefs.getBool('timer_has_started') ?? false;
            if (!hasStartedTimer) {
              // Set flag to true since user has had water today
              prefs.setBool('timer_has_started', true);
            }
          });

          // Check if timer is already running
          final endTimeMillis = await SharedPreferences.getInstance()
              .then((prefs) => prefs.getInt(_endTimeKey));

          if (endTimeMillis != null) {
            final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
            if (endTime.isAfter(DateTime.now())) {
              // Timer is still running, load it normally
              _loadCountdownState();
            } else {
              // Timer has expired, show "SAATNYA MINUM!"
              setState(() {
                _remainingTime = Duration.zero;
                _isCountdownActive =
                    true; // This will make UI show "SAATNYA MINUM!"
              });
            }
          } else {
            // No timer but user has had water, show "SAATNYA MINUM!"
            setState(() {
              _remainingTime = Duration.zero;
              _isCountdownActive = true;
            });
          }
        }
      } else {
        // If no target exists for today, create one first
        await _checkAndCreateTodayTarget();

        // Check for any existing hydration records for today
        final riwayatHariIni = await _riwayatHidrasiController
            .getRiwayatHidrasiHariIni(idPengguna!);

        double totalIntake = 0;
        for (var riwayat in riwayatHariIni) {
          totalIntake += riwayat.jumlahHidrasi;
        }

        // If there are records, update the total in the database
        if (totalIntake > 0) {
          await _targetHidrasiRepository.updateTotalHidrasi(
              idPengguna!, todayDate, totalIntake);

          // Always get fresh data from database after updating
          final updatedTarget = await _targetHidrasiRepository
              .getTargetHidrasiHarian(idPengguna!, todayDate);

          if (updatedTarget != null) {
            setState(() {
              currentIntake =
                  updatedTarget['total_hidrasi_harian'] ?? totalIntake;
              _valueNotifier.value = updatedTarget['persentase_hidrasi'] ?? 0.0;
              target = updatedTarget['target_hidrasi'] ?? target;
            });

            print(
                "Data hidrasi diperbarui: $currentIntake mL dari target $target mL (${_valueNotifier.value.toStringAsFixed(1)}%)");
          } else {
            // This should rarely happen as we just created/updated the record
            print("Warning: Target hidrasi not found after update");
            setState(() {
              currentIntake = totalIntake;
            });

            // Try one more time to get data from database
            await _loadTodayIntake();
          }

          if (_remainingTime.inSeconds <= 0) {
            _startCountdown();
          }
        } else {
          // No records yet today, just set the UI with zero intake
          setState(() {
            currentIntake = 0;
            _valueNotifier.value = 0;
          });

          print("Tidak ada riwayat hidrasi hari ini. Target: $target mL");
        }
      }
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");

      try {
        // In case of database error, calculate a temporary target
        await _hydrationCalculator.initializeData(idPengguna!);
        final targetHidrasi =
            _hydrationCalculator.calculateDailyWaterIntake() * 1000;

        // Get any saved data from database even if there was an error earlier
        final targetHarian = await _targetHidrasiRepository
            .getTargetHidrasiHarian(idPengguna!, todayDate);

        if (targetHarian != null) {
          // If we can get data, use it
          setState(() {
            target = targetHarian['target_hidrasi'] ?? targetHidrasi;
            currentIntake = targetHarian['total_hidrasi_harian'] ?? 0.0;
            _valueNotifier.value = targetHarian['persentase_hidrasi'] ?? 0.0;
          });
        } else {
          // Last resort fallback
          setState(() {
            target = targetHidrasi;
            // Don't calculate percentage here, keep at 0 or previous value
          });
        }

        print("Menggunakan target hidrasi fallback: $target mL");
      } catch (e2) {
        print("Error saat menghitung target hidrasi (fallback): $e2");
      }
    }
  }

  // Modify _animateGlass method to play sound// Improved version of _animateGlass method to ensure consistent database updates and UI
  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User tidak teridentifikasi!")),
      );
      return;
    }

    _playDrinkingSound();

    try {
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
      );

      previousIntake = currentIntake;
      double newTotalIntake = currentIntake + amount;

      await _targetHidrasiRepository.updateTotalHidrasi(
        idPengguna!, todayDate, newTotalIntake,
      );

      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(idPengguna!, todayDate);

      if (targetHarian != null) {
        setState(() {
          previousIntake = currentIntake;
          currentIntake = targetHarian['total_hidrasi_harian'] ?? newTotalIntake;
          target = targetHarian['target_hidrasi'] ?? target;
          _valueNotifier.value = target > 0
              ? min(100, (currentIntake / target) * 100)
              : 0;
        });
      } else {
        setState(() {
          previousIntake = currentIntake;
          currentIntake = newTotalIntake;
          _valueNotifier.value = target > 0
              ? min(100, (currentIntake / target) * 100)
              : 0;
        });
      }

      _eventBus.fire('refresh_statistics');
    } catch (e) {
      print("Gagal menyimpan riwayat: $e");

      setState(() {
        previousIntake = currentIntake;
        currentIntake += amount;
        _valueNotifier.value = target > 0
            ? min(100, (currentIntake / target) * 100)
            : 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan data: ${e.toString().substring(0, min(50, e.toString().length))}..."),
          backgroundColor: Colors.red,
        ),
      );
    }

    _animateGlassMovement(amount);
    _startCountdown();
    _showAddedWaterPopup(context, amount);
    checkTargetAndShowAlert(context);
  }

  void _animateGlassMovement(double amount) {
    setState(() => _glassOffsets[amount] = -10);
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() => _glassOffsets[amount] = 0);
    });
  }

  // Start countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingTime = const Duration(seconds: _countdownDurationInSeconds);
      _isCountdownActive = true;
    });

    // Save absolute end time (opsional, jika ingin restore countdown saat app dibuka ulang)
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimeMillis = now + _remainingTime.inMilliseconds;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_endTimeKey, endTimeMillis);
      prefs.setBool('timer_has_started', true);
    });

    // _startTimer();

    // Mulai countdown di UI
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > Duration.zero) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          timer.cancel();
          NotificationController.createNewNotification();
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
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
                      IgnorePointer(
                        // biar transparan untuk gesture
                        child: Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width - 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A6FB).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        // biar transparan juga
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SvgPicture.asset(
                              'assets/images/glass2.svg',
                              width: 32,
                              height: 32,
                            ),
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
                                content: Text("User tidak teridentifikasi!")),
                          );
                          return;
                        }

                        _playDrinkingSound();

                        setState(() {
                          selectedWater = tempSelectedWater;
                        });

                        try {
                          // Save hydration record
                          await _riwayatHidrasiController.tambahRiwayatHidrasi(
                            fkIdPengguna: idPengguna!,
                            jumlahHidrasi: selectedWater.toDouble(),
                          );

                          // Update total in target_hidrasi
                          previousIntake = currentIntake;
                          double newTotalIntake = currentIntake + selectedWater;
                          await _targetHidrasiRepository.updateTotalHidrasi(
                              idPengguna!, todayDate, newTotalIntake);

                          // Always get fresh data from database
                          final targetHarian = await _targetHidrasiRepository
                              .getTargetHidrasiHarian(idPengguna!, todayDate);

                          setState(() {
                            if (targetHarian != null) {
                              previousIntake = currentIntake;
                              currentIntake =
                                  targetHarian['total_hidrasi_harian'] ??
                                      newTotalIntake;
                              _valueNotifier.value =
                                  targetHarian['persentase_hidrasi'] ?? 0.0;
                            } else {
                              previousIntake = currentIntake;
                              currentIntake = newTotalIntake;
                            }
                          });
                        } catch (e) {
                          print("Error saat menambah air: $e");
                        }

                        _startCountdown();
                        _showAddedWaterPopup(context, selectedWater.toDouble());
                        Navigator.pop(context);
                        //show alert
                        checkTargetAndShowAlert(context);
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

  //? fungsi alert untuk ucapan selamat
  bool hasShownCongrats = false;
  void checkTargetAndShowAlert(BuildContext context) {
    if (previousIntake < target) {
      hasShownCongrats = false;
    }
    if (currentIntake >= target && !hasShownCongrats) {
      hasShownCongrats = true;

      final confettiController =
          ConfettiController(duration: const Duration(seconds: 3));
      confettiController.play();

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Congrats",
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Confetti fireworks 🎇
                ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.05,
                  numberOfParticles: 25,
                  colors: const [
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.green
                  ],
                ),

                // Animated Alert Dialog with zoom in
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.white,
                    title: Column(
                      children: const [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                        SizedBox(height: 10),
                        Text(
                          'Selamat! 🎉',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    content: const Text(
                      'Kamu sudah mencapai target harianmu!',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            confettiController.dispose();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Mantap!',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          );
        },
      );
    }
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
                      "Hai, ${truncateName(namaPengguna!, 20)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    currentIntake >= target
                        ? "Pencapaianmu hari ini telah selesai."
                        : "Ayo selesaikan pencapaianmu hari ini!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentIntake >= target
                          ? Color(0xFF07BAE4)
                          : Colors.black54,
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
                                '${min(100, value.ceil())}%', // Tetap menampilkan maksimal 100%
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
                        (_isCountdownActive && _remainingTime.inSeconds > 0)
                            ? "Hidrasi selanjutnya ${_formatTime(_remainingTime)}"
                            : (_isCountdownActive || currentIntake > 0)
                                ? "SAATNYA MINUM!"
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDrinkOption(
                            'assets/images/glass/100ml_glass.svg', 100),
                        _buildDrinkOption(
                            'assets/images/glass/150ml_glass.svg', 150),
                        _buildDrinkOption(
                            'assets/images/glass/200ml_glass.svg', 200),
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

  Widget _buildDrinkOption(String gambar, double amount) {
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
              height: 50,
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
