import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// Pastikan path ini sesuai dengan struktur proyek Anda
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:intl/intl.dart';

// Asumsi AppEvent sudah terdefinisi di app_event_bus.dart
// Jika belum, Anda bisa menggunakan definisi sederhana ini untuk sementara:
// class AppEvent {
//   final String type;
//   final dynamic data;
//   AppEvent({required this.type, this.data});
// }

enum StatisticPeriod { weekly, monthly, yearly }

class HydrationStatsChart extends StatefulWidget {
  final Color accentColor;
  final Color? cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  HydrationStatsChart({
    super.key,
    this.accentColor = Colors.blueAccent, // Warna aksen yang lebih cerah
    this.cardColor,
    this.primaryTextColor = Colors.black87, // Warna teks primer yang sedikit lebih lembut
    this.secondaryTextColor = Colors.black54, // Warna teks sekunder yang sedikit lebih lembut
  });

  @override
  State<HydrationStatsChart> createState() => _HydrationStatsChartState();
}

class _HydrationStatsChartState extends State<HydrationStatsChart> {
  int touchedIndex = -1;
  StatisticPeriod currentPeriod = StatisticPeriod.weekly;
  int currentIndex = 0;
  bool _isTargetLoading = false;
  List<Map<String, dynamic>> _processedChartPoints = [];
  final TargetHidrasiRepository _targetHidrasiRepository = TargetHidrasiRepository();

  late RiwayatHidrasiController _riwayatHidrasiController;
  bool _isChartLoading = true;
  List<BarChartGroupData> _barGroups = [];
  List<String> _axisLabels = [];
  double _maxYValue = 100; // Default untuk Y-axis persentase (0-100% + buffer)
  int? _userId;

  final AppEventBus _eventBus = AppEventBus();
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    print("[HydrationStatsChart] initState called");
    _riwayatHidrasiController = RiwayatHidrasiController();
    _loadInitialData();

    _eventSubscription = _eventBus.stream.listen((AppEvent event) {
      if (event.type == 'refresh_statistics' || event.type == 'refresh_all') {
        print("[HydrationStatsChart] Menerima event: ${event.type}. Memuat ulang data chart...");
        if (mounted) {
          _loadInitialData();
        }
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    print("[HydrationStatsChart] _loadInitialData called");
    if (!mounted) return;

    if (_userId == null) {
      final session = SessionManager();
      _userId = await session.getUserId();
    }

    if (_userId != null) {
      await _fetchChartData(_userId!);
    } else {
      if (mounted) {
        setState(() {
          _isChartLoading = false;
          _barGroups = [];
          _axisLabels = [];
          _processedChartPoints = [];
          _maxYValue = 100; // Reset maxYValue
          print("[HydrationStatsChart] User ID tidak ditemukan, chart tidak bisa dimuat.");
        });
      }
    }
  }

  Future<void> _fetchChartData(int userId) async {
    if (!mounted) return;
    setState(() {
      _isChartLoading = true;
      // Kosongkan data sebelumnya agar tidak ada tampilan data lama saat loading
      _barGroups = [];
      _axisLabels = [];
      _processedChartPoints = [];
    });

    DateTime referenceDate = _calculateReferenceDate();
    print("[Chart] Fetching data for period: $currentPeriod, referenceDate: $referenceDate, currentIndex: $currentIndex");

    await _riwayatHidrasiController.fetchStatistikData(
        userId: userId,
        periode: currentPeriod, // Pastikan tipe ini sesuai dengan yang diharapkan controller
        referensiTanggal: referenceDate);

    if (mounted && _riwayatHidrasiController.statistikData.isNotEmpty) {
      await _processRawDataToPercentages(userId, _riwayatHidrasiController.statistikData, referenceDate);
    } else if (mounted) {
      setState(() {
        _processedChartPoints = [];
        _barGroups = [];
        _axisLabels = [];
        _maxYValue = 100;
        _isTargetLoading = false;
      });
    }

    if (mounted) {
      setState(() {
        _isChartLoading = false;
        touchedIndex = -1;
      });
      print("[Chart] _fetchChartData selesai. _isChartLoading: $_isChartLoading, _isTargetLoading: $_isTargetLoading");
      print("[Chart] Data untuk chart: BarGroups: ${_barGroups.length}, MaxY: $_maxYValue");
    }
  }

  Future<void> _processRawDataToPercentages(int userId, List<Map<String, dynamic>> rawDataMl, DateTime referenceDateForPeriod) async {
    if (!mounted) return;
    setState(() {
      _isTargetLoading = true;
    });

    List<Map<String, dynamic>> tempProcessedPoints = [];
    List<BarChartGroupData> tempBarGroups = [];
    List<String> tempAxisLabels = [];
    double newCalculatedMaxY = 100.0; // Default max Y untuk persentase

    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = _calculateBarWidth(screenWidth);

    final String todayForTarget = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7))); // Sesuaikan zona waktu jika perlu
    print("[ChartStats - _processRawDataToPercentages] Memanggil _targetHidrasiRepository.getTargetHidrasiHarian untuk userId: $userId, tanggal: $todayForTarget");
    final targetDataToday = await _targetHidrasiRepository.getTargetHidrasiHarian(userId, todayForTarget);
    double dailyTargetGeneral = (targetDataToday?['target_hidrasi'] as num?)?.toDouble() ?? 2500.0;
    if (dailyTargetGeneral <= 0) dailyTargetGeneral = 2500.0;
    print("[ChartStats - _processRawDataToPercentages] Menggunakan dailyTargetGeneral: $dailyTargetGeneral ml untuk perhitungan persentase.");

