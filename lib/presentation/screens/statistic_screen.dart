import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
// Import event bus
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({Key? key}) : super(key: key);

  @override
  StatisticScreenState createState() => StatisticScreenState();
}

class StatisticScreenState extends State<StatisticScreen> {
  // Refined Color Palette based on 0xFF00A6FB
  final Color _primaryColor = const Color(0xFF00A6FB); // Vibrant Blue
  final Color _accentColor = const Color(0xFF38BDF8); // Light Blue
  final Color _backgroundColor = const Color(0xFFE8F7FF); // Very Light Blue
  final Color _textPrimaryColor = const Color(0xFF0F172A); // Deep Slate
  final Color _textSecondaryColor = const Color(0xFF475569); // Slate Gray
  final Color _surfaceColor = Colors.white;

  List<RiwayatHidrasi> waterHistory = [];
  DateTime selectedDate = DateTime.now();
  final RiwayatHidrasiController _controller = RiwayatHidrasiController();
  bool isLoading = true;
  int? userId;
  String? errorMessage;

  // Stream subscription untuk event bus
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();

  @override
  void initState() {
    super.initState();
    // Set status bar color to match app theme
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: _primaryColor,
    //   statusBarIconBrightness: Brightness.light,
    // ));
    _initData();

    // Subscribe ke event bus untuk refresh data
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_statistics' || event.type == 'refresh_all') {
        refresh();
      }
    });
  }

  // Metode publik untuk memaksa refresh data
  void refresh() {
    print("Refreshing Statistics data...");
    if (selectedDate.isAtSameMomentAs(DateTime.now())) {
      _initData();
    } else {
      setState(() {
        selectedDate = DateTime.now();
      });
      _initData();
    }
  }

  Future<void> _initData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      userId = await SessionManager().getUserId();
      if (userId != null) {
        await _loadRiwayatHidrasi();
      } else {
        setState(() {
          errorMessage = "Pengguna tidak teridentifikasi";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Gagal memuat data: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRiwayatHidrasi() async {
    if (userId == null) return;

    try {
      List<RiwayatHidrasi> history =
          await _controller.getRiwayatHidrasiByTanggal(userId!, selectedDate);
      setState(() {
        waterHistory = history;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Kesalahan saat memuat riwayat: $e";
      });
    }
  }

  void _changeDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      errorMessage = null;
    });
    _loadRiwayatHidrasi();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              secondary: _accentColor,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      _changeDate(picked);
    }
  }

  // Detailed Date Navigation Widget
  Widget _buildDateNavigation() {
    final bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String dateTitle =
        isToday ? "Hari Ini" : DateFormat('dd MMMM yyyy').format(selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day Button
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: _primaryColor,
              size: 32,
            ),
            onPressed: () {
              _changeDate(selectedDate.subtract(const Duration(days: 1)));
            },
          ),

          // Date Display with Gesture
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              dateTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Next Day Button
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isToday ? Colors.grey.shade400 : _primaryColor,
              size: 32,
            ),
            onPressed: isToday
                ? null
                : () {
                    _changeDate(selectedDate.add(const Duration(days: 1)));
                  },
          ),
        ],
      ),
    );
  }

  // Sophisticated Empty State
  Widget _buildEmptyState() {
    final bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.1),
                  _primaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset('assets/loading.json', width: 200, height: 200),
          ),
          const SizedBox(height: 24),
          Text(
            isToday ? "Ayo Minum Air!" : "Tidak Ada Riwayat",
            style: TextStyle(
              fontSize: 20,
              color: _textPrimaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isToday
                ? "Yuk catat konsumsi air mineralmu hari ini"
                : "Tidak ada data hidrasi untuk tanggal ini",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondaryColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

// Enhanced Water Intake Item with Attractive Dismissible UI// Responsive dismissible water intake item
Widget _buildWaterIntakeItem(RiwayatHidrasi item) {
  final String time = item.waktuHidrasi ?? "00:00";
  final double screenWidth = MediaQuery.of(context).size.width;
  final bool isSmallScreen = screenWidth < 360;
  
  return Dismissible(
    key: Key(item.id.toString()),
    background: Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, // 4% of screen width
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.shade200,
            Colors.red.shade800,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: screenWidth * 0.06), // 6% of screen width
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Hapus",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: isSmallScreen ? 22 : 26,
          ),
        ],
      ),
    ),
    direction: DismissDirection.endToStart,
    confirmDismiss: (direction) async {
      return await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, anim1, anim2) {
          final double dialogWidth = screenWidth * 0.85;
          final double maxDialogWidth = 450;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, // 5% of screen width
              vertical: 24,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text("Konfirmasi Hapus"),
              ],
            ),
            content: Container(
              constraints: BoxConstraints(
                maxWidth: min(dialogWidth, maxDialogWidth),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Anda yakin ingin menghapus catatan hidrasi ${item.jumlahHidrasi.toInt()} mL ini?",
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: _textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tindakan ini tidak dapat dibatalkan.",
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: _textSecondaryColor),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actionsPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, // 4% of screen width
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: _textSecondaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05, // 5% of screen width
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  "BATAL", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05, // 5% of screen width
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  "HAPUS", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ],
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
              child: child,
            ),
          );
        },
      );
    },
    onDismissed: (direction) {
      // Remove item from UI only
      setState(() {
        waterHistory.remove(item);
      });
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: isSmallScreen ? 16 : 18),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Flexible(
                child: Text(
                  "Catatan hidrasi telah dihapus",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: "BATALKAN",
            textColor: Colors.white,
            onPressed: () {
              // Restore the item to the list
              setState(() {
                waterHistory.add(item);
                // Re-sort the list if needed
                waterHistory.sort((a, b) => 
                  (b.waktuHidrasi ?? "").compareTo(a.waktuHidrasi ?? ""));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Catatan telah dipulihkan"),
                  duration: const Duration(seconds: 1),
                  backgroundColor: _primaryColor,
                  behavior: SnackBarBehavior.floating,
                )
              );
            },
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03, // 3% of screen width
            vertical: 8,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, // 4% of screen width
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _primaryColor.withOpacity(0.1),
          highlightColor: _primaryColor.withOpacity(0.05),
          onTap: () {
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, // 4% of screen width
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/glass.svg',
                    width: isSmallScreen ? 24 : 32,
                    height: isSmallScreen ? 24 : 32,
                    colorFilter: ColorFilter.mode(_primaryColor, BlendMode.srcIn),
                  ),
                ),

                SizedBox(width: screenWidth * 0.03), // 3% of screen width

                // Water Amount with responsive layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${item.jumlahHidrasi.toInt()} mL",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimaryColor,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 8),
                          // Responsive visual indicator
                          LayoutBuilder(builder: (context, constraints) {
                            // Calculate number of dots based on container width
                            final int maxDots = isSmallScreen ? 3 : 5;
                            final int dots = min(
                              (item.jumlahHidrasi / 100).clamp(1, maxDots).toInt(),
                              maxDots
                            );
                            
                            return Row(
                              children: List.generate(
                                dots,
                                (index) => Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  width: isSmallScreen ? 4 : 6,
                                  height: isSmallScreen ? 4 : 6,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      Text(
                        "Konsumsi Air",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: _textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      // Responsive time badge
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: isSmallScreen ? 12 : 14,
                              color: _primaryColor,
                            ),
                            SizedBox(width: isSmallScreen ? 2 : 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                fontWeight: FontWeight.w500,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Hint icon for swipe action
                Icon(
                  Icons.chevron_left,
                  color: _textSecondaryColor.withOpacity(0.5),
                  size: isSmallScreen ? 18 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Riwayat Hidrasi",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Navigation
            _buildDateNavigation(),

            // Error Message (if any)
            if (errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Main Content with Bottom Padding
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    )
                  : waterHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 80), // Large bottom padding
                          itemCount: waterHistory.length,
                          itemBuilder: (context, index) {
                            return _buildWaterIntakeItem(waterHistory[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel(); // Batalkan subscription saat widget dihapus
    super.dispose();
  }
}
