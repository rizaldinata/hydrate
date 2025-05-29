import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart';
import 'package:hydrate/presentation/widgets/Main/animated_progress_circle.dart';
import 'package:hydrate/presentation/widgets/Main/customInputWater_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart'; // UI Controller
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/services/notification_settings_service.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({
    super.key,
  });

  @override
  State<HomeScreens> createState() => HomeScreensState();
}

class HomeScreensState extends State<HomeScreens>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // <= Perubahan di sini {
  late AudioPlayer _audioPlayer;
  late final HomeController _uiController;
  final PageController _pageController = PageController();

  double currentIntake = 0;
  double previousIntake = 0;
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);
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
  bool _isButtonCooldown = false;

  static const String _endTimeKey = 'countdown_end_time';
  Map<double, double> _glassOffsets = {};

  final NotificationSettingsService _notificationSettingsService =
      NotificationSettingsService();
  final AppEventBus _eventBus = AppEventBus();
  StreamSubscription<AppEvent>? _eventSubscription;

  bool _isHomeScreenLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationController.initializeLocalNotifications();
    NotificationController.startListeningNotificationEvents();
    _uiController = HomeController();
    _penggunaController = PenggunaController();
    _uiController.initAnimation(this);
    _pageController.addListener(() => setState(() {}));
    _audioPlayer = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print("[HomeScreen - initState] Memanggil _fetchDataAndUpdateScreen untuk pemuatan awal.");
        _fetchDataAndUpdateScreen(forceTargetRecalculation: false);
      }
    });

    _eventSubscription = _eventBus.stream.listen((AppEvent event) {
      if (event.type == 'refresh_all' || event.type == 'refresh_home_page') {
        print("[HomeScreen - EventBus] Event '${event.type}' diterima. Memanggil _fetchDataAndUpdateScreen (force recalculate). Jam: ${DateTime.now()}");
        _fetchDataAndUpdateScreen(forceTargetRecalculation: true);
      }
    });
  }

  @override
  void dispose() {
    print("[HomeScreen] dispose called");
    _audioPlayer.dispose();
    _countdownTimer?.cancel();
    _eventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _uiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataAndUpdateScreen({bool forceTargetRecalculation = false}) async {
    if (!mounted) return;
    
    setState(() {
      _isHomeScreenLoading = true;
    });

    print("[HomeScreen - _fetchDataAndUpdateScreen] Memulai. Force recalculate: $forceTargetRecalculation. Jam: ${DateTime.now()}");
    
    final session = SessionManager();
    final localUserId = await session.getUserId();

    if (localUserId != null) {
      if (mounted) {
        // Pastikan idPengguna di state terisi
        if (idPengguna != localUserId) { // Hanya update jika berbeda atau null
          setState(() {
            idPengguna = localUserId;
          });
        }

        // 1. Muat data pengguna untuk tampilan (misal nama)
        await _loadUserDisplayData(localUserId);
        
        // 2. Minta TargetHidrasiController untuk menginisialisasi atau menghitung ulang target
        final targetController = Provider.of<TargetHidrasiController>(context, listen: false);
        if (forceTargetRecalculation) {
          print("[HomeScreen] Meminta TargetHidrasiController untuk MEMAKSA kalkulasi ulang target untuk userId: $localUserId");
          await targetController.forceRecalculateAndUpdateTargetAfterProfileChange(localUserId);
        } else {
          print("[HomeScreen] Meminta TargetHidrasiController untuk INISIALISASI target (jika perlu) untuk userId: $localUserId");
          await targetController.initializeOrRefreshDailyTarget(localUserId);
        }
        
        // 3. Muat data intake harian (ini akan menggunakan target terbaru dari controller untuk persentase)
        await _loadTodayIntake(localUserId); 
        
        // 4. Muat ulang state countdown UI timer notifikasi
        await _loadCountdownState(); 

        // --- KIRIM EVENT SETELAH SEMUA PROSES UPDATE TARGET DI HOMESCREEN SELESAI ---
        // Ini akan memberi tahu MainScreen untuk me-refresh halaman Statistik
        _eventBus.fire('home_target_processing_complete');
        print("[HomeScreen - _fetchDataAndUpdateScreen] Mengirim event 'home_target_processing_complete'. Jam: ${DateTime.now()}");
        // ---------------------------------------------------------------------------------
      }
    } else {
      print("[HomeScreen - _fetchDataAndUpdateScreen] UserId tidak ditemukan.");
      if (mounted) {
        setState(() {
          idPengguna = null;
          namaPengguna = null;
          currentIntake = 0;
          _valueNotifier.value = 0;
          // Provider.of<TargetHidrasiController>(context, listen: false).resetTarget(); // Jika ada fungsi reset
        });
      }
    }

    if (mounted) {
      setState(() { _isHomeScreenLoading = false; });
    }
  }

  void refresh() {
    print("[HomeScreen - refresh] Metode refresh() publik dipanggil. Memanggil _fetchDataAndUpdateScreen (force recalculate). Jam: ${DateTime.now()}");
    _fetchDataAndUpdateScreen(forceTargetRecalculation: true);
  }

  Future<void> _loadUserDisplayData(int currentUserId) async {
    try {
      print("[HomeScreen - _loadUserDisplayData] Memulai untuk userId: $currentUserId. Jam: ${DateTime.now()}");
      final pengguna = await _penggunaController.getPenggunaById(currentUserId);
      if (mounted && pengguna != null) {
        setState(() {
          namaPengguna = pengguna.nama;
        });
        print("[HomeScreen - _loadUserDisplayData] Nama pengguna dimuat: ${pengguna.nama}");
      } else if (pengguna == null) {
        print("[HomeScreen - _loadUserDisplayData] Pengguna tidak ditemukan untuk userId: $currentUserId");
      }
    } catch (e) {
      print("[HomeScreen - _loadUserDisplayData] Error: $e");
    }
  }

  Future<void> _loadTodayIntake(int currentUserId) async {
    if (!mounted) return;
    
    final targetController = Provider.of<TargetHidrasiController>(context, listen: false);
    double actualTargetForCalculation = targetController.currentDailyTargetMl; 
    if (actualTargetForCalculation <= 0) {
        // Jika controller belum punya target valid, coba ambil dari repo sebagai fallback sementara
        // Namun, idealnya controller sudah diinisialisasi dengan benar oleh _fetchDataAndUpdateScreen
        final targetDataMap = await _targetHidrasiRepository.getTargetHidrasiHarian(currentUserId, todayDate);
        actualTargetForCalculation = (targetDataMap?['target_hidrasi'] as num?)?.toDouble() ?? 2500.0;
        print("[HomeScreen - _loadTodayIntake] Menggunakan target fallback dari repo: $actualTargetForCalculation");
    }
    if (actualTargetForCalculation <= 0) actualTargetForCalculation = 2500.0;

    try {
      final targetHarianData = await _targetHidrasiRepository.getTargetHidrasiHarian(currentUserId, todayDate);
      double totalHidrasi = 0.0;

      if (targetHarianData != null) {
        totalHidrasi = (targetHarianData['total_hidrasi_harian'] as num?)?.toDouble() ?? 0.0;
      }
      
      double persentaseHidrasi = (actualTargetForCalculation > 0) 
          ? (totalHidrasi / actualTargetForCalculation) * 100 
          : 0.0;

      if (mounted) {
        setState(() {
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi.clamp(0.0, 100.0);
          // Variabel 'target' lokal tidak lagi di-set di sini. UI akan menggunakan dari Provider.
        });
      }
      print("[HomeScreen - _loadTodayIntake] Data hidrasi dimuat: $totalHidrasi mL dari target $actualTargetForCalculation mL (${_valueNotifier.value.toStringAsFixed(1)}%)");
    } catch (e) {
      print("[HomeScreen - _loadTodayIntake] Error: $e");
       if (mounted) {
        setState(() {
          currentIntake = 0;
          _valueNotifier.value = 0;
        });
      }
    }
  }

  Future<void> _playDrinkingSound() async {
    try {
      print("Attempting to play drinking sound...");
      await _audioPlayer.stop();
      print("AudioPlayer stopped successfully");

      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
      print("Sound playing started successfully");
    } catch (e) {
      print("Error playing sound: $e");
      print("Error details: ${e.toString()}");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("[HomeScreen] App lifecycle state berubah: $state");
    if (state == AppLifecycleState.resumed) {
      print("[HomeScreen] App resumed. Merefresh intake dan countdown timer.");
      if (idPengguna != null) {
        _loadTodayIntake(idPengguna!); 
      }
      _loadCountdownState();        
    } else if (state == AppLifecycleState.paused) {
      _saveCurrentTimerState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("[HomeScreen] didChangeDependencies called.");
  }

  void _startTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        // Check if widget is still mounted
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
          _isCountdownActive =
              false; // Timer expired, but user might have drunk
        });
        // Check if user has had water today to show "SAATNYA MINUM!"
        if (idPengguna != null) {
          final targetHarian = await _targetHidrasiRepository
              .getTargetHidrasiHarian(idPengguna!, todayDate);
          if (targetHarian != null &&
              (targetHarian['total_hidrasi_harian'] ?? 0) > 0) {
            if (!mounted) return;
            setState(() {
              _isCountdownActive =
                  true; // This will make UI show "SAATNYA MINUM!"
            });
          }
        }
      }
    } else {
      if (idPengguna != null) {
        final targetHarian = await _targetHidrasiRepository
            .getTargetHidrasiHarian(idPengguna!, todayDate);
        if (!mounted) return;
        if (targetHarian != null &&
            (targetHarian['total_hidrasi_harian'] ?? 0) > 0) {
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
    if (_remainingTime > Duration.zero && _isCountdownActive) {
      // Only save if timer is active and has time
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final endTimeMillis = now + _remainingTime.inMilliseconds;
      await prefs.setInt(_endTimeKey, endTimeMillis);
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
      final targetControllerProvider = Provider.of<TargetHidrasiController>(context, listen: false);

      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
        targetController: targetControllerProvider,
      );

      previousIntake = currentIntake;
      double newTotalIntake = currentIntake + amount;

      double currentTargetForCalc = targetControllerProvider.currentDailyTargetMl;
      if (currentTargetForCalc <= 0) currentTargetForCalc = 2500.0;

      // Optimistic UI update
      if (mounted) {
        setState(() {
          currentIntake = newTotalIntake;
          _valueNotifier.value = currentTargetForCalc > 0 
              ? min(100, (currentIntake / currentTargetForCalc) * 100) 
              : 0;
        });
      }

      // Fetch fresh data to confirm
      await _loadTodayIntake(idPengguna!); // Muat ulang intake untuk memastikan data & persentase sinkron
      _eventBus.fire('refresh_statistics'); 

    } catch (e) {
      print("Gagal menyimpan riwayat: $e");
      if (mounted) {
        final targetControllerProvider = Provider.of<TargetHidrasiController>(context, listen: false);
        double currentTargetForCalc = targetControllerProvider.currentDailyTargetMl;
        if (currentTargetForCalc <= 0) currentTargetForCalc = 2500.0;

        setState(() {
          currentIntake = previousIntake; 
          _valueNotifier.value = currentTargetForCalc > 0 
              ? min(100, (currentIntake / currentTargetForCalc) * 100) 
              : 0;
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
      final targetController = context.read<TargetHidrasiController>();
      checkTargetAndShowAlert(context, targetController.currentDailyTargetMl);
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

  void _startCountdown() async {
    await NotificationController.cancelScheduledNotifications(); // Tambahkan await

    int reminderIntervalInSeconds = await _notificationSettingsService.getNotificationInterval();

    await NotificationController.schedulePeriodicHydrationNotification(
      intervalInSeconds: reminderIntervalInSeconds, 
    );

    _countdownTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _remainingTime = Duration(seconds: reminderIntervalInSeconds);
      _isCountdownActive = true;
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimeMillis = now + _remainingTime.inMilliseconds;

    SharedPreferences.getInstance().then((prefs) async { // jadikan async
      await prefs.setInt(_endTimeKey, endTimeMillis);
      await prefs.setBool('timer_has_started', true);
    });

    _startTimer();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showAddedWaterPopup(BuildContext context, double amount) {
    if (!mounted) return;
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: this, // Membutuhkan SingleTickerProviderStateMixin
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
                          'assets/images/berhasil.svg', // Pastikan path ini benar
                          colorFilter: const ColorFilter.mode(
                              Color(0xFF3EDAC0), BlendMode.srcIn),
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
          if (overlayEntry?.mounted ?? false) {
            overlayEntry?.remove();
          }
          animationController.dispose();
        }).catchError((e) {
          print("Error reversing animation or removing overlay: $e");
          if (overlayEntry?.mounted ?? false) {
            overlayEntry?.remove();
          }
          animationController.dispose();
        });
      } else if (!mounted) {
        if (overlayEntry?.mounted ?? false) {
          overlayEntry?.remove();
        }
        animationController.dispose();
      }
    });
  }

  //? fungsi alert untuk ucapan selamat
  bool hasShownCongrats = false;
  void checkTargetAndShowAlert(BuildContext context, double currentTargetFromController) {
    if (!mounted) return;

    // Reset if intake drops below target (e.g. data correction)
    if (currentIntake < currentTargetFromController) {
      hasShownCongrats = false;
    }

    if (currentIntake >= currentTargetFromController && !hasShownCongrats && currentTargetFromController > 0) {
      hasShownCongrats = true;

      final confettiController =
          ConfettiController(duration: const Duration(seconds: 3));

      if (mounted) confettiController.play();

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
                if (mounted) // Only show confetti if mounted
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
                            if (mounted)
                              confettiController.dispose(); // Dispose only if mounted
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
        if (mounted &&
            confettiController.state == ConfettiControllerState.playing) {
          confettiController.dispose();
        }
      });
    }
  }

  String truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;

    int lastSpace = name.substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace == -1 || lastSpace < maxLength - 5) {
      // Avoid very short first part
      return "${name.substring(0, maxLength - 3)}...";
    } else {
      return "${name.substring(0, lastSpace)}...";
    }
  }

  void _startDrinkingWithCooldown(double amount) {
    if (_isButtonCooldown) {
      _showOverlayError('Tunggu 3 detik sebelum minum lagi!');
      return;
    } else {
      _showOverlaySuccess('Berhasil minum $amount ml!');
    }

    setState(() => _isButtonCooldown = true);
    _animateGlass(amount);

    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isButtonCooldown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetController = context.watch<TargetHidrasiController>();
    double uiTargetMl = targetController.currentDailyTargetMl;
    bool isTargetControllerLoading = targetController.isLoadingTarget;

    bool isOverallLoading = _isHomeScreenLoading || isTargetControllerLoading;

    print("[HomeScreen Build] idPengguna: $idPengguna, namaPengguna: $namaPengguna, _isHomeScreenLoading: $_isHomeScreenLoading, isTargetControllerLoading: $isTargetControllerLoading, isOverallLoading: $isOverallLoading");

    if (idPengguna == null || namaPengguna == null || isOverallLoading) {
      // Check idPengguna as well
      return Scaffold(
        backgroundColor: Colors.blue[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (uiTargetMl > 0) {
        _valueNotifier.value = min(100, (currentIntake / uiTargetMl) * 100);
    } else {
        _valueNotifier.value = 0;
    }

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
                    currentIntake >= uiTargetMl && uiTargetMl > 0
                        ? "Pencapaianmu hari ini telah selesai."
                        : "Ayo selesaikan pencapaianmu hari ini!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentIntake >= uiTargetMl && uiTargetMl > 0
                          ? const Color(0xFF07BAE4)
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Lingkaran Proress
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: screenHeight * 0.2,
                  ),
                  AnimatedWaterProgressCircle(
                    currentIntake: currentIntake,
                    target: uiTargetMl,
                    screenWidth: screenWidth,
                  ),
                  // Padding(
                  //   padding: EdgeInsets.all(screenWidth * 0.1),
                  //   child: Center(
                  //       child: DashedCircularProgressBar.aspectRatio(
                  //     aspectRatio: 1,
                  //     valueNotifier: _valueNotifier,
                  //     progress: _valueNotifier.value > 100
                  //         ? 100
                  //         : _valueNotifier.value, // Cap progress at 100
                  //     startAngle: 230,
                  //     sweepAngle: 260,
                  //     foregroundColor: const Color(0xFF00A6FB),
                  //     backgroundColor: const Color(0xFFA1E3F9),
                  //     foregroundStrokeWidth: 15,
                  //     backgroundStrokeWidth: 15,
                  //     animation: true,
                  //     seekSize: 10,
                  //     seekColor: const Color(0xffeeeeee),
                  //     child: Center(
                  //       child: ValueListenableBuilder(
                  //         valueListenable: _valueNotifier,
                  //         builder: (_, double value, __) => Column(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             Text(
                  //               '${min(100, value.ceil())}%',
                  //               style: const TextStyle(
                  //                 color: Color(0xFF2F2E41),
                  //                 fontWeight: FontWeight.w300,
                  //                 fontSize: 40,
                  //               ),
                  //             ),
                  //             Row(
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               children: [
                  //                 Text(
                  //                   '${currentIntake.toInt()} mL',
                  //                   style: TextStyle(
                  //                     color:
                  //                         currentIntake >= target && target > 0
                  //                             ? Colors.blue
                  //                             : Colors.red,
                  //                     fontWeight: FontWeight.w600,
                  //                     fontSize: 16,
                  //                   ),
                  //                 ),
                  //                 Text(
                  //                   ' / ${target.toInt()} mL',
                  //                   style: const TextStyle(
                  //                     color: Color(0xFF2F2E41),
                  //                     fontWeight: FontWeight.w500,
                  //                     fontSize: 16,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   )),
                  // ),
                  Transform.translate(
                    offset: Offset(0, screenHeight * -0.05),
                    child: Container(
                      width: screenWidth * 0.75,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_isCountdownActive &&
                                  _remainingTime > Duration.zero)
                              ? [
                                  const Color(0xFF2AD1D1),
                                  const Color(0xFF2AD1D1),
                                ]
                              : [
                                  // Colors for "SAATNYA MINUM!" or when no timer
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
                            : ((_isCountdownActive && currentIntake > 0) ||
                                    (_isCountdownActive &&
                                        _remainingTime.inSeconds <=
                                            0)) // Show if active and intake > 0 OR active and time is up
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
                          color: const Color(0xFF2F2E41).withOpacity(0.1),
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
          onTap: () {
            if (_isButtonCooldown) {
              // Panggil fungsi popup peringatan kustom di sini
              _showWarningPopup(context, 'Tunggu 3 detik sebelum minum lagi!');
              return;
            }

            setState(() => _isButtonCooldown = true);

            _animateGlass(amount); // Pastikan fungsi ini ada

            // Panggil _showAddedWaterPopup jika logika penambahan air berhasil
            // Contoh: _showAddedWaterPopup(context, amount); setelah _animateGlass atau di dalamnya

            Timer(Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _isButtonCooldown = false);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            transform:
                Matrix4.translationValues(0, _glassOffsets[amount] ?? 0, 0),
            child: Opacity(
              opacity: _isButtonCooldown ? 0.5 : 1.0,
              child: SvgPicture.asset(
                // Atau Image.asset jika bukan SVG
                gambar,
                fit: BoxFit.scaleDown,
                height: 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${amount.toInt()} mL',
          style: TextStyle(
            fontSize: 12,
            color: _isButtonCooldown ? Colors.grey : Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _showWarningPopup(BuildContext context, String message) {
    if (!mounted) return;
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);
    // Pastikan TickerProvider tersedia, biasanya 'this' jika State menggunakan SingleTickerProviderStateMixin
    final animationController = AnimationController(
      vsync:
          this, // 'this' merujuk ke State object dengan SingleTickerProviderStateMixin
      duration: const Duration(milliseconds: 500),
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 50, // Posisi dari atas layar
          left: 20,
          right: 20,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1), // Muncul dari atas
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
                    // height: 60, // Bisa diatur otomatis atau fixed
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber[700]!
                          .withOpacity(0.95), // Warna kuning peringatan
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded, // Ikon peringatan
                          color: Colors.black87, // Warna ikon
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          // Gunakan Expanded agar teks bisa wrap jika panjang
                          child: Text(
                            message,
                            style: TextStyle(
                                color: Colors.black87, // Warna teks
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.left,
                          ),
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

    // Durasi popup peringatan tampil (misalnya 2 detik)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && animationController.status != AnimationStatus.dismissed) {
        animationController.reverse().then((value) {
          if (overlayEntry?.mounted ?? false) {
            overlayEntry?.remove();
          }
          animationController.dispose();
        }).catchError((e) {
          print("Error reversing animation or removing overlay: $e");
          if (overlayEntry?.mounted ?? false) {
            overlayEntry?.remove();
          }
          animationController.dispose();
        });
      } else if (!mounted) {
        if (overlayEntry?.mounted ?? false) {
          overlayEntry?.remove();
        }
        animationController.dispose();
      }
    });
  }

  void _showAddWaterModal(BuildContext context) {
    int selectedWater = 250;
    final targetControllerProvider = Provider.of<TargetHidrasiController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
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
                await _riwayatHidrasiController.tambahRiwayatHidrasi(
                  fkIdPengguna: idPengguna!,
                  jumlahHidrasi: newSelectedWater.toDouble(),
                  targetController: targetControllerProvider,
                );
                if (idPengguna != null) {
                  await _loadTodayIntake(idPengguna!);
                }
                _eventBus.fire('refresh_statistics');
              } catch (e) {
                print("Error saat menambah air: $e");
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal menyimpan data minum.")),
                    );
                  }
              }

              _startCountdown();
              _startDrinkingWithCooldown(newSelectedWater.toDouble()); 
              Navigator.pop(bottomSheetContext);
            },
          ),
        );
      },
    );
  }

  // Fungsi untuk menampilkan overlay (error/sukses)
  void _showOverlay(String message, Color color) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Overlay",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF2F2E41),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

// Fungsi khusus untuk overlay error
  void _showOverlayError(String message) {
    _showOverlay(message, Colors.red);
  }

// Fungsi khusus untuk overlay sukses
  void _showOverlaySuccess(String message) {
    _showOverlay(message, Colors.white.withOpacity(0.90));
  }
}
