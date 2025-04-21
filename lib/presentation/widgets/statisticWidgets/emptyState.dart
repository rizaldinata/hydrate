import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class EmptyState extends StatelessWidget {
  final DateTime selectedDate;
  final Color primaryColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const EmptyState({
    Key? key,
    required this.selectedDate,
    required this.primaryColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset('assets/loading.json', width: 200, height: 200),
          ),
          const SizedBox(height: 24),
          Text(
            isToday ? "Ayo Minum Air!" : "Tidak Ada Riwayat",
            style: TextStyle(
              fontSize: 20,
              color: textPrimaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isToday
                ? "Yuk catat konsumsi air mineralmu hari ini"
                : "Tidak ada data hidrasi untuk tanggal ini",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}