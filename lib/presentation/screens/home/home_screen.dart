import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart';
import 'package:hydrate/presentation/widgets/Main/alert_drinkByPercentace_widget.dart'
    show DrinkPercentageAlerts;
import 'package:hydrate/presentation/widgets/Main/animated_progress_circle.dart';
import 'package:hydrate/presentation/widgets/Main/drink_status_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/home_controller.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/services/notification_settings_service.dart';
import 'package:hydrate/presentation/widgets/Main/custom_input_water_widget.dart';

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
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(
      0); // Untuk DashedCircularProgressBar jika digunakan
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
  final Map<double, double> _glassOffsets = {};

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
    _uiController
        .initAnimation(this); // Untuk animasi jika ada di HomeController
    _pageController.addListener(() => setState(() {}));
    _audioPlayer = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDataAndUpdateScreen(forceTargetRecalculation: false);
        _scheduleWakeUpNotification();
      }
    });

    _eventSubscription = _eventBus.stream.listen((AppEvent event) {
      if (event.type == 'refresh_all' || event.type == 'refresh_home_page') {
        _fetchDataAndUpdateScreen(forceTargetRecalculation: true);
        _scheduleWakeUpNotification();
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

  Future<void> _scheduleWakeUpNotification() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    bool areNotificationsGloballyEnabled =
        prefs.getBool('notifications_enabled') ?? false;

    if (!areNotificationsGloballyEnabled) {
      return;
    }

    if (idPengguna == null) {
      final session = SessionManager();
      idPengguna = await session.getUserId();
      if (idPengguna == null) {
        return;
      }
    }

    final TimeOfDay wakeUp = await _notificationSettingsService.getWakeUpTime();
    DateTime now = DateTime.now();
    DateTime todayWakeUp =
        DateTime(now.year, now.month, now.day, wakeUp.hour, wakeUp.minute);
    DateTime nextWakeUpNotificationTime;

    if (now.isBefore(todayWakeUp)) {
      nextWakeUpNotificationTime = todayWakeUp;
    } else {
      nextWakeUpNotificationTime = todayWakeUp.add(const Duration(days: 1));
    }

    nextWakeUpNotificationTime =
        nextWakeUpNotificationTime.add(const Duration(seconds: 10));

    const int wakeUpNotificationId = 200;

    await AwesomeNotifications().cancel(wakeUpNotificationId);

    await NotificationController.scheduleNextHydrationNotification(
        exactNotificationTime: nextWakeUpNotificationTime,
        title: 'Bangun Tidur! Waktunya Minum Air 💧',
        body: 'Awali harimu dengan hidrasi yang cukup!',
        notificationId: wakeUpNotificationId,
        payload: {'type': 'wake_up_reminder'});
  }

  Future<void> _fetchDataAndUpdateScreen(
      {bool forceTargetRecalculation = false}) async {
    if (!mounted) return;

    setState(() {
      _isHomeScreenLoading = true;
    });

    setState(() => _isHomeScreenLoading = true);

    final session = SessionManager();
    final localUserId = await session.getUserId();

    if (localUserId != null) {
      if (mounted) {
        if (idPengguna != localUserId) {
          setState(() => idPengguna = localUserId);
        }
        await _loadUserDisplayData(localUserId);

        final targetController =
            Provider.of<TargetHidrasiController>(context, listen: false);
        if (forceTargetRecalculation) {
          await targetController
              .forceRecalculateAndUpdateTargetAfterProfileChange(localUserId);
        } else {
          await targetController.initializeOrRefreshDailyTarget(localUserId);
        }

        await _loadTodayIntake(
            localUserId); // Muat intake setelah target mungkin diperbarui
        await _loadCountdownState();

        _eventBus.fire('home_target_processing_complete');
        // ---------------------------------------------------------------------------------
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
        setState(() {
          namaPengguna = pengguna.nama;
        });
      } else if (pengguna == null) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          namaPengguna = null;
        });
      }
    }
  }

  Future<void> _loadTodayIntake(int currentUserId) async {
    if (!mounted) return;

    final targetController =
        Provider.of<TargetHidrasiController>(context, listen: false);
    double actualTargetForCalculation = targetController.currentDailyTargetMl;

    // Fallback jika target dari controller masih 0 (misal, baru login & kalkulasi belum selesai sempurna)
    if (actualTargetForCalculation <= 0) {
      // Jika controller belum punya target valid, coba ambil dari repo sebagai fallback sementara
      // Namun, idealnya controller sudah diinisialisasi dengan benar oleh _fetchDataAndUpdateScreen
      final targetDataMap = await _targetHidrasiRepository
          .getTargetHidrasiHarian(currentUserId, todayDate);
      actualTargetForCalculation =
          (targetDataMap?['target_hidrasi'] as num?)?.toDouble() ?? 2500.0;
    }
    // Ultimate fallback jika semua gagal
    if (actualTargetForCalculation <= 0) actualTargetForCalculation = 2500.0;

    try {
      final targetHarianData = await _targetHidrasiRepository
          .getTargetHidrasiHarian(currentUserId, todayDate);
      double totalHidrasi =
          (targetHarianData?['total_hidrasi_harian'] as num?)?.toDouble() ??
              0.0;

      double persentaseHidrasi = (actualTargetForCalculation > 0)
          ? (totalHidrasi / actualTargetForCalculation) * 100
          : 0.0;

      if (mounted) {
        setState(() {
          currentIntake = totalHidrasi;
          _valueNotifier.value = persentaseHidrasi.clamp(
              0.0, 100.0); // Untuk DashedCircularProgressBar
        });
      }
    } catch (e) {
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
      await _audioPlayer.stop();

      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioPlayer.dispose();
        });
      }
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
          if (mounted) {
            // Pastikan widget masih mounted
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
    final hasStartedTimerPreviously =
        prefs.getBool('timer_has_started') ?? false;

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
  final prefs = await SharedPreferences.getInstance();
  // Hanya simpan jika timer sedang berjalan aktif dengan sisa waktu DAN _endTime valid
  if (_isCountdownActive && _remainingTime.inSeconds > 0 && _endTime != null) {
    final endTimeMillis = _endTime!.millisecondsSinceEpoch;
    await prefs.setInt(_endTimeKey, endTimeMillis);
    // 'timer_has_started' sudah di-set oleh _startCountdown
  }
  // Jika "SAATNYA MINUM" (_remainingTime <= 0), tidak perlu menyimpan _endTimeKey di sini,
  // karena _loadCountdownState akan menanganinya dengan benar berdasarkan 'timer_has_started'.
}

  void _animateGlass(double amount) async {
    if (idPengguna == null) {
      if (mounted) _showOverlayError("User tidak teridentifikasi!");
      return;
    }

    _playDrinkingSound();
    previousIntake = currentIntake; // Simpan intake sebelum update

    try {
      final targetControllerProvider =
          Provider.of<TargetHidrasiController>(context, listen: false);
      await _riwayatHidrasiController.tambahRiwayatHidrasi(
        fkIdPengguna: idPengguna!,
        jumlahHidrasi: amount,
        targetController:
            targetControllerProvider, // Untuk update target jika perlu
      );

      // Setelah berhasil simpan, update UI dari data terbaru
      await _loadTodayIntake(
          idPengguna!); // Ini akan mengupdate currentIntake dan _valueNotifier
      _eventBus.fire('refresh_statistics');
    } catch (e) {
      if (mounted) {
        // Kembalikan nilai intake jika gagal, lalu refresh dari DB
        currentIntake = previousIntake;
        await _loadTodayIntake(
            idPengguna!); // Refresh untuk memastikan UI konsisten
        _showOverlayError(
            "Gagal menyimpan data: ${e.toString().substring(0, min(50, e.toString().length))}...");
      }
    }

    _animateGlassMovement(amount); // Animasi visual gelas
    _startCountdown(); // Mulai atau restart countdown untuk pengingat berikutnya

    if (mounted) {
      final targetController = context.read<TargetHidrasiController>();

      // Alert berdasarkan persentase
      DrinkPercentageAlerts.checkAndShowPercentageAlert(
          context, currentIntake, targetController.currentDailyTargetMl);
    }
  }

  void _animateGlassMovement(double amount) {
    if (!mounted) return;
    // Untuk animasi visual gelas (jika ada)
    setState(() => _glassOffsets[amount] = -10.0); // Contoh offset
    Future.delayed(const Duration(milliseconds: 300), () {
      // Durasi animasi
      if (mounted) setState(() => _glassOffsets[amount] = 0.0);
    });
  }

  Future<void> _startCountdown() async {
  final prefs = await SharedPreferences.getInstance();
  bool areNotificationsGloballyEnabled =
      prefs.getBool('notifications_enabled') ?? false;

  if (!areNotificationsGloballyEnabled) {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isCountdownActive = false;
        _remainingTime = Duration.zero;
        _endTime = null;
      });
      // Consider clearing _endTimeKey and setting timer_has_started to false if appropriate
      // await prefs.remove(_endTimeKey);
      // await prefs.setBool('timer_has_started', false); // Atau biarkan true jika sudah pernah minum
    }
    return;
  }

  await NotificationController.cancelScheduledNotifications();

  final TimeOfDay wakeUp = await _notificationSettingsService.getWakeUpTime();
  final TimeOfDay sleep = await _notificationSettingsService.getSleepTime();

  const Duration reminderInterval = Duration(hours: 1);
  DateTime now = DateTime.now();
  // Initialize with a default value in the future to avoid null errors
  DateTime scheduledNotificationTime = now.add(reminderInterval);

  // TODO: Replace this with your actual logic to calculate scheduledNotificationTime
  // Example fallback logic:
  // scheduledNotificationTime = ... (your calculation here)
  // Make sure to always assign a value to scheduledNotificationTime

  // --- BLOK PERUBAHAN UTAMA ---
  if (mounted) {
    DateTime newEndTime = scheduledNotificationTime;
    Duration newRemainingTime = newEndTime.isAfter(now)
        ? newEndTime.difference(now)
        : Duration.zero;

    // Jika kalkulasi menghasilkan waktu yang sudah lewat (seharusnya tidak terjadi jika fallback kuat),
    // setidaknya buat dia "SAATNYA MINUM" untuk siklus ini daripada menghilangkan timer.
    // Namun, idealnya newRemainingTime.inSeconds > 0 selalu tercapai.
    if (newRemainingTime.inSeconds <= 0 && areNotificationsGloballyEnabled) {
      // Fallback jika scheduledNotificationTime ternyata tidak di masa depan
      // Ini seharusnya jarang terjadi jika logika kalkulasi di atas sudah benar
      newEndTime = now.add(const Duration(minutes: 1)); // default kecil, atau reminderInterval
      newRemainingTime = newEndTime.difference(now);
    }


    setState(() {
      _endTime = newEndTime;
      _remainingTime = newRemainingTime;
      // _isCountdownActive akan true jika newRemainingTime > 0, atau jika kita ingin "SAATNYA MINUM"
      _isCountdownActive = true; // Setelah minum, countdown/pengingat selalu aktif
    });

    if (_remainingTime.inSeconds > 0) {
      // Simpan state BARU ke SharedPreferences
      await prefs.setInt(_endTimeKey, _endTime!.millisecondsSinceEpoch);
      await prefs.setBool('timer_has_started', true); // Tandai bahwa timer telah berhasil dimulai
      _startTimer(); // Mulai timer visual
    } else {
      // Kasus ini berarti "SAATNYA MINUM" langsung (jika newRemainingTime nol setelah fallback)
      // atau jika notifikasi dimatikan dan kita ingin menonaktifkan timer.
      // _isCountdownActive sudah true, _remainingTime sudah nol.
      await prefs.remove(_endTimeKey); // Tidak ada endTime spesifik di masa depan jika langsung "SAATNYA MINUM"
      await prefs.setBool('timer_has_started', true); // Siklus tetap dianggap dimulai
      // Tidak perlu _startTimer() karena sudah waktunya
    }

    // Jadwalkan notifikasi sistem (jika _remainingTime > 0)
    if (_isCountdownActive && _remainingTime.inSeconds > 0) {
       await NotificationController.scheduleNextHydrationNotification(
         exactNotificationTime: _endTime!, // Gunakan _endTime yang sudah pasti
       );
    } else if (_isCountdownActive && _remainingTime.inSeconds <= 0) {
      // Jika langsung "SAATNYA MINUM", mungkin tidak perlu notifikasi segera,
      // atau jadwalkan notifikasi "SAATNYA MINUM" jika diinginkan.
      // Biasanya ini ditangani oleh UI saja.
    }
  }
  // --- AKHIR BLOK PERUBAHAN UTAMA ---
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
          position:
              Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: animationController, curve: Curves.easeOut)),
          child: AnimatedOpacity(
            opacity:
                1.0, // Starts visible, fade out can be handled by reverse animation if needed
            duration: const Duration(
                milliseconds: 300), // Duration for opacity if animated
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
      } else if (!mounted || (overlayEntry?.mounted ?? false)) {
        if (overlayEntry?.mounted ?? false) overlayEntry?.remove();
        animationController.dispose();
      }
    });
  }

  bool hasShownCongrats = false;

  String truncateName(String name, int maxLength) {
    if (name.length <= maxLength) return name;
    int lastSpace = name.substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace == -1 || lastSpace < maxLength - (maxLength > 5 ? 5 : 0)) {
      // Cegah error jika maxLength kecil
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

    Timer(const Duration(seconds: 3), () {
      // Durasi cooldown
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
      return Scaffold(
          backgroundColor: Colors.blue[50],
          body: const Center(child: CircularProgressIndicator()));
    }
    if (idPengguna == null || namaPengguna == null) {
      // Kondisi jika user data belum ada setelah loading selesai
      return Scaffold(
          backgroundColor: Colors.blue[50],
          body: const Center(child: Text("Data pengguna tidak ditemukan.")));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        body: SingleChildScrollView(
          child: Container(
            // width: double.infinity,
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.08,
                    top: screenHeight * 0.07,
                    bottom: screenHeight * 0.025,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HYDRATE",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue,
                          fontFamily: "Gluten",
                        ),
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

                // Status Widget Section - Pisahkan dari main content
                Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 0),
                        child: DrinkStatusWidget(
                          isCountdownActive: _isCountdownActive,
                          remainingTime: _remainingTime,
                          currentIntake: currentIntake.toInt(),
                          screenHeight: screenHeight,
                          formatTime: _formatTime,
                          onStatusChange: () {
                            // print("Status widget changed");
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Water Progress Circle Section
                Container(
                  width: double.infinity,
                  child: Center(
                    child: AnimatedWaterProgressCircle(
                      currentIntake: currentIntake,
                      target: uiTargetMl,
                      screenWidth: screenWidth,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.021),

                // Drink Options Section
                Container(
                  width: screenWidth * 0.84,
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
                        'assets/images/glass/100ml_glass.svg',
                        100,
                        screenWidth,
                        screenHeight,
                      ),
                      _buildDrinkOption(
                        'assets/images/glass/150ml_glass.svg',
                        150,
                        screenWidth,
                        screenHeight,
                      ),
                      _buildDrinkOption(
                        'assets/images/glass/200ml_glass.svg',
                        200,
                        screenWidth,
                        screenHeight,
                      ),
                      GestureDetector(
                        onTap: () => _showAddWaterModal(context),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: FloatingActionButton(
                            heroTag: "addWaterHome",
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
                    ],
                  ),
                ),

                // Bottom spacing
                // SizedBox(height: 40),
              ],
            ),
          ),
        ));
  }

  Widget _buildDrinkOption(
      String gambar, double amount, double screenWidth, double screenHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _startDrinkingWithCooldown(amount),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(
                0, _glassOffsets[amount] ?? 0.0, 0), // Default ke 0.0 jika null
            child: Opacity(
              opacity: _isButtonCooldown ? 0.5 : 1.0,
              child: SvgPicture.asset(
                gambar, // Pastikan path asset benar
                fit: BoxFit.contain,
                height: screenHeight * 0.055,
                width: screenWidth *
                    0.1, // Width can be set for aspect ratio if needed
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
    final animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: screenHeight * 0.06,
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animationController, curve: Curves.easeOut)),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: screenWidth * 0.9,
                  padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.015,
                      horizontal: screenWidth * 0.035),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]!.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: screenWidth * 0.01,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.black87, size: screenWidth * 0.06),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                        child: Text(message,
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.left)),
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
      } else if (!mounted || (overlayEntry?.mounted ?? false)) {
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom),
        child: AddWaterModalContent(
          // Make sure this widget exists and is imported
          selectedWater: 250, // Nilai default atau dari state
          idPengguna: idPengguna,
          onWaterAdded: (newSelectedWater) {
            _startDrinkingWithCooldown(newSelectedWater.toDouble());
            Navigator.pop(
                bottomSheetContext); // Tutup modal setelah air ditambahkan
          },
        ),
      ),
    );
  }

  // Overlay generik (jika masih dibutuhkan)
  void _showOverlay(BuildContext context, String message, Color color,
      {bool isError = false}) {
    if (!mounted) return;
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    overlayEntry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animationController, curve: Curves.easeOut)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(
                  top: screenHeight * 0.06,
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05),
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: screenWidth * 0.015,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isError)
                  Icon(Icons.error_outline,
                      color: Colors.white, size: screenWidth * 0.05),
                if (isError) SizedBox(width: screenWidth * 0.02),
                Expanded(
                    child: Text(message,
                        style: TextStyle(
                            color: isError ? Colors.white : Color(0xFF2F2E41),
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
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
}