    if (rawDataMl.isNotEmpty) {
      bool anyExceeds100 = false;
      for (int i = 0; i < rawDataMl.length; i++) {
        final item = rawDataMl[i];
        final x = (item['x'] as num).toInt();
        final yMl = (item['y'] as num).toDouble();
        final label = item['label'] as String? ?? '';
        double percentage = 0;
        double currentPeriodTargetMl = dailyTargetGeneral;

        if (currentPeriod == StatisticPeriod.weekly) {
          currentPeriodTargetMl = dailyTargetGeneral;
        } else if (currentPeriod == StatisticPeriod.monthly) {
          currentPeriodTargetMl = dailyTargetGeneral * 7; // Asumsi target mingguan untuk perbandingan di chart bulanan per minggu
        } else if (currentPeriod == StatisticPeriod.yearly) {
          currentPeriodTargetMl = dailyTargetGeneral * 30.44; // Asumsi target bulanan untuk perbandingan di chart tahunan per bulan
        }

        if (currentPeriodTargetMl > 0) {
          percentage = (yMl / currentPeriodTargetMl) * 100;
        }
        if (percentage > 100) anyExceeds100 = true;
        percentage = percentage.clamp(0.0, 150.0); // Izinkan data persentase > 100 (misal max 150% untuk data), tapi tampilan bar akan diklem

        tempProcessedPoints.add({
          'x': x,
          'originalY_ml': yMl,
          'target_ml_for_period': currentPeriodTargetMl,
          'percentageY': percentage, // Persentase aktual untuk tooltip
          'label': label
        });

        double barDisplayPercentage = percentage.clamp(0.0, 100.0); // Klem tinggi bar visual di 100%
        tempBarGroups.add(makeGroupData(x, barDisplayPercentage, barWidth: barWidth, isTouched: x == touchedIndex));
        tempAxisLabels.add(label);
      }
      newCalculatedMaxY = anyExceeds100 ? 100.0 : 100.0; // Beri headroom jika ada data > 100%
    } else {
      newCalculatedMaxY = 100.0; // Default untuk chart kosong
    }

    print("[ChartStats - _processRawDataToPercentages] tempBarGroups yang akan di-set: ${tempBarGroups.length}");

