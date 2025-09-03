import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class DrinkPercentageAlerts {
  static bool hasShown100Percent = false;
  static bool hasShown200Percent = false;
  static bool hasShownExceed100Percent = false;

  static void checkAndShowPercentageAlert(
      BuildContext context, double currentIntake, double currentTarget) {
    if (!context.mounted || currentTarget <= 0) return;

    double percentage = (currentIntake / currentTarget) * 100;

    // Reset flags jika intake turun
    if (percentage < 100) {
      hasShown100Percent = false;
      hasShownExceed100Percent = false;
    }
    if (percentage < 200) {
      hasShown200Percent = false;
    }

    // Alert untuk 100% (menggunakan kata-kata dari kode yang dikirimkan)
    if (percentage >= 100 && percentage < 150 && !hasShown100Percent) {
      hasShown100Percent = true;
      _showCongratsAlert(context);
    }
    // Alert untuk lebih dari 100% (exceed target)
    else if (percentage >= 150 && percentage < 200 && !hasShownExceed100Percent) {
      hasShownExceed100Percent = true;
      _showExceedTargetAlert(context);
    }
    // Alert untuk lebih dari 200% (warning)
    else if (percentage >= 200 && !hasShown200Percent) {
      hasShown200Percent = true;
      _showOverdrinkWarningAlert(context);
    }
  }

  // Alert untuk 100% target (menggunakan kata-kata dari kode asli)
  static void _showCongratsAlert(BuildContext context) {
    if (!context.mounted) return;

    final confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    if (context.mounted) confettiController.play();

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Congrats",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (context.mounted)
                ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.05,
                  numberOfParticles: 25,
                  colors: const [
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.green
                  ],
                ),
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: animation, curve: Curves.easeOutBack),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                  backgroundColor: Colors.white,
                  title: Column(children: [
                    Icon(Icons.emoji_events,
                        color: Colors.amber, size: screenWidth * 0.15),
                    SizedBox(height: screenHeight * 0.012),
                    Text('Selamat! 🎉',
                        style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ]),
                  content: Text('Kamu sudah mencapai target harianmu!',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                      textAlign: TextAlign.center),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (context.mounted) {
                            confettiController.dispose();
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025)),
                        ),
                        child: Text('Mantap!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (confettiController.state == ConfettiControllerState.playing) {
        confettiController.dispose();
      }
    });
  }

  // Alert untuk melebihi target (lebih dari 100%)
  static void _showExceedTargetAlert(BuildContext context) {
    if (!context.mounted) return;

    final confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    if (context.mounted) confettiController.play();

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Exceed Target",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (context.mounted)
                ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.03,
                  numberOfParticles: 15,
                  colors: const [
                    Colors.green,
                    Colors.lightGreen,
                    Colors.teal,
                    Colors.cyan
                  ],
                ),
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: animation, curve: Curves.easeOutBack),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                  backgroundColor: Colors.white,
                  title: Column(children: [
                    Icon(Icons.star,
                        color: Colors.yellow, size: screenWidth * 0.15),
                    SizedBox(height: screenHeight * 0.012),
                    Text('Keren!',
                        style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                        textAlign: TextAlign.center),
                  ]),
                  content: Text('Kamu bisa minum melebihi target harianmu!',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                      textAlign: TextAlign.center),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (context.mounted) {
                            confettiController.dispose();
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025)),
                        ),
                        child: Text('Hebat!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (confettiController.state == ConfettiControllerState.playing) {
        confettiController.dispose();
      }
    });
  }

  // Alert untuk peringatan minum berlebihan (lebih dari 200%)
  static void _showOverdrinkWarningAlert(BuildContext context) {
    if (!context.mounted) return;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Warning",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
                parent: animation, curve: Curves.easeOutBack),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.05)),
              backgroundColor: Colors.white,
              title: Column(children: [
                Icon(Icons.warning,
                    color: Colors.orange, size: screenWidth * 0.15),
                SizedBox(height: screenHeight * 0.012),
                Text('Peringatan!',
                    style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                    textAlign: TextAlign.center),
              ]),
              content: Text(
                  'Terlalu banyak minum juga bisa berdampak kurang baik untuk tubuh!',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  textAlign: TextAlign.center),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.025)),
                    ),
                    child: Text('Mengerti!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method untuk reset semua flags (bisa dipanggil saat ganti hari)
  static void resetAllFlags() {
    hasShown100Percent = false;
    hasShown200Percent = false;
    hasShownExceed100Percent = false;
  }
}