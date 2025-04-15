import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

  Future<void> _playDrinkingSound() async {
    late AudioPlayer _audioPlayer;

    try {
      print("Attempting to play drinking sound...");
      // Reset the player to ensure it can play again
      await _audioPlayer.stop();
      print("AudioPlayer stopped successfully");

      // Play the sound
      await _audioPlayer.play(AssetSource('sounds/drinking_water.mp3'));
      print("Sound playing started successfully");
    } catch (e) {
      print("Error playing sound: $e");
      // Add more detailed error info
      print("Error details: ${e.toString()}");
    }
  }

class AddWaterModal {
  int selectedWater = 150;
  int? idPengguna;

  void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempSelectedWater = selectedWater;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 420,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Pilih Ukuran Air",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: Colors.blue, thickness: 1, height: 20),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(
                            initialItem: (selectedWater ~/ 50) - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              tempSelectedWater = (index + 1) * 50;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 20,
                            builder: (context, index) {
                              int waterValue = (index + 1) * 50;
                              return Center(
                                child: Text(
                                  "$waterValue",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: tempSelectedWater == waterValue
                                        ? const Color(0xFF00A6FB)
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width - 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A6FB).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SvgPicture.asset(
                              'assets/images/glass2.svg',
                              width: 32,
                              height: 32,
                            ),
                            const Text(
                              "mL",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2E41),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (idPengguna == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User tidak teridentifikasi!"),
                            ),
                          );
                          return;
                        }

                        _playDrinkingSound();

                        setState(() {
                          selectedWater = tempSelectedWater;
                        });

                        try {
                          await _riwayatHidrasiController.tambahRiwayatHidrasi(
                            fkIdPengguna: idPengguna!,
                            jumlahHidrasi: selectedWater.toDouble(),
                          );

                          double newTotalIntake = currentIntake + selectedWater;
                          await _targetHidrasiRepository.updateTotalHidrasi(
                              idPengguna!, todayDate, newTotalIntake);

                          final targetHarian = await _targetHidrasiRepository
                              .getTargetHidrasiHarian(idPengguna!, todayDate);

                          if (targetHarian != null) {
                            double persentase =
                                targetHarian['persentase_hidrasi'] ?? 0.0;
                            setState(() {
                              currentIntake = newTotalIntake;
                              _valueNotifier.value = persentase;
                            });
                          } else {
                            setState(() {
                              currentIntake = newTotalIntake;
                              _valueNotifier.value =
                                  min(100, (currentIntake / target) * 100);
                            });
                          }
                        } catch (e) {
                          print("Error saat menambah air: $e");
                          setState(() {
                            currentIntake += selectedWater;
                            _valueNotifier.value =
                                min(100, (currentIntake / target) * 100);
                          });
                        }

                        _startCountdown();
                        _showAddedWaterPopup(context, selectedWater.toDouble());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Pilih",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
