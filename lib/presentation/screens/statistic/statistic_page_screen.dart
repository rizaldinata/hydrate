import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/history_hydration.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/report_hydration.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/statistic.dart'; 
import 'package:hydrate/presentation/controllers/hydration_stats_controller.dart'; 

class StatisticPageScreen extends StatefulWidget {
  const StatisticPageScreen({super.key});

  @override
  State<StatisticPageScreen> createState() => StatisticPageScreenState();
}

class StatisticPageScreenState extends State<StatisticPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HydrationStatsController>(context, listen: false)
          .fetchHydrationStats();
    });
  }

  void refresh() {
    Provider.of<HydrationStatsController>(context, listen: false)
        .fetchHydrationStats();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    HydrationStatsChart(
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
                    Consumer<HydrationStatsController>(
                      builder: (context, controller, child) {
                        if (controller.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (controller.errorMessage != null) {
                          return Center(child: Text('Error: ${controller.errorMessage}'));
                        }
                        final stats = controller.stats;
                        return HydrasiReport(
                          weeklyAverage: stats.weeklyAverageIntake,
                          monthlyAverage: stats.monthlyAverageIntake,
                          drinkFrequency: stats.averageDailyDrinkFrequency,
                          currentDailyIntake: stats.todayIntake, // ✅ Parameter yang sudah ada
                          averageDailyTarget: stats.averageDailyTarget, // ✅ Parameter yang sudah ada  
                          averageCompletionRate: stats.averageCompletionRate, // ✅ Parameter baru yang ditambahkan
                          accentColor: const Color(0xFF00A6FB),
                          // completionPercentage: 78, // ❌ Hapus parameter lama ini
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Padding(padding: const EdgeInsets.all(8), child: Cadangan()),
          ],
        ),
      ),
    );
  }
}