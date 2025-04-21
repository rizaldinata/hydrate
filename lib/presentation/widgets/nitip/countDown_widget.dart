import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Countdown extends StatefulWidget {
  const Countdown();

  @override
  State<Countdown> createState() => CountdownState();
}

class CountdownState extends State<Countdown> {
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  static const int _countdownDurationInSeconds = 3600; // 1 jam
  static const String _endTimeKey = 'countdown_end_time';
  

  @override
  void initState() {
    super.initState();
  }

  void startCountdown() {
    
    _countdownTimer?.cancel();
    setState(() {
      _remainingTime = const Duration(seconds: _countdownDurationInSeconds);
    });

    // Save absolute end time
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimeMillis = now + _remainingTime.inMilliseconds;

    // Save immediately to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_endTimeKey, endTimeMillis);
      // print(
      //     "Timer end time saved: ${DateTime.fromMillisecondsSinceEpoch(endTimeMillis)}");
    });

    // Start the counter
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > Duration.zero) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }
}
