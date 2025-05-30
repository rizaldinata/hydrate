import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart';
import 'package:hydrate/presentation/widgets/Main/animated_progress_circle.dart';
import 'package:hydrate/presentation/widgets/Main/customInputWater_widget.dart'; // Pastikan path ini benar
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
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
  late AudioPlayer _audioPlayer;
  late final HomeController _uiController;
  final PageController _pageController = PageController();

  double currentIntake = 0;
  double previousIntake = 0;
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0); // Untuk DashedCircularProgressBar jika digunakan
  late final PenggunaController _penggunaController;
  int? idPengguna;
  String? namaPengguna;

  final RiwayatHidrasiController _riwayatHidrasiController =
      RiwayatHidrasiController();
  final TargetHidrasiRepository _targetHidrasiRepository =
      TargetHidrasiRepository();

  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7))); //WIB

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
    _uiController.initAnimation(this); // Untuk animasi jika ada di HomeController
    _pageController.addListener(() => setState(() {}));
    _audioPlayer = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDataAndUpdateScreen(forceTargetRecalculation: false);
      }
    });

    _eventSubscription = _eventBus.stream.listen((AppEvent event) {
      if (event.type == 'refresh_all' || event.type == 'refresh_home_page') {
        _fetchDataAndUpdateScreen(forceTargetRecalculation: true);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _countdownTimer?.cancel();
    _eventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _uiController.dispose();
    _pageController.dispose();
    // Make sure all AnimationControllers are disposed in their respective popup closing logic
    super.dispose();
  }

  Future<void> _fetchDataAndUpdateScreen(
      {bool forceTargetRecalculation = false}) async {
    if (!mounted) return;
    setState(() => _isHomeScreenLoading = true);

    final session = SessionManager();
    final localUserId = await session.getUserId();

    if (localUserId != null) {
      if (mounted) {
        if (idPengguna != localUserId) {
          setState(() => idPengguna = localUserId);
        }
        await _loadUserDisplayData(localUserId);

        final targetController = Provider.of<TargetHidrasiController>(context, listen: false);
        if (forceTargetRecalculation) {
          await targetController.forceRecalculateAndUpdateTargetAfterProfileChange(localUserId);
        } else {
          await targetController.initializeOrRefreshDailyTarget(localUserId);
        }

        await _loadTodayIntake(localUserId); // Muat intake setelah target mungkin diperbarui
        await _loadCountdownState();

        _eventBus.fire('home_target_processing_complete');
      }
    } else {
      if (mounted) {
        setState(() {
          idPengguna = null;
          namaPengguna = null;
          currentIntake = 0;
          _valueNotifier.value = 0;
          // Mungkin reset state lain jika diperlukan
        });
      }
    }

    if (mounted) {
      setState(() => _isHomeScreenLoading = false);
    }
  }

  void refresh() {
    _fetchDataAndUpdateScreen(forceTargetRecalculation: true);
  }

  Future<void> _loadUserDisplayData(int currentUserId) async {
    try {
      final pengguna = await _penggunaController.getPenggunaById(currentUserId);
      if (mounted && pengguna != null) {
        setState(() => namaPengguna = pengguna.nama);
      }
    } catch (e) {
      print("[HomeScreen - _loadUserDisplayData] Error: $e");
      // Handle error, mungkin tampilkan pesan ke user
    }
  }

  Future<void> _loadTodayIntake(int currentUserId) async {
    if (!mounted) return;

    final targetController = Provider.of<TargetHidrasiController>(context, listen: false);
    double actualTargetForCalculation = targetController.currentDailyTargetMl;

    // Fallback jika target dari controller masih 0 (misal, baru login & kalkulasi belum selesai sempurna)
    if (actualTargetForCalculation <= 0) {
      final targetDataMap = await _targetHidrasiRepository.getTargetHidrasiHarian(currentUserId, todayDate);
      actualTargetForCalculation = (targetDataMap?['target_hidrasi'] as num?)?.toDouble() ?? 2500.0;
    }
    // Ultimate fallback jika semua gagal
    if (actualTargetForCalculation <= 0) actualTargetForCalculation = 2500.0;


    try {
      final targetHarianData = await _targetHidrasiRepository.getTargetHidrasiHarian(currentUserId, todayDate);
      double totalHidrasi = (targetHarianData?['total_hidrasi_harian'] as num?)?.toDouble() ?? 0.0;
      
      double persentaseHidrasi = (actualTargetForCalculation > 0)
          ? (totalHidrasi / actualTargetForCalculation) * 100
          : 0.0;

      if (mounted) {
        setState(() {
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi.clamp(0.0, 100.0); // Untuk DashedCircularProgressBar
        });
      }
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
      await _audioPlayer.stop(); // Hentikan pemutaran sebelumnya jika ada
      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (idPengguna != null) {
        _loadTodayIntake(idPengguna!); // Refresh data saat app kembali aktif
      }
      _loadCountdownState(); // Juga refresh state countdown
    } else if (state == AppLifecycleState.paused) {
      _saveCurrentTimerState(); // Simpan state timer saat app dijeda
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bisa digunakan jika ada dependensi dari InheritedWidget yang berubah
  }

  void _startTimer() {
    _countdownTimer?.cancel(); // Batalkan timer sebelumnya jika ada
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          timer.cancel();
          // Aksi saat timer selesai, misal update teks "SAATNYA MINUM!"
          // _isCountdownActive mungkin perlu di-set ulang di sini tergantung logika
           if (mounted) { // Pastikan widget masih mounted
            setState(() {
                // Logika untuk menampilkan "SAATNYA MINUM!" sudah dihandle di _loadCountdownState dan build method
                // Cukup pastikan _isCountdownActive = true jika sudah pernah minum
            });
          }
        }
      });
    });
  }

  Future<void> _loadCountdownState() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt(_endTimeKey);
    final hasStartedTimerPreviously = prefs.getBool('timer_has_started') ?? false;

    if (!mounted) return;

    if (!hasStartedTimerPreviously) {
      setState(() {
        _remainingTime = Duration.zero;
        _isCountdownActive = false; // Belum ada aktivitas minum atau timer
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
        // Timer sudah berakhir
        setState(() {
          _remainingTime = Duration.zero;
          // Tetap aktifkan countdown UI untuk "SAATNYA MINUM!" jika sudah pernah minum
          _isCountdownActive = hasStartedTimerPreviously;
        });
      }
    } else {
      // Tidak ada endTime tersimpan, tapi timer mungkin sudah 'aktif' karena sudah minum.
      // Tampilkan "SAATNYA MINUM!" jika sudah ada intake.
        setState(() {
          _remainingTime = Duration.zero;
          _isCountdownActive = hasStartedTimerPreviously;
        });
    }
  }

  Future<void> _saveCurrentTimerState() async {
    // Hanya simpan jika timer sedang berjalan aktif dengan sisa waktu
    if (_isCountdownActive && _remainingTime.inSeconds > 0) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final endTimeMillis = now.millisecondsSinceEpoch + _remainingTime.inMilliseconds;
      await prefs.setInt(_endTimeKey, endTimeMillis);
      // 'timer_has_started' sudah di-set true saat _startCountdown
    }
  }

  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      if (mounted) _showOverlayError("User tidak teridentifikasi!");
      return;
    }

    _playDrinkingSound();
    previousIntake = currentIntake; // Simpan intake sebelum update

    try {
      final targetControllerProvider = Provider.of<TargetHidrasiController>(context, listen: false);
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
        targetController: targetControllerProvider, // Untuk update target jika perlu
      );
      
      // Setelah berhasil simpan, update UI dari data terbaru
      await _loadTodayIntake(idPengguna!); // Ini akan mengupdate currentIntake dan _valueNotifier
      _eventBus.fire('refresh_statistics');

    } catch (e) {
      print("Gagal menyimpan riwayat: $e");
      if (mounted) {
        // Kembalikan nilai intake jika gagal, lalu refresh dari DB
        currentIntake = previousIntake; 
        await _loadTodayIntake(idPengguna!); // Refresh untuk memastikan UI konsisten
        _showOverlayError("Gagal menyimpan data: ${e.toString().substring(0, min(50, e.toString().length))}...");
      }
    }

    _animateGlassMovement(amount); // Animasi visual gelas
    _startCountdown(); // Mulai atau restart countdown untuk pengingat berikutnya

    if (mounted) {
      final targetController = context.read<TargetHidrasiController>();
      checkTargetAndShowAlert(context, targetController.currentDailyTargetMl); // Cek apakah target tercapai
    }
  }

  void _animateGlassMovement(double amount) {
    if (!mounted) return;
    // Untuk animasi visual gelas (jika ada)
    setState(() => _glassOffsets[amount] = -10.0); // Contoh offset
    Future.delayed(const Duration(milliseconds: 300), () { // Durasi animasi
      if (mounted) setState(() => _glassOffsets[amount] = 0.0);
    });
  }

  void _startCountdown() async {
    await NotificationController.cancelScheduledNotifications(); // Batalkan notif terjadwal sebelumnya
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

    final now = DateTime.now();
    final endTimeMillis = now.millisecondsSinceEpoch + _remainingTime.inMilliseconds;

    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setInt(_endTimeKey, endTimeMillis);
      await prefs.setBool('timer_has_started', true); // Tandai bahwa timer sudah pernah dimulai
    });

    _startTimer(); // Mulai timer periodik untuk update UI
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
    // Each call to this function should have its own AnimationController
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: screenHeight * 0.06,
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
              .animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut)),
          child: AnimatedOpacity(
            opacity: 1.0, // Starts visible, fade out can be handled by reverse animation if needed
            duration: const Duration(milliseconds: 300), // Duration for opacity if animated
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.075,
                  padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.012,
                      horizontal: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: screenWidth * 0.01),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/berhasil.svg', // Pastikan path asset benar
                        colorFilter: const ColorFilter.mode(
                            Color(0xFF3EDAC0), BlendMode.srcIn),
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Text(
                        "Berhasil menambahkan air !",
                        style: TextStyle(
                            color: Color(0xFF2F2E41),
                            fontSize: screenWidth * 0.04,
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
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && animationController.status != AnimationStatus.dismissed) {
        animationController.reverse().whenComplete(() {
          if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
          animationController.dispose();
        });
      } else if(!mounted || (overlayEntry?.mounted ?? false && animationController.status == AnimationStatus.dismissed)) {
        if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
        animationController.dispose(); 
      }
    });
  }

  bool hasShownCongrats = false;
  void checkTargetAndShowAlert(BuildContext context, double currentTargetFromController) {
    if (!mounted) return;

    if (currentIntake < currentTargetFromController) {
      hasShownCongrats = false; // Reset jika intake turun di bawah target
    }

    if (currentIntake >= currentTargetFromController && !hasShownCongrats && currentTargetFromController > 0) {
      hasShownCongrats = true; // Tandai sudah ditampilkan agar tidak muncul berulang kali
      final confettiController = ConfettiController(duration: const Duration(seconds: 3));
      if (mounted) confettiController.play();

      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

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
                if (mounted) // Ensure confettiController is used only when mounted
                  ConfettiWidget(
                    confettiController: confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0.05,
                    numberOfParticles: 25,
                    colors: const [Colors.blue, Colors.pink, Colors.orange, Colors.green],
                  ),
                ScaleTransition(
                  scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                    backgroundColor: Colors.white,
                    title: Column(children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: screenWidth * 0.15),
                      SizedBox(height: screenHeight * 0.012),
                      Text('Selamat! 🎉', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ]),
                    content: Text('Kamu sudah mencapai target harianmu!', style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.center),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (mounted) confettiController.dispose(); // Dispose before pop
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                          ),
                          child: Text('Mantap!', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
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
        // Ensure confetti controller is disposed if dialog is dismissed externally
        // or if the widget is unmounted while it was playing.
        if (confettiController.state == ConfettiControllerState.playing) {
           confettiController.dispose();
        }
      });
    }
  }

  String truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;
    int lastSpace = name.substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace == -1 || lastSpace < maxLength - (maxLength > 5 ? 5: 0) ) { // Cegah error jika maxLength kecil
      return "${name.substring(0, maxLength - 3)}...";
    } else {
      return "${name.substring(0, lastSpace)}...";
    }
  }

  void _startDrinkingWithCooldown(double amount) {
    if (_isButtonCooldown) {
      _showWarningPopup(context, 'Tunggu beberapa saat sebelum minum lagi!');
      return;
    }
    
    // Tampilkan popup berhasil segera (UI feedback cepat)
    _showAddedWaterPopup(context, amount); 

    setState(() => _isButtonCooldown = true);
    
    // Proses utama (simpan data, update state, dll.)
    _animateGlass(amount); 

    Timer(const Duration(seconds: 3), () { // Durasi cooldown
      if (mounted) setState(() => _isButtonCooldown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetController = context.watch<TargetHidrasiController>();
    double uiTargetMl = targetController.currentDailyTargetMl;
    bool isTargetControllerLoading = targetController.isLoadingTarget;
    bool isOverallLoading = _isHomeScreenLoading || isTargetControllerLoading;

    if (isOverallLoading) { 
      return Scaffold(backgroundColor: Colors.blue[50], body: const Center(child: CircularProgressIndicator()));
    }
    if (idPengguna == null || namaPengguna == null) { // Kondisi jika user data belum ada setelah loading selesai
        return Scaffold(backgroundColor: Colors.blue[50], body: const Center(child: Text("Data pengguna tidak ditemukan.")));
    }


    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Untuk DashedCircularProgressBar jika digunakan
    // if (uiTargetMl > 0) {
    //   _valueNotifier.value = min(100, (currentIntake / uiTargetMl) * 100);
    // } else {
    //   _valueNotifier.value = 0;
    // }

    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02), // Padding bawah untuk konten scrollable potensial
          child: Stack(
            children: [
              // Konten Header
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HYDRATE",
                      style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue,
                          fontFamily: "Gluten"), // Pastikan font Gluten ada di pubspec.yaml
                    ),
                    Transform.translate(
                      offset: Offset(0, screenHeight * -0.007),
                      child: Text(
                        "Hai, ${truncateName(namaPengguna!, 20)}",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
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
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        color: currentIntake >= uiTargetMl && uiTargetMl > 0
                            ? const Color(0xFF07BAE4)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Konten Utama (Lingkaran Progres, tombol, dll.)
              Column(
                mainAxisAlignment: MainAxisAlignment.start, // This allows content to start from top
                children: [
                  SizedBox(height: screenHeight * 0.20), // Spasi untuk header
                  AnimatedWaterProgressCircle(
                    currentIntake: currentIntake,
                    target: uiTargetMl,
                    screenWidth: screenWidth,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Transform.translate(
                    offset: Offset(0, screenHeight * -0.03),
                    child: Container(
                      width: screenWidth * 0.75,
                      height: screenHeight * 0.055,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_isCountdownActive && _remainingTime.inSeconds > 0)
                              ? [const Color(0xFF2AD1D1), const Color(0xFF2AD1D1)] // Warna saat countdown aktif
                              : [const Color(0xFF4EE9BD), const Color(0xFF07BAE4)], // Warna default atau saat "SAATNYA MINUM"
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (_isCountdownActive && _remainingTime.inSeconds > 0)
                            ? "Hidrasi selanjutnya ${_formatTime(_remainingTime)}"
                             : ((_isCountdownActive && currentIntake > 0) || (_isCountdownActive && _remainingTime.inSeconds <=0)) 
                                ? "Tekan gelas untuk minum!" // "SAATNYA MINUM" jika sudah pernah minum & timer habis
                                : "Tekan gelas untuk minum!", // Default jika belum pernah minum sama sekali
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.038, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.010),
                  Container(
                    width: screenWidth * 0.85,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015, horizontal: screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.03)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2F2E41).withOpacity(0.1),
                          blurRadius: screenWidth * 0.03,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDrinkOption('assets/images/glass/100ml_glass.svg', 100, screenWidth, screenHeight),
                        _buildDrinkOption('assets/images/glass/150ml_glass.svg', 150, screenWidth, screenHeight),
                        _buildDrinkOption('assets/images/glass/200ml_glass.svg', 200, screenWidth, screenHeight),
                        GestureDetector( // Wrap FAB with GestureDetector for consistent tap area if needed
                          onTap: () => _showAddWaterModal(context),
                          child: Container( // Container for consistent padding/sizing if FAB size is constrained
                            padding: EdgeInsets.all(screenWidth * 0.01), 
                            child: SizedBox( 
                              width: screenWidth * 0.11,
                              height: screenWidth * 0.11,
                              child: FloatingActionButton(
                                heroTag: "addWaterHome", 
                                backgroundColor: Colors.blue,
                                elevation: 2.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.075), 
                                ),
                                onPressed: () => _showAddWaterModal(context),
                                child: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.065),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // Margin bawah agar tidak terpotong jika ada elemen lain
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkOption(String gambar, double amount, double screenWidth, double screenHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _startDrinkingWithCooldown(amount),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(0, _glassOffsets[amount] ?? 0.0, 0), // Default ke 0.0 jika null
            child: Opacity(
              opacity: _isButtonCooldown ? 0.5 : 1.0,
              child: SvgPicture.asset(
                gambar, // Pastikan path asset benar
                fit: BoxFit.contain,
                height: screenHeight * 0.055,
                width: screenWidth * 0.1, // Width can be set for aspect ratio if needed
              ),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Text(
          '${amount.toInt()} mL',
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: _isButtonCooldown ? Colors.grey : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showWarningPopup(BuildContext context, String message) {
    if (!mounted) return;
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);
    // Buat AnimationController baru setiap kali popup ditampilkan
    final animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: screenHeight * 0.06, left: screenWidth * 0.05, right: screenWidth * 0.05,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut)),
          child: AnimatedOpacity(
            opacity: 1.0, duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: screenWidth * 0.9,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015, horizontal: screenWidth * 0.035),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]!.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: screenWidth * 0.01, offset: Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.black87, size: screenWidth * 0.06),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(child: Text(message, style: TextStyle(color: Colors.black87, fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600), textAlign: TextAlign.left)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && animationController.status != AnimationStatus.dismissed) {
        animationController.reverse().whenComplete(() {
          if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
          animationController.dispose(); // Dispose setelah selesai
        });
      } else if(!mounted || (overlayEntry?.mounted ?? false && animationController.status == AnimationStatus.dismissed)) {
        if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
        animationController.dispose();
      }
    });
  }

  void _showAddWaterModal(BuildContext context) {
    // int selectedWater = 250; // Bisa dijadikan state jika ingin nilainya diingat antar modal
    double screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent, 
      shape: RoundedRectangleBorder( 
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom),
        child: AddWaterModalContent( // Make sure this widget exists and is imported
          selectedWater: 250, // Nilai default atau dari state
          idPengguna: idPengguna,
          onWaterAdded: (newSelectedWater) {
            _startDrinkingWithCooldown(newSelectedWater.toDouble());
            Navigator.pop(bottomSheetContext); // Tutup modal setelah air ditambahkan
          },
        ),
      ),
    );
  }

  // Overlay generik (jika masih dibutuhkan)
  void _showOverlay(BuildContext context, String message, Color color, {bool isError = false}) {
    if (!mounted) return;
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    overlayEntry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(top: screenHeight * 0.06, left: screenWidth * 0.05, right: screenWidth * 0.05),
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: screenWidth * 0.015, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if(isError) Icon(Icons.error_outline, color: Colors.white, size: screenWidth * 0.05),
                if(isError) SizedBox(width: screenWidth * 0.02),
                Expanded(child: Text(message, style: TextStyle(color: isError ? Colors.white : Color(0xFF2F2E41), fontSize: screenWidth * 0.038, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ]),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) { 
        if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
        animationController.dispose();
        return;
      }
      if (overlayEntry != null) { 
        if (animationController.status != AnimationStatus.dismissed) {
          animationController.reverse().whenComplete(() { 
            if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
            overlayEntry = null; 
            animationController.dispose();
          });
        } else { 
          if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
          overlayEntry = null;
          animationController.dispose();
        }
      } else { 
        animationController.dispose(); 
      }
    });
  }

  void _showOverlayError(String message) {
    _showOverlay(context, message, Colors.redAccent, isError: true);
  }

  void _showOverlaySuccess(String message) {
    // Biasanya sudah ditangani oleh _showAddedWaterPopup
    // Jika perlu, bisa panggil _showOverlay di sini dengan warna sukses
    // _showOverlay(context, message, Colors.green.withOpacity(0.9));
  }
}