    if (mounted) {
      setState(() {
        _processedChartPoints = tempProcessedPoints;
        _barGroups = tempBarGroups;
        _axisLabels = tempAxisLabels;
        _maxYValue = newCalculatedMaxY; // Update maxYValue
        _isTargetLoading = false;
        print("[ChartStats - _processRawDataToPercentages] Selesai. BarGroups: ${_barGroups.length}, AxisLabels: ${_axisLabels.length}, MaxY: $_maxYValue");
      });
    }
  }

  DateTime _calculateReferenceDate() {
    final now = DateTime.now();
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        DateTime targetDay = now.subtract(Duration(days: currentIndex * 7));
        return targetDay.add(Duration(days: DateTime.sunday - targetDay.weekday));
      case StatisticPeriod.monthly:
        return DateTime(now.year, now.month - currentIndex, 1);
      case StatisticPeriod.yearly:
        return DateTime(now.year - currentIndex, 1, 1);
    }
  }

  double _calculateBarWidth(double screenWidth) {
    int numberOfBars = 7;
    if(currentPeriod == StatisticPeriod.monthly) numberOfBars = _axisLabels.isNotEmpty ? _axisLabels.length : 4;
    else if(currentPeriod == StatisticPeriod.yearly) numberOfBars = 12;

    if (numberOfBars == 0) numberOfBars = 7; // fallback

    double totalGroupSpace = screenWidth / numberOfBars;
    double calculatedBarWidth = totalGroupSpace * 0.5;

    return calculatedBarWidth.clamp(8.0, 22.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final optimalHeight = _calculateOptimalHeight(availableWidth);

      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          _buildChartCard(context, optimalHeight, availableWidth),
        ],
      );
    });
  }

  Widget _buildPeriodSelector() {
    final Color unselectedButtonColor = widget.cardColor ?? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: unselectedButtonColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildPeriodButton('Mingguan', StatisticPeriod.weekly)),
          Expanded(child: _buildPeriodButton('Bulanan', StatisticPeriod.monthly)),
          Expanded(child: _buildPeriodButton('Tahunan', StatisticPeriod.yearly)),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, StatisticPeriod period) {
    final isSelected = currentPeriod == period;
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            currentPeriod = period;
            currentIndex = 0;
            _isChartLoading = true;
          });
          _loadInitialData();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : widget.primaryTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  double _calculateOptimalHeight(double width) {
    if (width < 300) {
      return 320;
    } else if (width < 400) {
      return 360;
    } else {
      return 390;
    }
  }

  Widget _buildChartCard(BuildContext context, double height, double width) {
    final horizontalPadding = width < 350 ? 10.0 : 16.0;
    final titlePadding = width < 350 ? 12.0 : 16.0;
    final chartPaddingHorizontal = width < 350 ? 8.0 : 12.0;
    final chartPaddingTop = 16.0;

    // Perhitungan barWidth dan groupSpace dipindahkan ke sini agar context selalu tersedia
    // dan ukuran chart yang sebenarnya (setelah padding) digunakan.
    // Perlu 40 untuk reservedSize Y-axis kiri, dan padding horizontal kiri kanan dari chart itu sendiri
    final double chartAreaWidth = width - (horizontalPadding * 2) - (chartPaddingHorizontal * 2) - 44;
    final barWidthValue = _calculateBarWidth(chartAreaWidth);
    final groupSpace = barWidthValue * 0.8;

    final titleFontSize = width < 350 ? 17.0 : 19.0;
    final subtitleFontSize = width < 350 ? 11.0 : 12.5;
    final legendFontSize = width < 350 ? 10.0 : 11.0;

    final cardBgColor = widget.cardColor ?? Theme.of(context).cardColor;

    Widget chartContent;
    if (_isChartLoading || _isTargetLoading) {
      chartContent = Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: widget.accentColor));
    } else if (_userId == null) {
      chartContent = Center(
        key: ValueKey('no_user'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "User ID tidak ditemukan.\nStatistik tidak dapat dimuat.",
            style: TextStyle(color: widget.secondaryTextColor, fontSize: subtitleFontSize, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_barGroups.isEmpty) {
      chartContent = Center(
        key: ValueKey('no_data'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Tidak ada data untuk periode ini.",
            style: TextStyle(color: widget.secondaryTextColor, fontSize: subtitleFontSize, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      chartContent = BarChart(
        key: ValueKey('chart_data'),
        mainBarData(barWidthValue, groupSpace),
        swapAnimationDuration: Duration(milliseconds: 350),
        swapAnimationCurve: Curves.easeInOutCubic,
      );
    }

    return Container(
      height: height,
      child: Card(
        color: cardBgColor,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8, left: 4, right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(titlePadding, titleFontSize, subtitleFontSize),
              _buildNavigationRow(titlePadding),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: chartPaddingHorizontal,
                    right: chartPaddingHorizontal,
                    top: chartPaddingTop,
                    bottom: 8,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: chartContent,
                  ),
                ),
              ),
              if (!_isChartLoading && !_isTargetLoading && _barGroups.isNotEmpty && _userId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                  child: Center(
                    child: _buildLegend(legendFontSize),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double horizontalTitlePadding, double titleFontSize, double subtitleFontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalTitlePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 2),
            child: Text(
              _getChartTitle(),
              style: TextStyle(
                color: widget.primaryTextColor,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Persentase pencapaian target hidrasi',
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: subtitleFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(double horizontalNavPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalNavPadding - 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Periode Sebelumnya',
            splashRadius: 20,
            onPressed: _canNavigatePrevious()
                ? () {
                    if (mounted) {
                      setState(() {
                        currentIndex++;
                        touchedIndex = -1;
                         _isChartLoading = true;
                      });
                      _loadInitialData();
                    }
                  }
                : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: _canNavigatePrevious() ? widget.primaryTextColor : widget.secondaryTextColor.withOpacity(0.4),
            ),
          ),
          Expanded(
            child: Text(
              _getCurrentPeriodLabel(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.primaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Periode Berikutnya',
            splashRadius: 20,
            onPressed: _canNavigateNext()
                ? () {
                    if (mounted) {
                      setState(() {
                        currentIndex--;
                        touchedIndex = -1;
                        _isChartLoading = true;
                      });
                      _loadInitialData();
                    }
                  }
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: _canNavigateNext() ? widget.primaryTextColor : widget.secondaryTextColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return 'Statistik Mingguan';
      case StatisticPeriod.monthly:
        return 'Statistik Bulanan';
      case StatisticPeriod.yearly:
        return 'Statistik Tahunan';
    }
  }

  String _getCurrentPeriodLabel() {
    final now = DateTime.now();
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        final weekDate = now.subtract(Duration(days: currentIndex * 7));
        if (currentIndex == 0) return 'Minggu Ini (${_getMonthName(weekDate.month)} ${weekDate.year})';
        if (currentIndex == 1) return 'Minggu Lalu (${_getMonthName(weekDate.month)} ${weekDate.year})';
        // Untuk minggu yang lebih lama, bisa menampilkan rentang tanggal
        final firstDayOfWeek = weekDate.subtract(Duration(days: weekDate.weekday % 7)); // Minggu
        final lastDayOfWeek = firstDayOfWeek.add(Duration(days: 6)); // Sabtu
        return '${DateFormat('d MMM').format(firstDayOfWeek)} - ${DateFormat('d MMM yyyy').format(lastDayOfWeek)}';
      case StatisticPeriod.monthly:
        final monthDate = DateTime(now.year, now.month - currentIndex, 1);
        return '${_getMonthName(monthDate.month)} ${monthDate.year}';
      case StatisticPeriod.yearly:
        return 'Tahun ${now.year - currentIndex}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }

  bool _canNavigatePrevious() {
    return currentIndex < _getMaxIndex();
  }

  bool _canNavigateNext() {
    return currentIndex > 0;
  }

  int _getMaxIndex() {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return 52 * 2; // Maks 2 tahun
      case StatisticPeriod.monthly:
        return 12 * 2; // Maks 2 tahun
      case StatisticPeriod.yearly:
        return 5; // Maks 5 tahun
    }
  }

  Widget _buildLegend(double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.accentColor.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Pencapaian Target (%)',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: widget.primaryTextColor.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  BarChartData mainBarData(double barWidth, double groupSpace) {
    final screenWidth = MediaQuery.of(context).size.width;
    return BarChartData(
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.black87.withOpacity(0.9),
          tooltipBorder: BorderSide(color: widget.accentColor.withOpacity(0.5), width: 0.5),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          tooltipMargin: 10,
           // Jika fl_chart Anda versi < 0.60.0, tooltipRoundedRadius mungkin belum ada
           // tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (groupIndex < 0 || groupIndex >= _processedChartPoints.length) {
              return null;
            }
            final pointData = _processedChartPoints[groupIndex];
            final String label = pointData['label'];
            final double actualPercentage = pointData['percentageY']; // Persentase aktual bisa > 100
            final double originalMl = pointData['originalY_ml'];

            return BarTooltipItem(
              '$label\n',
              TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: (screenWidth < 350 ? 11.5 : 13),
                height: 1.3,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '${actualPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: (screenWidth < 350 ? 10.5 : 12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' (${originalMl.toStringAsFixed(0)} ml)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: (screenWidth < 350 ? 9.5 : 11),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
              textAlign: TextAlign.center,
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          if (mounted) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          }
        },
        handleBuiltInTouches: true,
        touchExtraThreshold: EdgeInsets.all(4),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 28,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: screenWidth < 350 ? 38 : 44,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value < 0 || value > _maxYValue) return Container();
              if (value == 0 && _maxYValue > 25) return Container();
              if (value > 100 && _maxYValue <= 100) return Container();

              final style = TextStyle(
                color: widget.secondaryTextColor,
                fontWeight: FontWeight.w500,
                fontSize: (screenWidth < 350 ? 9 : 10.5),
              );
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text('${value.toInt()}%', style: style, textAlign: TextAlign.right),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: widget.secondaryTextColor.withOpacity(0.3), width: 1),
          left: BorderSide(color: widget.secondaryTextColor.withOpacity(0.3), width: 1),
        ),
      ),
      barGroups: _barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
           if (value == 0 && _maxYValue > 25) return FlLine(color: Colors.transparent);
          return FlLine(
            color: widget.secondaryTextColor.withOpacity(0.15),
            strokeWidth: 0.8,
          );
        },
      ),
      groupsSpace: groupSpace,
      maxY: _maxYValue,
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, // Ini adalah barDisplayPercentage (0-100)
    {bool isTouched = false, required double barWidth}
  ) {
    final rodColor = isTouched ? widget.accentColor.withOpacity(0.9) : widget.accentColor;
    final rodY = isTouched ? (y + (100 * 0.05)).clamp(y, 100.0) : y.clamp(0.0, 100.0); // Pastikan y juga di-clamp

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: rodY, // rodY sudah di-clamp ke 100%
          gradient: LinearGradient(
            colors: [
              rodColor,
              rodColor.withOpacity(isTouched ? 0.7 : 0.6)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: barWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100, // Latar belakang hingga 100%
            color: widget.accentColor.withOpacity(0.08),
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    final screenWidth = MediaQuery.of(context).size.width;
    final style = TextStyle(
        color: widget.secondaryTextColor,
        fontWeight: FontWeight.w500,
        fontSize: (screenWidth < 350 ? 9.0 : 10.0));

    String textToDisplay = '';
    int index = value.toInt();

    if (index >= 0 && index < _axisLabels.length) {
      textToDisplay = _axisLabels[index];
      // Anda bisa menambahkan logika pemotongan label di sini jika diperlukan
      // Misalnya:
      // if (currentPeriod == StatisticPeriod.weekly && textToDisplay.length > 3 && screenWidth < 380) {
      //   textToDisplay = textToDisplay.substring(0, 1); // Hanya huruf pertama untuk mingguan jika sempit
      // } else if (textToDisplay.length > 5 && screenWidth < 380) {
      //    textToDisplay = textToDisplay.substring(0,3) + "..";
      // }
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(textToDisplay, style: style, overflow: TextOverflow.ellipsis),
    );
  }

  // Fungsi-fungsi placeholder yang tidak terpakai jika data dari controller:
  // _generateAxisLabels, _calculateDynamicMaxY, _processDataToBarGroups,
  // showingGroups, _getWeeklyData, _getMonthlyData, _getYearlyData.
  // Anda bisa menghapusnya jika yakin tidak akan dipakai.
  // Saya membiarkannya karena ada di kode asli yang Anda berikan.

   List<String> _generateAxisLabels(List<Map<String, dynamic>> data) {
     if (data.isEmpty) return [];
     return data.map((item) => item['label'] as String? ?? '').toList();
   }

   double _calculateDynamicMaxY(List<Map<String, dynamic>> data) {
     if (data.isEmpty) return 100;
     double maxPercent = 0;

     for (var item in data) {
       if ((item['percentageY'] as num).toDouble() > maxPercent) {
         maxPercent = (item['percentageY'] as num).toDouble();
       }
     }
     return maxPercent > 100 ? (maxPercent * 1.1).clamp(110, 150) : 100;
   }

   List<BarChartGroupData> _processDataToBarGroups(List<Map<String, dynamic>> data) {
     final barWidth = _calculateBarWidth(MediaQuery.of(context).size.width);
     return data.map((item) {
       final x = (item['x'] as num).toInt();
       // Jika data 'y' adalah persentase, maka perlu di-clamp ke 100 untuk bar
       final y = (item['percentageY'] as num).toDouble().clamp(0.0, 100.0);
       return makeGroupData(x, y, barWidth: barWidth, isTouched: x == touchedIndex);
     }).toList();
   }
}