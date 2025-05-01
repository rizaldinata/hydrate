import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/presentation/screens/home_screen1.dart';
import 'package:hydrate/presentation/widgets/nitip/countDown_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/drinkSound_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/popupAddWater_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddWaterModal extends StatefulWidget {
  const AddWaterModal({super.key});

  @override
  State<AddWaterModal> createState() => _AddWaterModalState();
}

class _AddWaterModalState extends State<AddWaterModal> {
  int selectedWater = 150;
  int? idPengguna;
  double target = 0;
  double currentIntake = 0;
  final RiwayatHidrasiController _riwayatHidrasiController =
      RiwayatHidrasiController();
  final TargetHidrasiRepository _targetHidrasiRepository =
      TargetHidrasiRepository();
  final ValueNotifier<double> _valueNotifier = ValueNotifier<double>(0);
  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7)));

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  
void _loadUserId() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    idPengguna = prefs.getInt('id_pengguna'); // Pastikan key-nya sesuai
  });
}

// Show the modal bottom sheet for custom water intake selection
  void showAddWaterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempSelectedWater = selectedWater;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 420,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Pilih Ukuran Air",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(
                    color: Colors.blue,
                    thickness: 1,
                    height: 20,
                  ),
                  SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.5,
                          physics: FixedExtentScrollPhysics(),
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
                        // biar transparan untuk gesture
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
                        // biar transparan juga
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SvgPicture.asset(
                              'assets/images/glass2.svg',
                              width: 32,
                              height: 32,
                            ),
                            Text(
                              "mL",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2F2E41),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
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
                        // Play drinking sound effect
                        DrinkSound();

                        setState(() {
                          selectedWater = tempSelectedWater;
                        });

                        try {
                          // Simpan riwayat hidrasi
                          await _riwayatHidrasiController.tambahRiwayatHidrasi(
                            fkIdPengguna: idPengguna!,
                            jumlahHidrasi: selectedWater.toDouble(),
                          );

                          // Perbarui total hidrasi di tabel target_hidrasi
                          double newTotalIntake = currentIntake + selectedWater;
                          await _targetHidrasiRepository.updateTotalHidrasi(
                              idPengguna!, todayDate, newTotalIntake);

                          // Dapatkan persentase terbaru dari database
                          final targetHarian = await _targetHidrasiRepository
                              .getTargetHidrasiHarian(idPengguna!, todayDate);

                          if (targetHarian != null) {
                            // Gunakan persentase yang disimpan di database
                            double persentase =
                                targetHarian['persentase_hidrasi'] ?? 0.0;
                            setState(() {
                              currentIntake = newTotalIntake;
                              _valueNotifier.value = persentase;
                            });
                            print(
                                "Modal: Persentase hidrasi diperbarui dari database: $persentase%");
                          } else {
                            setState(() {
                              currentIntake = newTotalIntake;
                              _valueNotifier.value =
                                  min(100, (currentIntake / target) * 100);
                            });
                          }
                        } catch (e) {
                          print("Error saat menambah air: $e");
                          // Fallback jika gagal mengakses database
                          setState(() {
                            currentIntake += selectedWater;
                            _valueNotifier.value =
                                min(100, (currentIntake / target) * 100);
                          });
                        }

                        Countdown();
                        Popupaddwater();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreens()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
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

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Widget ini tidak menampilkan apa-apa
  }

  // Update fungsi _loadTodayIntake() untuk menggunakan persentase dari database
  // Future<void> _loadTodayIntake() async {
  //   if (idPengguna == null) return;
  //   try {
  //     final targetHarian = await _targetHidrasiRepository
  //         .getTargetHidrasiHarian(idPengguna!, todayDate);
  //     if (targetHarian != null) {
  //       double targetHidrasi = targetHarian['target_hidrasi'] ?? 0.0;
  //       double totalHidrasi = targetHarian['total_hidrasi_harian'] ?? 0.0;
  //       double persentaseHidrasi = targetHarian['persentase_hidrasi'] ?? 0.0;
  //       setState(() {
  //         target = targetHidrasi;
  //         currentIntake = totalHidrasi;
  //         _valueNotifier.value = persentaseHidrasi;
  //       });
  //       print(
  //           "Data hidrasi dimuat: $totalHidrasi mL dari target $targetHidrasi mL (${persentaseHidrasi.toStringAsFixed(1)}%)");
  //       if (totalHidrasi > 0 && _remainingTime.inSeconds <= 0) {
  //         Countdown();
  //       }
  //     } else {
  //       Popupaddwater();
  //       final riwayatHariIni = await _riwayatHidrasiController
  //           .getRiwayatHidrasiHariIni(idPengguna!);
  //       double totalIntake = 0;
  //       for (var riwayat in riwayatHariIni) {
  //         totalIntake += riwayat.jumlahHidrasi;
  //       }
  //       if (totalIntake > 0) {
  //         await _targetHidrasiRepository.updateTotalHidrasi(
  //             idPengguna!, todayDate, totalIntake);
  //         final updatedTarget = await _targetHidrasiRepository
  //             .getTargetHidrasiHarian(idPengguna!, todayDate);
  //         if (updatedTarget != null) {
  //           setState(() {
  //             currentIntake = totalIntake;
  //             _valueNotifier.value = updatedTarget['persentase_hidrasi'] ?? 0.0;
  //           });
  //         } else {
  //           setState(() {
  //             currentIntake = totalIntake;
  //             _valueNotifier.value = min(100, (currentIntake / target) * 100);
  //           });
  //         }
  //         if (_remainingTime.inSeconds <= 0) {
  //           Countdown();
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print("Error saat memuat intake hari ini: $e");
  //     try {
  //       await _hydrationCalculator.initializeData(idPengguna!);
  //       final targetHidrasi =
  //           _hydrationCalculator.calculateDailyWaterIntake() * 1000;
  //       setState(() {
  //         target = targetHidrasi;
  //         _valueNotifier.value = min(100, (currentIntake / target) * 100);
  //       });
  //       print("Menggunakan target hidrasi fallback: $targetHidrasi mL");
  //     } catch (e2) {
  //       print("Error saat menghitung target hidrasi (fallback): $e2");
  //     }
  //   }
  // }

  // Modify _animateGlass method to play sound
  // void _animateGlass(BuildContext context, double amount) async {
  //   if (idPengguna == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("User tidak teridentifikasi!")));
  //     return;
  //   }
  //   // Play drinking sound effect
  //   DrinkSound();
  //   try {
  //     await _riwayatHidrasiController.tambahRiwayatHidrasi(
  //       fkIdPengguna: idPengguna!,
  //       jumlahHidrasi: amount,
  //     );
  //     double newTotalIntake = currentIntake + amount;
  //     await _targetHidrasiRepository.updateTotalHidrasi(
  //         idPengguna!, todayDate, newTotalIntake);
  //     final targetHarian = await _targetHidrasiRepository
  //         .getTargetHidrasiHarian(idPengguna!, todayDate);
  //     if (targetHarian != null) {
  //       double persentase = targetHarian['persentase_hidrasi'] ?? 0.0;
  //       setState(() {
  //         currentIntake = newTotalIntake;
  //         _valueNotifier.value = persentase;
  //       });
  //       print("Persentase hidrasi diperbarui dari database: $persentase%");
  //     } else {
  //       setState(() {
  //         currentIntake = newTotalIntake;
  //         _valueNotifier.value = min(100, (currentIntake / target) * 100);
  //       });
  //     }
  //     // Notifikasi halaman lain tentang perubahan data hidrasi
  //     _eventBus.fire('refresh_statistics');
  //   } catch (e) {
  //     print("Gagal menyimpan riwayat: $e");
  //     setState(() {
  //       currentIntake += amount;
  //       _valueNotifier.value = min(100, (currentIntake / target) * 100);
  //     });
  //   }
  //   GlassAnimation();
  //   Countdown();
  //   Popupaddwater();
  // }

  // Update fungsi _checkAndCreateTodayTarget() untuk menggunakan nilai target dari calculator
  // Future<void> _checkAndCreateTodayTarget() async {
  //   if (idPengguna == null) return;
  //   try {
  //     final targetExists = await _targetHidrasiRepository
  //         .checkTargetHidrasiExists(idPengguna!, todayDate);
  //     if (!targetExists) {
  //       if (target <= 0) {
  //         await _hydrationCalculator.initializeData(idPengguna!);
  //         target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
  //       }
  //       await _targetHidrasiRepository.createTargetHidrasi(
  //           idPengguna!, target, todayDate, 0.0);
  //       print(
  //           "Target hidrasi baru dibuat untuk tanggal $todayDate: $target mL");
  //     } else {
  //       await _targetHidrasiRepository.updateTargetHidrasiValue(
  //           idPengguna!, todayDate);
  //       print(
  //           "Target hidrasi untuk tanggal $todayDate sudah ada dan diperbarui");
  //       final updatedTarget = await _targetHidrasiRepository
  //           .getTargetHidrasiHarian(idPengguna!, todayDate);
  //       if (updatedTarget != null &&
  //           (updatedTarget['target_hidrasi'] ?? 0) > 0) {
  //         setState(() {
  //           target = updatedTarget['target_hidrasi'];
  //         });
  //         print("Target hidrasi diperbarui: $target mL");
  //       }
  //     }
  //   } catch (e) {
  //     print("Error saat memeriksa/membuat target hidrasi: $e");
  //     try {
  //       await _hydrationCalculator.initializeData(idPengguna!);
  //       target = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
  //       print("Target hidrasi (recovery): $target mL");
  //     } catch (e2) {
  //       print("Error saat menghitung target hidrasi (recovery): $e2");
  //     }
  //   }
  // }

  // Fungsi animasi gelas (dipisahkan dari fungsi utama agar tidak mengganggu setState)
  // void _animateGlassMovement(double amount) {
  //   setState(() {
  //     _glassOffsets[amount] = -10;
  //   });
  //   Future.delayed(const Duration(milliseconds: 1000), () {
  //     setState(() {
  //       _glassOffsets[amount] = 0;
  //     });
  //   });
  // }

  // Start countdown timer
  // void _startCountdown() {
  //   _countdownTimer?.cancel();
  //   setState(() {
  //     _remainingTime = const Duration(seconds: _countdownDurationInSeconds);
  //   });
  //   // Save absolute end time
  //   final now = DateTime.now().millisecondsSinceEpoch;
  //   final endTimeMillis = now + _remainingTime.inMilliseconds;
  //   // Save immediately to SharedPreferences
  //   SharedPreferences.getInstance().then((prefs) {
  //     prefs.setInt(_endTimeKey, endTimeMillis);
  //     // print(
  //     //     "Timer end time saved: ${DateTime.fromMillisecondsSinceEpoch(endTimeMillis)}");
  //   });
  //   // Start the counter
  //   _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     setState(() {
  //       if (_remainingTime > Duration.zero) {
  //         _remainingTime -= const Duration(seconds: 1);
  //       } else {
  //         timer.cancel();
  //       }
  //     });
  //   });
  // }

  

  // Show snack bar to indicate added water
  // void _showAddedWaterPopup(BuildContext context, double amount) {
  //   OverlayEntry overlayEntry;
  //   final overlay = Overlay.of(context);
  //   final animationController = AnimationController(
  //     vsync: Navigator.of(context),
  //     duration: const Duration(milliseconds: 500),
  //   );
  //   overlayEntry = OverlayEntry(
  //     builder: (context) {
  //       return Positioned(
  //         top: 50,
  //         left: 20,
  //         right: 20,
  //         child: SlideTransition(
  //           position: Tween<Offset>(
  //             begin: const Offset(0, -0.5),
  //             end: const Offset(0, 0),
  //           ).animate(CurvedAnimation(
  //             parent: animationController,
  //             curve: Curves.easeOut,
  //           )),
  //           child: AnimatedOpacity(
  //             opacity: 1.0,
  //             duration: const Duration(milliseconds: 300),
  //             child: Material(
  //               color: Colors.transparent,
  //               child: Center(
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width * 0.9,
  //                   height: 60,
  //                   padding: const EdgeInsets.symmetric(
  //                       vertical: 10, horizontal: 20),
  //                   decoration: BoxDecoration(
  //                     // color: const Color(0xFF69CE6C).withOpacity(0.9), // Warna hijau
  //                     color: Colors.white.withOpacity(0.90), // Warna hijau
  //                     borderRadius: BorderRadius.circular(
  //                         10), // Border radius agar rounded
  //                     boxShadow: [
  //                       BoxShadow(color: Colors.black26, blurRadius: 5),
  //                     ],
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       SvgPicture.asset(
  //                         'assets/images/berhasil.svg',
  //                         color: const Color(0xFF3EDAC0),
  //                         width: 24, // Ukuran ikon
  //                         height: 24,
  //                       ),
  //                       const SizedBox(width: 16), // Jarak antara ikon dan teks
  //                       const Text(
  //                         "Berhasil menambahkan air !",
  //                         style: TextStyle(
  //                             // color: Colors.white,
  //                             color: const Color(0xFF2F2E41),
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.bold),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  //   overlay.insert(overlayEntry);
  //   animationController.forward();
  //   // Hapus snackbar setelah beberapa detik
  //   Future.delayed(const Duration(seconds: 2), () {
  //     animationController.reverse().then((value) {
  //       overlayEntry.remove();
  //     });
  //   });
  // }
}
