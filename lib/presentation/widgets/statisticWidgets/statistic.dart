import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum StatisticPeriod { weekly, monthly, yearly }

class HydrationStatsChart extends StatefulWidget {
  final Color accentColor;
  final Color? cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const HydrationStatsChart({
    Key? key,
    this.accentColor = Colors.blue,
    this.cardColor,
    this.primaryTextColor = Colors.black,
    this.secondaryTextColor = Colors.grey,
  }) : super(key: key);

  @override
  State<HydrationStatsChart> createState() => _HydrationStatsChartState();
}

class _HydrationStatsChartState extends State<HydrationStatsChart> {
  int touchedIndex = -1;
  StatisticPeriod currentPeriod = StatisticPeriod.weekly;
  int currentIndex = 0; // Index untuk navigasi (minggu ke-, bulan ke-, tahun ke-)

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
          currentIndex = 0; // Reset index saat ganti periode
          touchedIndex = -1; // Reset touched index
        });
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

  // Calculate optimal height based on screen width
  double _calculateOptimalHeight(double width) {
    if (width < 300) {
      return 320; // Very small screens - increased for navigation
    } else if (width < 400) {
      return 360; // Small screens - increased for navigation
    } else {
      return 390; // Normal and large screens - increased for navigation
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
                    mainBarData(barWidth, groupSpace),
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
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          tooltipBorder: BorderSide(color: Colors.transparent),
          tooltipMargin: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String label = _getTooltipLabel(group.x);
            return BarTooltipItem(
              '$label\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '${(rod.toY).round()} ml',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 24,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          left: BorderSide(color: Colors.transparent),
        ),
      ),
      barGroups: showingGroups(barWidth),
      gridData: FlGridData(
        show: false,
      ),
      groupsSpace: groupSpace,
      maxY: _getMaxY(),
    );
  }

  String _getTooltipLabel(int index) {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        return index < days.length ? days[index] : '';
      case StatisticPeriod.monthly:
        return 'Minggu ${index + 1}';
      case StatisticPeriod.yearly:
        return _getMonthName(index + 1);
    }
  }

  double _getMaxY() {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return 2500;
      case StatisticPeriod.monthly:
        return 15000; // Total per minggu bisa lebih tinggi
      case StatisticPeriod.yearly:
        return 60000; // Total per bulan
    }
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
    final style = TextStyle(
      color: Colors.grey, 
      fontWeight: FontWeight.bold, 
      fontSize: 10
    );
    
    List<String> labels = _getAxisLabels();
    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        value.toInt() < labels.length ? labels[value.toInt()] : '', 
        style: style
      ),
    );
  }

  List<String> _getAxisLabels() {
    switch (currentPeriod) {
      case StatisticPeriod.weekly:
        return ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
      case StatisticPeriod.monthly:
        return ['W1', 'W2', 'W3', 'W4'];
      case StatisticPeriod.yearly:
        return ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 
                'JUL', 'AGS', 'SEP', 'OKT', 'NOV', 'DES'];
    }
  }
}