import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 Tambahkan import Provider
import 'package:hydrate/presentation/widgets/statisticWidgets/history_hydration.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/report_hydration.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/statistic.dart'; // Asumsi ini adalah HydrationStatsChart
import 'package:hydrate/presentation/controllers/hydration_stats_controller.dart'; // 👈 Import controller
import 'package:hydrate/core/utils/session_manager.dart'; // 👈 Import SessionManager

class StatisticPageScreen extends StatefulWidget {
  const StatisticPageScreen({super.key});

  @override
  State<StatisticPageScreen> createState() => StatisticPageScreenState();
}

class StatisticPageScreenState extends State<StatisticPageScreen> {
  // int? _currentUserId; // 👈 Pindahkan _currentUserId dan logikanya jika perlu

  @override
  void initState() {
    super.initState();
    // Memuat data statistik saat widget diinisialisasi
    // Pastikan HydrationStatsController sudah tersedia di context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Panggil fetchHydrationStats dari controller.
      // ID pengguna akan diambil di dalam controller menggunakan SessionManager.
      Provider.of<HydrationStatsController>(context, listen: false)
          .fetchHydrationStats();
    });
  }

  void refresh() {
    print("Refreshing StatisticPageScreen");
    // Panggil fetchHydrationStats untuk memuat ulang data.
    Provider.of<HydrationStatsController>(context, listen: false)
        .fetchHydrationStats();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Jumlah tab
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F7FF),
        appBar: AppBar(
          title: const Text(
            'Riwayat Hidrasi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF00A6FB),
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Laporan Hidrasi'),
              Tab(text: 'Riwayat Harian'),
            ],
          ),
          // Tambahkan tombol refresh jika diinginkan
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: refresh,
              tooltip: 'Segarkan Data',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Laporan Hidrasi (Grafik dan HydrasiReport)
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Widget grafik Anda
                    HydrationStatsChart( // Nama widget ini mungkin 'Statistic' sesuai import Anda
                      accentColor: const Color(0xFF00A6FB),
                      cardColor: Theme.of(context).cardColor,
                      primaryTextColor:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black,
                      secondaryTextColor:
                          Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    // Menggunakan Consumer untuk mendengarkan perubahan dari HydrationStatsController
                    Consumer<HydrationStatsController>(
                      builder: (context, controller, child) {
                        if (controller.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (controller.errorMessage != null) {
                          return Center(child: Text('Error: ${controller.errorMessage}'));
                        }
                        // Ambil data dari controller
                        final stats = controller.stats;
                        return HydrasiReport(
                          weeklyAverage: stats.weeklyAverageIntake,
                          monthlyAverage: stats.monthlyAverageIntake,
                          drinkFrequency: stats.averageDailyDrinkFrequency,
                          currentDailyIntake: stats.todayIntake, // 👈 Parameter baru
                          averageDailyTarget: stats.averageDailyTarget, // 👈 Parameter baru
                          accentColor: const Color(0xFF00A6FB),
                          // completionPercentage: 78, // 👈 Hapus parameter lama ini
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Tab 2: Riwayat Harian
            // Anda mungkin ingin menggunakan RiwayatHidrasiController di sini
            // untuk menampilkan daftar riwayat harian yang dinamis.
            Padding(padding: const EdgeInsets.all(8), child: Cadangan()), // Widget 'Cadangan' Anda
          ],
        ),
      ),
    );
  }
}