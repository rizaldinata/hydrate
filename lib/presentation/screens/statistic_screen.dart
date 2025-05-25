import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/locator.dart'; 
import 'package:lottie/lottie.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({Key? key}) : super(key: key);

  @override
  StatisticScreenState createState() => StatisticScreenState();
}

class StatisticScreenState extends State<StatisticScreen> {
  final Color _primaryColor = const Color(0xFF00A6FB);
  final Color _accentColor = const Color(0xFF38BDF8);
  final Color _backgroundColor = const Color(0xFFE8F7FF);
  final Color _textPrimaryColor = const Color(0xFF0F172A);
  final Color _textSecondaryColor = const Color(0xFF475569);
  final Color _surfaceColor = Colors.white;

  List<RiwayatHidrasi> waterHistory = [];
  DateTime selectedDate = DateTime.now();
  final RiwayatHidrasiController _riwayatController = RiwayatHidrasiController();

  bool isLoading = true;
  int? userId;
  String? errorMessage;
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();
  RiwayatHidrasi? _lastDeletedItem;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _initData();
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_statistics' || event.type == 'refresh_all') {
        refresh();
      }
    });
  }

  void refresh() {
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    DateTime startOfSelectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    if (startOfSelectedDate.isAtSameMomentAs(startOfToday)) {
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
      final sessionManager = locator<SessionManager>();
      userId = await sessionManager.getUserId();

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
          await _riwayatController.getRiwayatHidrasiByTanggal(userId!, selectedDate);
      if (mounted) {
        setState(() {
          waterHistory = _riwayatController.sortRiwayatByWaktuDescending(history);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Kesalahan saat memuat riwayat: $e";
        });
      }
    }
  }

  bool _isTodayRecord(RiwayatHidrasi item) {
    final today = DateTime.now();
    final recordDate = DateTime.parse(item.tanggalHidrasi ?? today.toString());
    return recordDate.year == today.year &&
        recordDate.month == today.month &&
        recordDate.day == today.day;
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

  void _showSnackBarNotification({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    bool isSuccess = false,
  }) {
    _undoTimer?.cancel();
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      duration: duration,
      backgroundColor: isSuccess ? Colors.green.shade600 : _accentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(10),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

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
            color: _primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded,
                color: _primaryColor, size: 32),
            onPressed: () =>
                _changeDate(selectedDate.subtract(const Duration(days: 1))),
          ),
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
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isToday ? Colors.grey.shade400 : _primaryColor,
              size: 32,
            ),
            onPressed: isToday
                ? null
                : () => _changeDate(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

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
                  _primaryColor.withOpacity(0.2)
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

  Widget _buildItemCard(RiwayatHidrasi item, String time, bool isSmallScreen,
      double screenWidth, bool isTodayRecord) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _primaryColor.withValues(alpha: 0.1),
          highlightColor: _primaryColor.withValues(alpha: 0.05),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/glass.svg',
                    width: isSmallScreen ? 24 : 32,
                    height: isSmallScreen ? 24 : 32,
                    colorFilter:
                        ColorFilter.mode(_primaryColor, BlendMode.srcIn),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
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
                          // SizedBox(width: isSmallScreen ? 4 : 8),
                          // LayoutBuilder(builder: (context, constraints) {
                          //   final int maxDots = isSmallScreen ? 3 : 5;
                          //   final int dots = min(
                          //       (item.jumlahHidrasi / 100)
                          //           .clamp(1, maxDots)
                          //           .toInt(),
                          //       maxDots);
                          //   return Row(
                          //     children: List.generate(
                          //       dots,
                          //       (index) => Container(
                          //         margin: const EdgeInsets.only(right: 2),
                          //         width: isSmallScreen ? 4 : 6,
                          //         height: isSmallScreen ? 4 : 6,
                          //         decoration: BoxDecoration(
                          //           color: _primaryColor,
                          //           shape: BoxShape.circle,
                          //         ),
                          //       ),
                          //     ),
                          //   );
                          // }),
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
                if (isTodayRecord)
                  Icon(
                    Icons.chevron_left,
                    color: _textSecondaryColor.withValues(alpha: 0.5),
                    size: isSmallScreen ? 18 : 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterIntakeItem(RiwayatHidrasi item) {
    final String time = item.waktuHidrasi ?? "00:00";
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    final bool isTodayRecord = _isTodayRecord(item);

    if (!isTodayRecord) {
      return _buildItemCard(item, time, isSmallScreen, screenWidth, false);
    }

    return Dismissible(
      key:  Key(item.syncId ?? item.id.toString()),
      background: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent.shade200, Colors.red.shade800],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: screenWidth * 0.06),
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
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/delete.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: 12), // Jarak antar icon dan title
                // Center(
                //   child: const Text(
                //     "Konfirmasi Hapus",
                //     style: TextStyle(fontWeight: FontWeight.w800,),
                //   ),
                // ),
                // SizedBox(height: 12), // Jarak antar title dan content
              ],
            ),
            contentTextStyle: TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            content: Text(
              "Apakah kamu yakin menghapus catatan ${item.jumlahHidrasi.toInt()} mL ini?",
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            actions: [
              SizedBox(
                width: 80,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: const Color(0xFF0F172A)),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16), // atur radius di sini
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Hapus",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16), // atur radius di sini
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _lastDeletedItem = item;
        setState(() => waterHistory.remove(item));

        _showSnackBarNotification(
          message: "Catatan hidrasi telah dihapus",
          actionLabel: "BATALKAN",
          onAction: () {
            if (_lastDeletedItem != null) {
              setState(() {
                waterHistory.add(_lastDeletedItem!);
                waterHistory = _riwayatController.sortRiwayatByWaktuDescending(waterHistory);
              });
              _lastDeletedItem = null;
              _showSnackBarNotification(
                message: "Catatan telah dipulihkan",
                duration: const Duration(seconds: 2),
                isSuccess: true,
              );
            }
          },
        );

        _undoTimer = Timer(const Duration(seconds: 4), () async { // Tambahkan async
          if (_lastDeletedItem != null) {
            if (_lastDeletedItem!.syncId == null) {
              print("Error: syncId tidak ditemukan untuk item yang akan dihapus.");
              // Handle error, mungkin item ini belum pernah disinkronkan atau model tidak lengkap
              return;
            }
            // ========================================================
            //           PERUBAHAN PENTING ADA DI SINI
            // ========================================================
            await _riwayatController.hapusRiwayatDanUpdateTotal( // Tambahkan await
              riwayatSyncId: _lastDeletedItem!.syncId!, // Pastikan model punya syncId
              idPengguna: userId!, // userId sudah ada di state
              tanggalHidrasi: _lastDeletedItem!.tanggalHidrasi ?? DateFormat('yyyy-MM-dd').format(selectedDate),
            );
            // ========================================================
          }
          _lastDeletedItem = null;
        });
      },
      child: _buildItemCard(item, time, isSmallScreen, screenWidth, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Riwayat Hidrasi",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDateNavigation(),
            if (errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor))
                  : waterHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: waterHistory.length,
                          itemBuilder: (context, index) =>
                              _buildWaterIntakeItem(waterHistory[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}
