import 'package:flutter/material.dart';

class WaterProgressIndicator extends StatelessWidget {
  final ValueNotifier<double> notifier;

  const WaterProgressIndicator({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (_, double value, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${value.toInt()}%', // Persentase hidrasi
              style: const TextStyle(
                color: Color(0xFF2F2E41),
                fontWeight: FontWeight.w300,
                fontSize: 60,
              ),
            ),
          ],
        );
      },
    );
  }
}
