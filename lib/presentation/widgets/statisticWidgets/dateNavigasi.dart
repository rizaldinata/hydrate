import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateNavigation extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSelectDate;
  final Color primaryColor;
  final Color surfaceColor;

  const DateNavigation({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onSelectDate,
    required this.primaryColor,
    required this.surfaceColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String dateTitle =
        isToday ? "Hari Ini" : DateFormat('dd MMMM yyyy').format(selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day Button
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: primaryColor,
              size: 32,
            ),
            onPressed: () {
              onDateChanged(selectedDate.subtract(const Duration(days: 1)));
            },
          ),

          // Date Display with Gesture
          GestureDetector(
            onTap: onSelectDate,
            child: Text(
              dateTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Next Day Button
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isToday ? Colors.grey.shade400 : primaryColor,
              size: 32,
            ),
            onPressed: isToday
                ? null
                : () {
                    onDateChanged(selectedDate.add(const Duration(days: 1)));
                  },
          ),
        ],
      ),
    );
  }
}