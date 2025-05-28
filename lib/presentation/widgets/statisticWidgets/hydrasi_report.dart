import 'package:flutter/material.dart';
import 'dart:math' as math; // Digunakan untuk fungsi math.min dan math.max

class HydrasiReport extends StatefulWidget {
  final double weeklyAverage;
  final double monthlyAverage;
  final int drinkFrequency;
  final Color accentColor;
  final double currentDailyIntake; // Asupan hidrasi hari ini
  final double averageDailyTarget; // Rata-rata target harian pengguna

  const HydrasiReport({
    Key? key,
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.drinkFrequency,
    required this.currentDailyIntake,
    required this.averageDailyTarget,
    this.accentColor = const Color(0xFF00A6FB),
  }) : super(key: key);

  @override
  State<HydrasiReport> createState() => _HydrasiReportState();
}

class _HydrasiReportState extends State<HydrasiReport> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStatsGrid(context),
            const SizedBox(height: 16),
            _buildProgressIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Laporan Minum Air',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final double completionRate = widget.averageDailyTarget > 0
        ? (widget.currentDailyIntake / widget.averageDailyTarget * 100)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth > 320;

        if (useGrid) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Rata-rata Mingguan', '${widget.weeklyAverage.toStringAsFixed(0)} ml/hari', Icons.calendar_view_week)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, 'Rata-rata Bulanan', '${widget.monthlyAverage.toStringAsFixed(0)} ml/hari', Icons.calendar_month)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Rata2 Penyelesaian', '${completionRate.toStringAsFixed(1)}%', Icons.check_circle_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, 'Frekuensi Minum', '${widget.drinkFrequency} kali/hari', Icons.local_drink)),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatCard(context, 'Rata-rata Mingguan', '${widget.weeklyAverage.toStringAsFixed(0)} ml/hari', Icons.calendar_view_week),
              const SizedBox(height: 10),
              _buildStatCard(context, 'Rata-rata Bulanan', '${widget.monthlyAverage.toStringAsFixed(0)} ml/hari', Icons.calendar_month),
              const SizedBox(height: 10),
              _buildStatCard(context, 'Rata2 Penyelesaian', '${completionRate.toStringAsFixed(1)}%', Icons.check_circle_outline),
              const SizedBox(height: 10),
              _buildStatCard(context, 'Frekuensi Minum', '${widget.drinkFrequency} kali/hari', Icons.local_drink),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final double percentage = widget.averageDailyTarget > 0
        ? (widget.currentDailyIntake / widget.averageDailyTarget)
        : 0.0;
    final double clampedPercentage = math.max(0.0, math.min(1.0, percentage));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rata Rata Hidrasi Harian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final progressWidth = availableWidth * clampedPercentage;

            return Stack(
              children: [
                Container(
                  height: 14,
                  width: availableWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 14,
                  width: progressWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            );
          }
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.currentDailyIntake.round()} ml',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
              ),
            ),
            Text(
              '${widget.averageDailyTarget.round()} ml',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}