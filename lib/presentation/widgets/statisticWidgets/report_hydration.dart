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
    super.key,
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.drinkFrequency,
    required this.currentDailyIntake,
    required this.averageDailyTarget,
    this.accentColor = const Color(0xFF00A6FB), // Warna aksen default
  });

  @override
  State<HydrasiReport> createState() => _HydrasiReportState();
}

class _HydrasiReportState extends State<HydrasiReport> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // Margin diatur agar Card bisa full-width jika parent mengizinkan
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Membuat Column sependek mungkin
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStatsColumn(context), // Mengganti _buildStatsGrid dengan _buildStatsColumn
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
        Expanded( // Menggunakan Expanded agar Center bekerja dengan baik di dalam Row
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

  // Mengubah _buildStatsGrid menjadi _buildStatsColumn untuk layout vertikal
  Widget _buildStatsColumn(BuildContext context) {
    final double completionRate = widget.averageDailyTarget > 0
        ? (widget.currentDailyIntake / widget.averageDailyTarget * 100)
        : 0.0;

    // Jarak antar kartu statistik
    const double cardSpacing = 10.0;

    return Column(
      children: [
        _buildStatCard(context, 'Rata-rata Mingguan', '${widget.weeklyAverage.toStringAsFixed(0)} ml/hari', Icons.calendar_view_week),
        const SizedBox(height: cardSpacing),
        _buildStatCard(context, 'Rata-rata Bulanan', '${widget.monthlyAverage.toStringAsFixed(0)} ml/hari', Icons.calendar_month),
        const SizedBox(height: cardSpacing),
        _buildStatCard(context, 'Rata2 Penyelesaian', '${completionRate.toStringAsFixed(1)}%', Icons.check_circle_outline),
        const SizedBox(height: cardSpacing),
        _buildStatCard(context, 'Frekuensi Minum', '${widget.drinkFrequency} kali/hari', Icons.local_drink),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      width: double.infinity, // Membuat kartu mengambil lebar penuh yang tersedia
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9), // Sedikit transparansi untuk kedalaman
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)), // Border halus
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1), // Bayangan halus
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten jika kartu memiliki tinggi tetap (tidak dalam kasus ini)
        children: [
          Row(
            children: [
              Icon(icon, color: widget.accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded( // Penting untuk teks judul yang panjang agar responsif
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis, // Atasi teks yang terlalu panjang
                  maxLines: 1, // Batasi judul menjadi satu baris jika sangat panjang
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
            overflow: TextOverflow.ellipsis, // Atasi nilai yang terlalu panjang
            maxLines: 1, // Batasi nilai menjadi satu baris
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final double percentage = widget.averageDailyTarget > 0
        ? (widget.currentDailyIntake / widget.averageDailyTarget)
        : 0.0;
    // Pastikan persentase antara 0.0 dan 1.0
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
        LayoutBuilder( // Menggunakan LayoutBuilder agar progress bar responsif
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final progressWidth = availableWidth * clampedPercentage;

            return Stack(
              children: [
                Container(
                  height: 14, // Tinggi progress bar
                  width: availableWidth, // Lebar penuh background progress bar
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3), // Warna background
                    borderRadius: BorderRadius.circular(7), // Rounded corners
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500), // Durasi animasi
                  curve: Curves.easeInOut, // Kurva animasi
                  height: 14,
                  width: progressWidth, // Lebar progress yang terisi
                  decoration: BoxDecoration(
                    gradient: LinearGradient( // Menggunakan gradient untuk tampilan yang lebih menarik
                      colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.7)],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Teks rata kiri dan kanan
          children: [
            Text(
              '${widget.currentDailyIntake.round()} ml',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.accentColor, // Warna sesuai aksen
              ),
            ),
            Text(
              '${widget.averageDailyTarget.round()} ml',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color, // Warna standar untuk target
              ),
            ),
          ],
        ),
      ],
    );
  }
}