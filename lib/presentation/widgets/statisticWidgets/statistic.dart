import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  bool isWeeklyView = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal chart height based on available width
        final availableWidth = constraints.maxWidth;
        final optimalHeight = _calculateOptimalHeight(availableWidth);
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildChartCard(context, optimalHeight, availableWidth),
          ],
        );
      }
    );
  }

  // Calculate optimal height based on screen width
  double _calculateOptimalHeight(double width) {
    if (width < 300) {
      return 280; // Very small screens
    } else if (width < 400) {
      return 320; // Small screens
    } else {
      return 350; // Normal and large screens
    }
  }

  Widget _buildChartCard(BuildContext context, double height, double width) {
    // Adjust padding based on available width
    final horizontalPadding = width < 350 ? 8.0 : 16.0;
    final titlePadding = width < 350 ? 12.0 : 20.0;
    final chartPadding = width < 350 ? 8.0 : 16.0;
    
    // Calculate chart height based on container height
    final chartHeight = height * 0.45;
    
    // Adjust bar width and spacing based on available width
    // Make bars narrower as we now have 7 days instead of 5
    final barWidth = width < 300 ? 8.0 : (width < 400 ? 10.0 : 12.0);
    final groupSpace = width < 300 ? 8.0 : (width < 400 ? 12.0 : 14.0);
    
    // Adjust font sizes based on available width
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
              Padding(
                padding: EdgeInsets.fromLTRB(titlePadding, 16, titlePadding, 0),
                child: Text(
                  isWeeklyView ? 'Hidrasi Mingguan' : 'Hidrasi Hari Ini',
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
                  'Jumlah konsumsi air dalam mililiter (ml)',
                  style: TextStyle(
                    color: widget.secondaryTextColor,
                    fontSize: subtitleFontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
            String day;
            switch (group.x) {
              case 0:
                day = 'Senin';
                break;
              case 1:
                day = 'Selasa';
                break;
              case 2:
                day = 'Rabu';
                break;
              case 3:
                day = 'Kamis';
                break;
              case 4:
                day = 'Jumat';
                break;
              case 5:
                day = 'Sabtu';
                break;
              case 6:
                day = 'Minggu';
                break;
              default:
                day = '';
            }
            return BarTooltipItem(
              '$day\n',
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
            reservedSize: 24, // Reduced from 30
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
      maxY: 2500,
    );
  }

  List<BarChartGroupData> showingGroups(double barWidth) => List.generate(7, (i) {
        final List<double> dailyHydration = [1200, 1850, 1500, 2100, 1650, 1400, 900];
        return makeGroupData(
          i,
          dailyHydration[i],
          barWidth: barWidth,
          isTouched: i == touchedIndex,
        );
      });

  BarChartGroupData makeGroupData(
    int x, 
    double y, 
    {bool isTouched = false, required double barWidth}
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 100 : y,
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
    final labels = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
    return SideTitleWidget(
      meta: meta,
      space: 8, // Reduced from 12
      child: Text(value.toInt() < labels.length ? labels[value.toInt()] : '', style: style),
    );
  }
}