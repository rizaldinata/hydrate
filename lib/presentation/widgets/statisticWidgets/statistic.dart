import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:intl/intl.dart';

enum StatisticPeriod { weekly, monthly, yearly }

class HydrationStatsChart extends StatefulWidget {
  final Color accentColor;
  final Color? cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  HydrationStatsChart({
    super.key,
    this.accentColor = Colors.blue,
    this.cardColor,
    this.primaryTextColor = Colors.black,
    this.secondaryTextColor = Colors.grey,
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
  double _maxYValue = 2500;
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
    
    // Gunakan variabel instance _userId
    if (_userId == null) { 
      final session = SessionManager();
      // Tetapkan nilai ke variabel instance _userId
      _userId = await session.getUserId(); 
    }

    if (_userId != null) {
      // Teruskan nilai _userId yang sudah pasti tidak null
      await _fetchChartData(_userId!); 
    } else {
      if (mounted) {
        setState(() {
          _isChartLoading = false;
          _barGroups = [];
          _axisLabels = [];
          _processedChartPoints = [];
          print("[HydrationStatsChart] User ID tidak ditemukan, chart tidak bisa dimuat.");
        });
      }
    }
  }

  Future<void> _fetchChartData(int userId) async {
    if (!mounted) return;
    setState(() {
      _isChartLoading = true;
    });

    DateTime referenceDate = _calculateReferenceDate();
    print("[Chart] Fetching data for period: $currentPeriod, referenceDate: $referenceDate, currentIndex: $currentIndex");

    await _riwayatHidrasiController.fetchStatistikData(
      userId: userId, 
      periode: currentPeriod, 
      referensiTanggal: referenceDate
    );

    if (_riwayatHidrasiController.statistikData.isNotEmpty) {
      await _processRawDataToPercentages(userId, _riwayatHidrasiController.statistikData, referenceDate);
    } else {
      // Jika tidak ada data mentah, pastikan semua state chart dikosongkan dan loading selesai
      if (mounted) {
        setState(() {
          _processedChartPoints = [];
          _barGroups = [];
          _axisLabels = [];
          _maxYValue = 110; 
          _isTargetLoading = false; // Penting
        });
      }
    }

    if (mounted) {
      setState(() {;
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
      _barGroups = [];
      _axisLabels = [];
      _processedChartPoints = [];
    });

    List<Map<String, dynamic>> tempProcessedPoints = [];
    List<BarChartGroupData> tempBarGroups = [];
    List<String> tempAxisLabels = [];
    double calculatedMaxY = 100.0;

    final barWidth = _calculateBarWidth(MediaQuery.of(context).size.width);

    final String todayForTarget = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    print("[ChartStats - _processRawDataToPercentages] Memanggil _targetHidrasiRepository.getTargetHidrasiHarian untuk userId: $userId, tanggal: $todayForTarget");
    final targetDataToday = await _targetHidrasiRepository.getTargetHidrasiHarian(userId, todayForTarget);
    double dailyTargetGeneral = (targetDataToday?['target_hidrasi'] as num?)?.toDouble() ?? 2500.0; 
    if (dailyTargetGeneral <= 0) dailyTargetGeneral = 2500.0;
    print("[ChartStats - _processRawDataToPercentages] Menggunakan dailyTargetGeneral: $dailyTargetGeneral ml untuk perhitungan persentase.");

     if (rawDataMl.isNotEmpty) {
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
            currentPeriodTargetMl = dailyTargetGeneral * 7; 
          } else if (currentPeriod == StatisticPeriod.yearly) {
            currentPeriodTargetMl = dailyTargetGeneral * 30.44; 
          }

          if (currentPeriodTargetMl > 0) {
            percentage = (yMl / currentPeriodTargetMl) * 100;
          }
          percentage = percentage.clamp(0.0, 150.0); 

          tempProcessedPoints.add({
            'x': x,
            'originalY_ml': yMl,
            'target_ml_for_period': currentPeriodTargetMl,
            'percentageY': percentage,
            'label': label
          });

          double barDisplayPercentage = percentage.clamp(0.0, 100.0); 
          tempBarGroups.add(makeGroupData(x, barDisplayPercentage, barWidth: barWidth, isTouched: x == touchedIndex));
          tempAxisLabels.add(label);
      }
     }

    print("[ChartStats - _processRawDataToPercentages] tempBarGroups yang akan di-set: $tempBarGroups");

    if (mounted) {
      setState(() {
        _processedChartPoints = tempProcessedPoints;
        _barGroups = tempBarGroups;
        _axisLabels = tempAxisLabels;
        _maxYValue = calculatedMaxY; 
        _isTargetLoading = false;
        print("[ChartStats - _processRawDataToPercentages] Selesai. BarGroups: ${_barGroups.length}, AxisLabels: ${_axisLabels.length}");
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

  List<String> _generateAxisLabels(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];
    return data.map((item) => item['label'] as String? ?? '').toList();
  }

  double _calculateDynamicMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 110; 
    double maxPercent = 0;

    for (var item in data) {
      if ((item['percentageY'] as num).toDouble() > maxPercent) {
         maxPercent = (item['percentageY'] as num).toDouble();
      }
    }

    return maxPercent > 100 ? (maxPercent * 1.1).clamp(110, 150) : 110;
  }

  List<BarChartGroupData> _processDataToBarGroups(List<Map<String, dynamic>> data) {
    final barWidth = _calculateBarWidth(MediaQuery.of(context).size.width); // Hitung barWidth
    return data.map((item) {
      final x = (item['x'] as num).toInt();
      final y = (item['y'] as num).toDouble();
      return makeGroupData(x, y, barWidth: barWidth, isTouched: x == touchedIndex);
    }).toList();
  }
  
  double _calculateBarWidth(double screenWidth) {
    // Logika yang sama seperti di _buildChartCard Anda
    return screenWidth < 300 ? 8.0 : (screenWidth < 400 ? 10.0 : 12.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final optimalHeight = _calculateOptimalHeight(availableWidth);
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            _buildChartCard(context, optimalHeight, availableWidth),
          ],
        );
      }
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.cardColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Mingguan', StatisticPeriod.weekly),
          ),
          Expanded(
            child: _buildPeriodButton('Bulanan', StatisticPeriod.monthly),
          ),
          Expanded(
            child: _buildPeriodButton('Tahunan', StatisticPeriod.yearly),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, StatisticPeriod period) {
    final isSelected = currentPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentPeriod = period;
          currentIndex = 0; 
        });
        _loadInitialData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? widget.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : widget.primaryTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    final horizontalPadding = width < 350 ? 8.0 : 16.0;
    final titlePadding = width < 350 ? 12.0 : 20.0;
    final chartPadding = width < 350 ? 8.0 : 16.0;
    
    final barWidth = width < 300 ? 8.0 : (width < 400 ? 10.0 : 12.0);
    final groupSpace = width < 300 ? 8.0 : (width < 400 ? 12.0 : 14.0);
    
    final titleFontSize = width < 350 ? 16.0 : 20.0;
    final subtitleFontSize = width < 350 ? 10.0 : 12.0;
    final legendFontSize = width < 350 ? 10.0 : 11.0;
    
    return Container(
      height: height,
      child: Card(
        color: widget.cardColor,
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(titlePadding, titleFontSize, subtitleFontSize),
              _buildNavigationRow(titlePadding),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(chartPadding, 16, chartPadding, 0),
                  child: BarChart(
                    _isChartLoading 
                        ? BarChartData() 
                        : mainBarData(barWidth, groupSpace), 
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildHeader(double titlePadding, double titleFontSize, double subtitleFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(titlePadding, 16, titlePadding, 0),
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
          padding: EdgeInsets.fromLTRB(titlePadding, 4, titlePadding, 0),
          child: Text(
            _getChartSubtitle(),
            style: TextStyle(
              color: widget.secondaryTextColor,
              fontSize: subtitleFontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRow(double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _canNavigatePrevious() ? () {
              setState(() {
                currentIndex++;
                touchedIndex = -1;
              });
              _loadInitialData();
            } : null,
            icon: Icon(
              Icons.chevron_left,
              color: _canNavigatePrevious() ? widget.primaryTextColor : Colors.grey.withOpacity(0.5),
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
            ),
          ),
          IconButton(
            onPressed: _canNavigateNext() ? () {
              setState(() {
                currentIndex--;
                touchedIndex = -1;
              });
              _loadInitialData();
            } : null,
            icon: Icon(
              Icons.chevron_right,
              color: _canNavigateNext() ? widget.primaryTextColor : Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return 'Hidrasi Mingguan';
      case StatisticPeriod.monthly:
        return 'Hidrasi Bulanan';
      case StatisticPeriod.yearly:
        return 'Hidrasi Tahunan';
    }
  }

  String _getChartSubtitle() {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return 'Konsumsi air harian dalam mililiter (ml)';
      case StatisticPeriod.monthly:
        return 'Konsumsi air mingguan dalam mililiter (ml)';
      case StatisticPeriod.yearly:
        return 'Konsumsi air bulanan dalam mililiter (ml)';
    }
  }

  String _getCurrentPeriodLabel() {
    final now = DateTime.now();
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        final weekDate = now.subtract(Duration(days: currentIndex * 7));
        return 'Minggu ${_getWeekOfMonth(weekDate)} - ${_getMonthName(weekDate.month)} ${weekDate.year}';
      case StatisticPeriod.monthly:
        final monthDate = DateTime(now.year, now.month - currentIndex, 1);
        return '${_getMonthName(monthDate.month)} ${monthDate.year}';
      case StatisticPeriod.yearly:
        return 'Tahun ${now.year - currentIndex}';
    }
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysDifference = date.difference(firstDayOfMonth).inDays;
    return (daysDifference / 7).floor() + 1;
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
        return 52; // 52 minggu dalam setahun
      case StatisticPeriod.monthly:
        return 12; // 12 bulan
      case StatisticPeriod.yearly:
        return 5; // 5 tahun ke belakang
    }
  }

  Widget _buildLegend(double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.accentColor.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Konsumsi Air',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: widget.primaryTextColor,
          ),
        ),
      ],
    );
  }

  BarChartData mainBarData(double barWidth, double groupSpace) {
  return BarChartData(
    barTouchData: BarTouchData( // (LOGIKA TOOLTIP AKAN DIPERBARUI DI BAWAH)
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
        tooltipBorder: BorderSide.none,
        tooltipMargin: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          if (groupIndex < 0 || groupIndex >= _processedChartPoints.length) {
            return null;
          }
          final pointData = _processedChartPoints[groupIndex];
          final String label = pointData['label'];
          final double percentage = rod.toY; // Ini sudah persentase
          final double originalMl = pointData['originalY_ml'];
          
          return BarTooltipItem(
            '$label\n',
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: (MediaQuery.of(context).size.width < 350 ? 11 : 13),
            ),
            children: <TextSpan>[
              TextSpan(
                text: '${percentage.toStringAsFixed(0)}%', // Tampilkan persentase
                style: TextStyle(
                  color: widget.accentColor, // Warna aksen Anda
                  fontSize: (MediaQuery.of(context).size.width < 350 ? 10 : 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: ' (${originalMl.toStringAsFixed(0)} ml)', // Tampilkan ml asli
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: (MediaQuery.of(context).size.width < 350 ? 9 : 11),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
      touchCallback: (FlTouchEvent event, barTouchResponse) {
        // ... (logika touchCallback Anda tetap sama) ...
      },
    ),
    titlesData: FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: getTitles, // getTitles sekarang menggunakan _axisLabels dari state
          reservedSize: 24,
        ),
      ),
      leftTitles: AxisTitles( // KONFIGURASI SUMBU Y (KIRI) UNTUK PERSENTASE
        sideTitles: SideTitles(
          showTitles: true,
          interval: 20, // Tampilkan label setiap 20%
          reservedSize: (MediaQuery.of(context).size.width < 350 ? 28 : 36), // Ruang untuk label
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value > 100 || value < 0) return Container(); // Hanya 0-100%
            final style = TextStyle(
              color: widget.secondaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: (MediaQuery.of(context).size.width < 350 ? 8 : 10),
            );
            return Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text('${value.toInt()}%', style: style, textAlign: TextAlign.right),
            );
          },
        ),
      ),
    ),
    borderData: FlBorderData( /* ... (tetap sama) ... */ ),
    barGroups: _isChartLoading || _isTargetLoading ? [] : _barGroups, // Gunakan _barGroups dari state
    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20), // Grid horizontal per 20%
    groupsSpace: groupSpace,
    maxY: _maxYValue, // Gunakan _maxYValue dari state (misal, 110)
  );
}

  List<BarChartGroupData> showingGroups(double barWidth) {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return _getWeeklyData(barWidth);
      case StatisticPeriod.monthly:
        return _getMonthlyData(barWidth);
      case StatisticPeriod.yearly:
        return _getYearlyData(barWidth);
    }
  }

  List<BarChartGroupData> _getWeeklyData(double barWidth) {
    // Simulasi data mingguan (7 hari)
    final List<double> dailyHydration = [1200, 1850, 1500, 2100, 1650, 1400, 900];
    return List.generate(7, (i) {
      return makeGroupData(
        i,
        dailyHydration[i],
        barWidth: barWidth,
        isTouched: i == touchedIndex,
      );
    });
  }

  List<BarChartGroupData> _getMonthlyData(double barWidth) {
    // Simulasi data bulanan (4 minggu)
    final List<double> weeklyHydration = [12000, 14500, 13200, 11800];
    return List.generate(4, (i) {
      return makeGroupData(
        i,
        weeklyHydration[i],
        barWidth: barWidth,
        isTouched: i == touchedIndex,
      );
    });
  }

  List<BarChartGroupData> _getYearlyData(double barWidth) {
    // Simulasi data tahunan (12 bulan)
    final List<double> monthlyHydration = [
      45000, 42000, 48000, 50000, 52000, 55000,
      58000, 56000, 53000, 49000, 46000, 44000
    ];
    return List.generate(12, (i) {
      return makeGroupData(
        i,
        monthlyHydration[i],
        barWidth: barWidth,
        isTouched: i == touchedIndex,
      );
    });
  }

  BarChartGroupData makeGroupData(
    int x, 
    double y, 
    {bool isTouched = false, required double barWidth}
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + (y * 0.05) : y, // 5% increase when touched
          color: isTouched ? widget.accentColor.withOpacity(0.85) : widget.accentColor,
          gradient: LinearGradient(
            colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: barWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: false,
          ),
        ),
      ],
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    final screenWidth = MediaQuery.of(context).size.width; // Dapatkan screenWidth
    final style = TextStyle(
      color: Colors.grey, 
      fontWeight: FontWeight.bold, 
      fontSize: (screenWidth < 350 ? 9.0 : 10.0) // Sesuaikan font
    );
    
    String textToDisplay = '';
    int index = value.toInt();

    if (index >= 0 && index < _axisLabels.length) {
      textToDisplay = _axisLabels[index];
    }
    
    return SideTitleWidget(
      meta: meta,  // <-- KEMBALIKAN KE MENGGUNAKAN PARAMETER 'meta'
      space: 8,
      child: Text(
        textToDisplay,
        style: style
      ),
    );
  }
}