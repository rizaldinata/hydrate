import 'package:flutter/material.dart';

class HydrasiReport extends StatefulWidget {
  final double weeklyAverage;
  final double monthlyAverage;
  final double completionPercentage;
  final int drinkFrequency;
  final Color accentColor;

  const HydrasiReport({
    Key? key,
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.completionPercentage,
    required this.drinkFrequency,
    this.accentColor = const Color(0xFF00A6FB),
  }) : super(key: key);

  @override
  State<HydrasiReport> createState() => _HydrasiReportState();
}

class _HydrasiReportState extends State<HydrasiReport> {
  @override
  Widget build(BuildContext context) {
    // Calculate available width accounting for the 44px overflow issue
    final screenWidth = MediaQuery.of(context).size.width;
    final safeWidth = screenWidth - 44; // Accounting for the overflow

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: safeWidth,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStatsGrid(context),
            const SizedBox(height: 16),
            _buildProgressIndicator(context, safeWidth),
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
              'Laporan minum air',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //   decoration: BoxDecoration(
        //     color: widget.accentColor.withOpacity(0.1),
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(
        //         Icons.local_fire_department,
        //         color: widget.accentColor,
        //         size: 16,
        //       ),
        //       const SizedBox(width: 2),
        //       Text(
        //         '3 Hari Beruntun!',
        //         style: TextStyle(
        //           color: widget.accentColor,
        //           fontWeight: FontWeight.bold,
        //           fontSize: 11,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive layout based on available width
        final useGrid = constraints.maxWidth > 300;
        
        if (useGrid) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Rata-rata Mingguan', '${widget.weeklyAverage} ml/hari', Icons.calendar_view_week)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(context, 'Rata-rata Bulanan', '${widget.monthlyAverage} ml/hari  ', Icons.calendar_month)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Completion Rate', '${widget.completionPercentage}%', Icons.check_circle_outline)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(context, 'Drink Frequency', '${widget.drinkFrequency} times/day', Icons.local_drink)),
                ],
              ),
            ],
          );
        } else {
          // Stack vertically on smaller screens
          return Column(
            children: [
              _buildStatCard(context, 'Rata-rata Mingguan', '${widget.weeklyAverage} ml/hari', Icons.calendar_view_week),
              const SizedBox(height: 8),
              _buildStatCard(context, 'Rata-rata Bulanan', '${widget.monthlyAverage} ml/bulanan', Icons.calendar_month),
              const SizedBox(height: 8),
              _buildStatCard(context, 'Penyelesaian rata-rata', '${widget.completionPercentage}%', Icons.check_circle_outline),
              const SizedBox(height: 8),
              _buildStatCard(context, 'Frekuensi minum', '${widget.drinkFrequency} waktu/hari', Icons.local_drink),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: widget.accentColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, double safeWidth) {
    // Calculate the actual progress width to prevent overflow
    final availableWidth = safeWidth - 24; // Account for padding
    final progressWidth = availableWidth * (widget.completionPercentage / 100);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Harian',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 12,
              width: availableWidth,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              height: 12,
              width: progressWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(2500 * widget.completionPercentage / 100).round()} ml',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
              ),
            ),
            Text(
              '2500 ml',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}