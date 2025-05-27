import 'package:flutter/material.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/cadangan.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/hydrasi_report.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/statistic.dart';


class StatisticPageScreen extends StatefulWidget {
  const StatisticPageScreen({super.key});

  @override
  State<StatisticPageScreen> createState() => StatisticPageScreenState();
}


class StatisticPageScreenState extends State<StatisticPageScreen> {

  void refresh() {
    print("Refreshing StatisticPageScreen");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Jumlah tab
      child: Scaffold(
        backgroundColor: Color(0xFFE8F7FF),
        appBar: AppBar(
          title: const Text(
            'Riwayat Hidrasi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF00A6FB),
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
        ),
        body: TabBarView(
          children: [
            // Tab 1: Grafik
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    HydrationStatsChart(
                      accentColor: Color(0xFF00A6FB),
                      cardColor: Theme.of(context).cardColor,
                      primaryTextColor:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black,
                      secondaryTextColor:
                          Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.grey,
                    ),
                    SizedBox(height: 16),
                    // Add the new gamification widget here
                    HydrasiReport(
                      weeklyAverage: 1660,
                      monthlyAverage: 1720,
                      completionPercentage: 78,
                      drinkFrequency: 6,
                      accentColor: Color(0xFF00A6FB),
                    ),
                  ],
                ),
              ),
            ),

            // Tab 2: Riwayat Harian
            Padding(padding: EdgeInsets.all(8), child: Cadangan()),
          ],
        ),
      ),
    );
  }
}