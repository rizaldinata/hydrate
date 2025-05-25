import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

import 'package:hydrate/presentation/controllers/home_screen_controller.dart';
import 'package:hydrate/presentation/widgets/Main/add_water_modal_content_widget.dart'; 
import 'package:hydrate/core/utils/app_event_bus.dart';

class HomeScreenProvider extends StatelessWidget {
  const HomeScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
       create: (context) => HomeScreenController()..initialize(),
      child: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreensState();
}

class HomeScreensState extends State<HomeScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Animation controller untuk UI (jika ada, seperti _controller lama Anda)
  // HomeController (Animation)
  late AnimationController _uiAnimationController; // Contoh jika ada controller animasi UI
  
  late AudioPlayer _audioPlayer;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();
  final Map<double, double> _glassOffsets = {}; // Untuk animasi gelas

  void refresh() {
    if (mounted) { 
      context.read<HomeScreenController>().refreshData();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();

    // Inisialisasi animation controller jika Anda punya (seperti _controller lama)
    _uiAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));


    _eventSubscription = _eventBus.stream.listen((event) {
      if (event == 'refresh_home' || event == 'refresh_all') {
        refresh();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final controller = context.read<HomeScreenController>();
    if (state == AppLifecycleState.paused) {
      controller.onAppPause();
    } else if (state == AppLifecycleState.resumed) {
      controller.initialize(); // Re-initialize atau load timer state
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _uiAnimationController.dispose();
    _eventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _playDrinkingSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  void _handleWaterAdded(double amount) {
    _playDrinkingSound();
    context.read<HomeScreenController>().addWater(amount);
    _animateGlassMovement(amount); // Animasi lokal UI
    _showAddedWaterPopup(context, amount); // Feedback UI
  }
  
  void _animateGlassMovement(double amount) {
    setState(() => _glassOffsets[amount] = -10); // Efek gelas naik sedikit
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _glassOffsets[amount] = 0);
      }
    });
  }

  void _checkTargetAndShowConfetti(HomeScreenController controller) {
    if (controller.hasReachedTargetToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
            _confettiController.play();
            // Tampilkan dialog selamat Anda di sini
             _showCongratsDialog();
         }
      });
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // UI Widgets (seperti _buildDrinkOption, dialogs, dll. tetap di sini karena bersifat View)
  Widget _buildDrinkOption(double amount) {
    String imagePath;
    if (amount == 100) imagePath = 'assets/images/glass/100ml_glass.svg';
    else if (amount == 150) imagePath = 'assets/images/glass/150ml_glass.svg';
    else if (amount == 200) imagePath = 'assets/images/glass/200ml_glass.svg';
    else imagePath = 'assets/images/glass/default_glass.svg'; // Fallback

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _handleWaterAdded(amount),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), // Durasi animasi naik-turun
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(0, _glassOffsets[amount] ?? 0, 0),
            child: SvgPicture.asset(imagePath, height: 50),
          ),
        ),
        const SizedBox(height: 5),
        Text('${amount.toInt()} mL', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // Di dalam class HomeScreensState di file lib/presentation/screens/home_screen.dart

  // Di home_screen.dart, jika AddWaterModalContent sudah di-refactor
  void _showAddWaterModal(BuildContext context) {
    final homeController = context.read<HomeScreenController>();
    final currentUserId = homeController.userId;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data pengguna belum siap. Silakan coba lagi sesaat.")),
      );
      return;
    }

    int initialSelectedWater = 250; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddWaterModalContent(
        selectedWater: initialSelectedWater, 
        idPengguna: currentUserId,
        onWaterAdded: (double amount) {
          _handleWaterAdded(amount);
          Navigator.pop(context); 
        },
      ),
    );
  }
  
  // Pindahkan _showAddedWaterPopup dan _showCongratsDialog ke sini
   void _showAddedWaterPopup(BuildContext context, double amount) {
    OverlayEntry overlayEntry;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: Navigator.of(context), // Pastikan ada TickerProvider
      duration: const Duration(milliseconds: 500),
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 50, left: 20, right: 20,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
                .animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut)),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/images/berhasil.svg', colorFilter: const ColorFilter.mode(Color(0xFF3EDAC0), BlendMode.srcIn), width: 24, height: 24),
                    const SizedBox(width: 16),
                    Text("Berhasil menambahkan ${amount.toInt()} ml !", style: const TextStyle(color: Color(0xFF2F2E41), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
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
      animationController.reverse().then((value) {
        overlayEntry.remove();
        animationController.dispose(); // Penting untuk di-dispose
      });
    });
  }

  void _showCongratsDialog() {
     showGeneralDialog(
       context: context,
       barrierDismissible: true,
       barrierLabel: "Congrats",
       transitionDuration: const Duration(milliseconds: 500),
       pageBuilder: (context, anim1, anim2) { // anim1 untuk dialog, anim2 untuk background
         return Center(
           child: Stack(
             alignment: Alignment.center,
             children: [
               ConfettiWidget(
                 confettiController: _confettiController,
                 blastDirectionality: BlastDirectionality.explosive,
                 shouldLoop: false, emissionFrequency: 0.05,
                 numberOfParticles: 25,
                 colors: const [Colors.blue, Colors.pink, Colors.orange, Colors.green],
               ),
               ScaleTransition(
                 scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
                 child: AlertDialog(
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   backgroundColor: Colors.white,
                   title: const Column(
                     children: [
                       Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                       SizedBox(height: 10),
                       Text('Selamat! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                     ],
                   ),
                   content: const Text('Kamu sudah mencapai target harianmu!', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
                   actionsAlignment: MainAxisAlignment.center,
                   actions: [
                     SizedBox(
                       width: double.infinity, // Membuat tombol memenuhi lebar dialog
                       child: ElevatedButton(
                         onPressed: () => Navigator.pop(context),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                         child: const Text('Mantap!', style: TextStyle(color: Colors.white)),
                       ),
                     ),
                   ],
                 ),
               ),
             ],
           ),
         );
       },
     );
   }


  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendengarkan perubahan dari HomeScreenController
    return Consumer<HomeScreenController>(
      builder: (context, controller, child) {
        // Cek apakah target tercapai untuk memutar confetti
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.hasReachedTargetToday && mounted) {
            _checkTargetAndShowConfetti(controller);
          }
        });

        if (controller.isLoading && controller.userName == null) { // Hanya tampilkan full loading jika data user belum ada
          return Scaffold(
            backgroundColor: const Color(0xFFE8F7FF),
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
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
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.07),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (Logo, Nama, Pesan)
                      const Text("HYDRATE", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.blue, fontFamily: "Gluten")),
                      Transform.translate(
                        offset: Offset(0, screenHeight * -0.008),
                        child: Text("Hai, ${controller.userName ?? 'Pengguna'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      Text(
                        controller.currentIntake >= controller.targetIntake && controller.targetIntake > 0
                            ? "Pencapaianmu hari ini telah selesai."
                            : "Ayo selesaikan pencapaianmu hari ini!",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: controller.currentIntake >= controller.targetIntake && controller.targetIntake > 0 ? Color(0xFF07BAE4) : Colors.black54),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.22), // Disesuaikan agar pas
                      // Progress Bar
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.08), // Sedikit lebih kecil
                        child: DashedCircularProgressBar.aspectRatio(
                          aspectRatio: 1,
                          valueNotifier: ValueNotifier<double>(controller.progressPercentage), // Gunakan dari controller
                          progress: controller.progressPercentage,
                          startAngle: 230, sweepAngle: 260,
                          foregroundColor: const Color(0xFF00A6FB), backgroundColor: const Color(0xFFA1E3F9),
                          foregroundStrokeWidth: 15, backgroundStrokeWidth: 15,
                          animation: true,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${controller.progressPercentage.ceil()}%', style: const TextStyle(color: Color(0xFF2F2E41), fontWeight: FontWeight.w300, fontSize: 40)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${controller.currentIntake.toInt()} mL', style: TextStyle(color: controller.currentIntake >= controller.targetIntake && controller.targetIntake > 0 ? Colors.blue : Colors.red, fontWeight: FontWeight.w600, fontSize: 16)),
                                    Text(' / ${controller.targetIntake.toInt()} mL', style: const TextStyle(color: Color(0xFF2F2E41), fontWeight: FontWeight.w500, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Indikator Timer
                      Transform.translate(
                        offset: Offset(0, screenHeight * -0.04), // Disesuaikan
                        child: Container(
                          width: screenWidth * 0.70, // Sedikit lebih kecil
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: (controller.isCountdownActive && controller.remainingTime.inSeconds > 0)
                                  ? [const Color(0xFF2AD1D1), const Color(0xFF2AD1D1)]
                                  : [const Color(0xFF4EE9BD), const Color(0xFF07BAE4)],
                              begin: Alignment.centerLeft, end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (controller.isCountdownActive && controller.remainingTime.inSeconds > 0)
                                ? "Hidrasi selanjutnya ${_formatTime(controller.remainingTime)}"
                                : (controller.isCountdownActive || controller.currentIntake > 0)
                                    ? "SAATNYA MINUM!"
                                    : "SAATNYA MINUM!", // Default jika belum minum
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      // Opsi Minum
                      Container(
                        width: screenWidth * 0.85, // Sedikit lebih kecil
                        margin: EdgeInsets.only(top: screenHeight * 0.01), // Disesuaikan
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          boxShadow: [BoxShadow(color: const Color(0xFF2F2E41).withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(1, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDrinkOption(100),
                            _buildDrinkOption(150),
                            _buildDrinkOption(200),
                            GestureDetector(
                              onTap: () => _showAddWaterModal(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                child: const Icon(Icons.add, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                       SizedBox(height: screenHeight * 0.05), // Spacer tambahan di bawah
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}