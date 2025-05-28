import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart';
import 'package:hydrate/presentation/widgets/Main/customInputWater_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart'; // Ditambahkan
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
  late final PenggunaController _penggunaController;
  late final TargetHidrasiController _targetHidrasiController; // Ditambahkan
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
  static const int _countdownDurationInSeconds = 15; // 1 jam, contoh saja, sesuaikan
  static const String _endTimeKey = 'countdown_end_time';

  Map<double, double> _glassOffsets = {};
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
    _targetHidrasiController = TargetHidrasiController(); // Inisialisasi
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
      _loadCountdownState();
      setState(() {});
    } else if (state == AppLifecycleState.paused) {
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

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { // Check if widget is still mounted
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingTime > Duration.zero) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          timer.cancel();
          // NotificationController.createNewNotification(); // Consider calling this only if app is in background
        }
      });
    });
  }

  Future<void> _loadCountdownState() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt(_endTimeKey);
    final hasStartedTimer = prefs.getBool('timer_has_started') ?? false;

    if (!mounted) return;

    if (!hasStartedTimer) {
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
        setState(() {
          _remainingTime = _endTime!.difference(now);
          _isCountdownActive = true;
        });
        _startTimer(); 
      } else {
        setState(() {
          _remainingTime = Duration.zero;
          _isCountdownActive = false; // Timer expired, but user might have drunk
        });
         // Check if user has had water today to show "SAATNYA MINUM!"
        if (idPengguna != null) {
            final targetHarian = await _targetHidrasiRepository.getTargetHidrasiHarian(idPengguna!, todayDate);
            if (targetHarian != null && (targetHarian['total_hidrasi_harian'] ?? 0) > 0) {
                 if (!mounted) return;
                setState(() {
                    _isCountdownActive = true; // This will make UI show "SAATNYA MINUM!"
                });
            }
        }
      }
    } else {
       if (idPengguna != null) {
            final targetHarian = await _targetHidrasiRepository.getTargetHidrasiHarian(idPengguna!, todayDate);
             if (!mounted) return;
            if (targetHarian != null && (targetHarian['total_hidrasi_harian'] ?? 0) > 0) {
                setState(() {
                    _remainingTime = Duration.zero;
                    _isCountdownActive = true; 
                });
            } else {
                setState(() {
                    _remainingTime = Duration.zero;
                    _isCountdownActive = false;
                });
            }
       } else {
            if (!mounted) return;
            setState(() {
                _remainingTime = Duration.zero;
                _isCountdownActive = false;
            });
       }
    }
  }

  Future<void> _saveCurrentTimerState() async {
    if (_remainingTime > Duration.zero && _isCountdownActive) { // Only save if timer is active and has time
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final endTimeMillis = now + _remainingTime.inMilliseconds;
      await prefs.setInt(_endTimeKey, endTimeMillis);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final session = SessionManager();
      final userId = await session.getUserId();

      if (!mounted) return;

      if (userId != null) {
        final pengguna = await _penggunaController.getPenggunaById(userId);

        if (!mounted) return;

        if (pengguna != null) {
          _hydrationCalculator = HydrationCalculator(penggunaId: userId);

          setState(() {
            idPengguna = userId;
            namaPengguna = pengguna.nama;
          });

          await _initializeTarget();
          await _loadTodayIntake(); 
        } else {
           print("Pengguna not found for userId: $userId");
           // Handle case where user data might be missing or corrupted
           // Maybe navigate to a login/setup screen
        }
      } else {
        print("UserId not found in session.");
        // Handle case where user is not logged in
        // Maybe navigate to a login screen
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _initializeTarget() async {
    if (_hasInitializedTarget || idPengguna == null) return;
    

    try {
      await _hydrationCalculator.initializeData(idPengguna!);
      final targetHidrasi =
          _hydrationCalculator.calculateDailyWaterIntake() * 1000;
      
      if (!mounted) return;
      _hasInitializedTarget = true; // Set this earlier to prevent re-entry if async operations are slow

      setState(() {
        target = targetHidrasi;
      });

      await _checkAndCreateTodayTarget();

      print("Target hidrasi diinisialisasi: $target mL");
    } catch (e) {
      print("Error initializing target: $e");
       _hasInitializedTarget = false; // Reset if initialization failed
    }
  }

  Future<void> _checkAndCreateTodayTarget() async {
    if (idPengguna == null) return;

    try {
      final targetExists = await _targetHidrasiRepository
          .checkTargetHidrasiExists(idPengguna!, todayDate);
      
      if (!mounted) return;

      if (!targetExists) {
        double currentCalculatedTarget = target; // Use the already calculated target
        if (currentCalculatedTarget <= 0) { // Recalculate if somehow it's still 0
          await _hydrationCalculator.initializeData(idPengguna!);
          currentCalculatedTarget = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
           if (!mounted) return;
           setState(() {
             target = currentCalculatedTarget;
           });
        }

        await _targetHidrasiRepository.createTargetHidrasi(
            idPengguna!, currentCalculatedTarget, todayDate, 0.0);
        print(
            "Target hidrasi baru dibuat untuk tanggal $todayDate: $currentCalculatedTarget mL");
      } else {
        // If target exists, ensure its value is up-to-date (e.g., if user profile changed)
        await _targetHidrasiRepository.updateTargetHidrasiValue(
            idPengguna!, todayDate);
        print(
            "Target hidrasi untuk tanggal $todayDate sudah ada dan diperbarui jika perlu");

        final updatedTargetData = await _targetHidrasiRepository
            .getTargetHidrasiHarian(idPengguna!, todayDate);
        
        if (!mounted) return;

        if (updatedTargetData != null &&
            (updatedTargetData['target_hidrasi'] ?? 0) > 0) {
          setState(() {
            target = updatedTargetData['target_hidrasi'];
          });
          print("Target hidrasi dari DB: $target mL");
        }
      }
    } catch (e) {
      print("Error saat memeriksa/membuat target hidrasi: $e");
      // Fallback: try to ensure target is set based on calculation
      try {
        if (idPengguna != null) {
            await _hydrationCalculator.initializeData(idPengguna!);
            final calculatedTarget = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
            if (!mounted) return;
            setState(() {
                target = calculatedTarget;
            });
            print("Target hidrasi (recovery): $target mL");
        }
      } catch (e2) {
        print("Error saat menghitung target hidrasi (recovery): $e2");
      }
    }
  }

  Future<void> _loadTodayIntake() async {
    if (idPengguna == null) return;

    try {
      // Ensure target is initialized before loading intake that depends on it
      if (target <= 0) {
          await _initializeTarget(); // This will also call _checkAndCreateTodayTarget
          if (!mounted || target <= 0) return; // if target still not set, abort
      }


      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(idPengguna!, todayDate);
      
      if (!mounted) return;

      if (targetHarian != null) {
        double dbTargetHidrasi = targetHarian['target_hidrasi'] ?? 0.0;
        double totalHidrasi = targetHarian['total_hidrasi_harian'] ?? 0.0;
        double persentaseHidrasi = targetHarian['persentase_hidrasi'] ?? 0.0;

        setState(() {
          target = dbTargetHidrasi > 0 ? dbTargetHidrasi : target; // Prioritize DB target if valid
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi > 100 ? 100 : persentaseHidrasi; // Cap at 100
        });

        print(
            "Data hidrasi dimuat: $totalHidrasi mL dari target $target mL (${_valueNotifier.value.toStringAsFixed(1)}%)");

        if (totalHidrasi > 0) {
          final prefs = await SharedPreferences.getInstance();
          final hasStartedTimer = prefs.getBool('timer_has_started') ?? false;
          if (!hasStartedTimer) {
            prefs.setBool('timer_has_started', true);
          }
          // Logic for "SAATNYA MINUM!" if timer expired but water was drunk
          final endTimeMillis = prefs.getInt(_endTimeKey);
          if (endTimeMillis == null || DateTime.fromMillisecondsSinceEpoch(endTimeMillis).isBefore(DateTime.now())) {
             if (!mounted) return;
            setState(() {
              _isCountdownActive = true; // Show "SAATNYA MINUM!"
              _remainingTime = Duration.zero;
            });
          } else {
            _loadCountdownState(); // Reload to sync timer if it was running
          }
        } else {
           if (!mounted) return;
           setState(() { // No intake yet, so no active countdown message unless started by adding water
             _isCountdownActive = false;
             _remainingTime = Duration.zero;
           });
        }
      } else {
        // No target_hidrasi record for today, this should have been created by _checkAndCreateTodayTarget
        // This might happen if _checkAndCreateTodayTarget fails or runs after this.
        // For safety, set intake to 0.
        print("Peringatan: Record target_hidrasi tidak ditemukan untuk hari ini setelah pengecekan.");
        setState(() {
          currentIntake = 0;
          _valueNotifier.value = 0;
          // target should be set by _initializeTarget
        });
      }
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");
    }
  }

  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User tidak teridentifikasi!")),
        );
      }
      return;
    }

    _playDrinkingSound();

    try {
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
        targetController: _targetHidrasiController, // Ditambahkan
      );

      // Data should be re-fetched or updated by TargetHidrasiController's notifyListeners
      // For immediate UI update, we can optimistically update and then rely on listener or re-fetch
      
      previousIntake = currentIntake;
      double newTotalIntake = currentIntake + amount;

      // Optimistic UI update
      if(mounted) {
        setState(() {
            currentIntake = newTotalIntake;
            _valueNotifier.value = target > 0 ? min(100, (currentIntake / target) * 100) : 0;
        });
      }
      
      // Fetch fresh data to confirm
      await _loadTodayIntake(); 


      _eventBus.fire('refresh_statistics');
    } catch (e) {
      print("Gagal menyimpan riwayat: $e");
      if (mounted) {
        // Revert optimistic update if error
        setState(() {
            currentIntake = previousIntake; // Revert to previous
             _valueNotifier.value = target > 0 ? min(100, (currentIntake / target) * 100) : 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Gagal menyimpan data: ${e.toString().substring(0, min(50, e.toString().length))}..."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    _animateGlassMovement(amount);
    _startCountdown();
    if (mounted) {
      _showAddedWaterPopup(context, amount);
      checkTargetAndShowAlert(context);
    }
  }

  void _animateGlassMovement(double amount) {
    if (!mounted) return;
    setState(() => _glassOffsets[amount] = -10);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _glassOffsets[amount] = 0);
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (!mounted) return;
    
    setState(() {
      _remainingTime = const Duration(seconds: _countdownDurationInSeconds);
      _isCountdownActive = true;
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimeMillis = now + _remainingTime.inMilliseconds;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_endTimeKey, endTimeMillis);
      prefs.setBool('timer_has_started', true);
    });

    _startTimer(); // Call the unified timer start function
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showAddedWaterPopup(BuildContext context, double amount) {
    if(!mounted) return;
    OverlayEntry? overlayEntry; // Make it nullable
    final overlay = Overlay.of(context);
    // Ensure TickerProvider is available, typically 'this' if State uses SingleTickerProviderStateMixin
    final animationController = AnimationController(
      vsync: this, // Assuming HomeScreensState uses SingleTickerProviderStateMixin
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
              opacity: 1.0, // Will be managed by controller if needed, but simple fade in is fine
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
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/berhasil.svg',
                          colorFilter: const ColorFilter.mode(Color(0xFF3EDAC0), BlendMode.srcIn), // Apply color filter
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Berhasil menambahkan air !",
                          style: TextStyle(
                              color: Color(0xFF2F2E41),
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

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && animationController.status != AnimationStatus.dismissed) {
        animationController.reverse().then((value) {
          if (overlayEntry?.mounted ?? false) { // Check if mounted before removing
             overlayEntry?.remove();
          }
          animationController.dispose(); // Dispose controller after use
        }).catchError((e) {
            print("Error reversing animation or removing overlay: $e");
            if (overlayEntry?.mounted ?? false) {
                overlayEntry?.remove();
            }
            animationController.dispose();
        });
      } else if (!mounted) {
         // If not mounted, just try to remove and dispose
         if (overlayEntry?.mounted ?? false) {
            overlayEntry?.remove();
         }
         animationController.dispose();
      }
    });
  }

  //? fungsi alert untuk ucapan selamat
  bool hasShownCongrats = false;
  void checkTargetAndShowAlert(BuildContext context) {
    if(!mounted) return;

    // Reset if intake drops below target (e.g. data correction)
    if (currentIntake < target) {
        hasShownCongrats = false;
    }

    if (currentIntake >= target && !hasShownCongrats && target > 0) { // ensure target is positive
      hasShownCongrats = true;

      final confettiController =
          ConfettiController(duration: const Duration(seconds: 3));
      
      // Play confetti only if mounted
      if(mounted) confettiController.play();


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
                if(mounted) // Only show confetti if mounted
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
                            if(mounted) confettiController.dispose(); // Dispose only if mounted
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
      ).then((_) {
          // Ensure controller is disposed if dialog is dismissed by other means
          if(mounted && confettiController.state == ConfettiControllerState.playing) {
              confettiController.dispose();
          }
      });
    }
  }

  String truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;

    int lastSpace = name.substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace == -1 || lastSpace < maxLength - 5) { // Avoid very short first part
      return "${name.substring(0, maxLength - 3)}...";
    } else {
      return "${name.substring(0, lastSpace)}...";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (idPengguna == null || namaPengguna == null) { // Check idPengguna as well
      return Scaffold(
        backgroundColor: Colors.blue[50],
        body: const Center(
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
                      "Hai, ${truncateName(namaPengguna!, 20)}", // namaPengguna is now checked for null
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    currentIntake >= target && target > 0 // ensure target is positive
                        ? "Pencapaianmu hari ini telah selesai."
                        : "Ayo selesaikan pencapaianmu hari ini!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentIntake >= target && target > 0
                          ? const Color(0xFF07BAE4)
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
                      progress: _valueNotifier.value > 100 ? 100 : _valueNotifier.value, // Cap progress at 100
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
                                '${min(100, value.ceil())}%',
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
                                      color: currentIntake >= target && target > 0
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
                          colors: (_isCountdownActive && _remainingTime > Duration.zero)
                              ? [
                                  const Color(0xFF2AD1D1),
                                  const Color(0xFF2AD1D1),
                                ]
                              : [ // Colors for "SAATNYA MINUM!" or when no timer
                                  const Color(0xFF4EE9BD),
                                  const Color(0xFF07BAE4),
                                ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (_isCountdownActive && _remainingTime.inSeconds > 0)
                            ? "Hidrasi selanjutnya ${_formatTime(_remainingTime)}"
                            : ((_isCountdownActive && currentIntake > 0) || (_isCountdownActive && _remainingTime.inSeconds <=0)) // Show if active and intake > 0 OR active and time is up
                                ? "SAATNYA MINUM!"
                                : "Tekan gelas untuk minum!", // Default when no timer and no intake
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
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2F2E41)
                              .withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(1, 2),
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
                                heroTag: "addWaterHome", // Unique heroTag
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
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 5),
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

  void _showAddWaterModal(BuildContext context) {
  int selectedWater = 250;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddWaterModalContent(
          selectedWater: selectedWater,
          idPengguna: idPengguna,
          onWaterAdded: (newSelectedWater) async {
          _playDrinkingSound();

          setState(() {
            selectedWater = newSelectedWater;
          });

          try {
            // Save hydration record
            await _riwayatHidrasiController.tambahRiwayatHidrasi(
              fkIdPengguna: idPengguna!,
              jumlahHidrasi: selectedWater.toDouble(),
              targetController: _targetHidrasiController,
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
        ),
      );
    },
  );
}

}
