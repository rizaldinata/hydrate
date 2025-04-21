import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrate/presentation/widgets/nitip/addWater_modal_widget.dart';
import 'package:hydrate/presentation/widgets/nitip/addWater_widget.dart';

class CobaAddWater extends StatefulWidget {
  const CobaAddWater({super.key});

  @override
  State<CobaAddWater> createState() => _CobaAddWaterState();
}

class _CobaAddWaterState extends State<CobaAddWater> {
  Map<double, double> _glassOffsets = {};
  double currentIntake = 0;
  double target = 2000; // Target default, bisa diubah sesuai kebutuhan
  final GlobalKey<AddWaterState> _addWaterKey = GlobalKey<AddWaterState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          AddWater(key: _addWaterKey),
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${currentIntake.toInt()} mL', // Tetap menampilkan jumlah air yang dikonsumsi sebenarnya
                style: TextStyle(
                  color: currentIntake >= target ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                ' / ${target.toInt()} mL',
                style: const TextStyle(
                  color: Color(0xFF2F2E41),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Container(
            width: screenWidth * (0.8 + 0.04),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F2E41)
                      .withOpacity(0.1), // Warna bayangan
                  blurRadius: 12, // Seberapa jauh bayangan menyebar
                  offset: Offset(1, 2), // Posisi bayangan (X, Y)
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDrinkOption('assets/images/glass/100.svg', 100, 28),
                _buildDrinkOption('assets/images/glass/150.svg', 150, 24),
                _buildDrinkOption('assets/images/glass/200.svg', 200, 24),
                GestureDetector(
                  onTap: () => AddWaterModal(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        onPressed: () {
                          AddWaterModal();
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkOption(String gambar, double amount, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Supaya ukuran sesuai isi
      children: [
        GestureDetector(
          onTap: () => AddWater(),
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            transform:
                Matrix4.translationValues(0, _glassOffsets[amount] ?? 0, 0),
            child: SvgPicture.asset(
              gambar,
              fit: BoxFit.scaleDown,
              width: size,
            ),
          ),
        ),
        const SizedBox(height: 5), // Beri sedikit jarak
        Text(
          '${amount.toInt()} mL',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
