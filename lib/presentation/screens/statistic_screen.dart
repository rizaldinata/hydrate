import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({Key? key}) : super(key: key);

  @override
  _StatisticScreenState createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  // Refined Color Palette based on 0xFF00A6FB
  final Color _primaryColor = const Color(0xFF00A6FB); // Vibrant Blue
  final Color _accentColor = const Color(0xFF38BDF8); // Light Blue
  final Color _backgroundColor = const Color(0xFFF0F9FF); // Very Light Blue
  final Color _textPrimaryColor = const Color(0xFF0F172A); // Deep Slate
  final Color _textSecondaryColor = const Color(0xFF475569); // Slate Gray
  final Color _surfaceColor = Colors.white;

  List<RiwayatHidrasi> waterHistory = [];
  DateTime selectedDate = DateTime.now();
  final RiwayatHidrasiController _controller = RiwayatHidrasiController();
  bool isLoading = true;
  int? userId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Set status bar color to match app theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _primaryColor,
      statusBarIconBrightness: Brightness.light,
    ));
    _initData();
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
      List<RiwayatHidrasi> history = await _controller.getRiwayatHidrasiByTanggal(userId!, selectedDate);
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
    final String dateTitle = isToday ? "Hari Ini" : DateFormat('dd MMMM yyyy').format(selectedDate);

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
            child: Icon(
              Icons.water_drop_outlined,
              size: 80, 
              color: _primaryColor,
            ),
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

  // Enhanced Water Intake Item
  Widget _buildWaterIntakeItem(RiwayatHidrasi item) {
    final String time = item.waktuHidrasi ?? "00:00";
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          onTap: () {
            // Optional: Add interaction or details view
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Animated Glass Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/glass.svg',
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(_primaryColor, BlendMode.srcIn),
                  ),
                ),

                const SizedBox(width: 16),

                // Water Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.jumlahHidrasi.toInt()} mL",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimaryColor,
                      ),
                    ),
                    Text(
                      "Konsumsi Air",
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondaryColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Time with icon
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: _textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          padding: const EdgeInsets.only(bottom: 80), // Large bottom padding
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
}