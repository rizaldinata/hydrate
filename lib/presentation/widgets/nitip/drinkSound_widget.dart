import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class DrinkSound extends StatefulWidget {
  const DrinkSound();

  @override
  State<DrinkSound> createState() => DrinkSoundState();
}

class DrinkSoundState extends State<DrinkSound> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playDrinkingSound();
  }

  Future<void> _playDrinkingSound() async {
    try {
      print("Attempting to play drinking sound...");
      await _audioPlayer.stop();
      print("AudioPlayer stopped successfully");

      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
      print("Sound playing started successfully");
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }
}
