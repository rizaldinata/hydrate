import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/material.dart';
import 'package:hydrate/controller/home_controller.dart';
import 'package:hydrate/view/screen/navigation.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';

class HomeScreens extends StatefulWidget {
  final String name;
  const HomeScreens({super.key, required this.name});

  @override
  State<HomeScreens> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreens>
    with SingleTickerProviderStateMixin {
  // late final HomeController _controller;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final double target = 1500; // Target harian air
  double currentIntake = 0; // Nilai awal air dalam ml
  final ValueNotifier<double> _valueNotifier =
      ValueNotifier<double>(0); //nilai persen awal
  // Inisialisasi scrollbar
  int selectedWater = 150; // Default 150mL
  int totalWater = 0; // Total konsumsi air

  @override
  void initState() {
    // super.initState();
    // _controller = HomeController();
    // _controller.initAnimation(this);

    // Future.delayed(const Duration(milliseconds: 600), () {
    //   setState(() {});
    // });

    // Future.delayed(const Duration(seconds: 5), () {
    //   _controller.startAnimation();
    // });

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  // buat memberhentikan resource yang tidak digunakan
  @override
  void dispose() {
    // _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk menambah jumlah air
  void _addWater(double amount) {
    setState(() {
      if (currentIntake + amount <= target) {
        currentIntake += amount;
      } else {
        currentIntake = target;
      }
      _valueNotifier.value = (currentIntake / target) * 100;
    });
  }

  void _showAddWaterModal(BuildContext context) {
    BottomPicker(
      items: List.generate(20, (index) {
        int value = 50 + (index * 50); // 50, 100, 150, ..., 1000
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            Center(
              child: Text(
                "$value",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Positioned(
              right: 50, // Menjaga jarak dari kanan
              child: Text(
                "mL",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
          ],
        );
      }),
      height: 350, // Tinggi modal
      pickerTitle: const Text(
        'Pilih Jumlah Air',
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
      ),

      onChange: (index) {
        setState(() {
          selectedWater = (50 + (index * 50)).toInt();
        });
      },
      onSubmit: (index) {
        setState(() {
          selectedWater = (50 + (index * 50)).toInt();
          if (currentIntake + selectedWater <= target) {
            currentIntake += selectedWater;
          } else {
            currentIntake =
                target; // Jika melebihi target, tetap pada target maksimal
          }
          _valueNotifier.value = (currentIntake / target) * 100;
        });
      },
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Stack(
        children: [
          // Bagian atas
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul aplikasi
                const Text("HYDRATE",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                        fontFamily: "Gluten")),

                // menampilkan username
                Text(
                  "Hai, ${widget.name}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Kata-kata pencapaian
                const Text(
                  "Ayo selesaikan pencapaianmu hari ini!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // buat setengah lingkarannya
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.all(42.0),
                  child: Center(
                    // Likaran progress
                    child: DashedCircularProgressBar.aspectRatio(
                      aspectRatio: 1,
                      valueNotifier: _valueNotifier,
                      progress: _valueNotifier.value,
                      startAngle: 250, // start awal lingkaran
                      sweepAngle: 222, // finie lingkaran
                      foregroundColor: Color(0xFF00A6FB),
                      backgroundColor: const Color(0xFFA1E3F9),
                      foregroundStrokeWidth: 15, //ketebalan dalam lingkaran
                      backgroundStrokeWidth: 15, //ketebalan dalam lingkaran
                      animation: true,
                      seekSize: 10,
                      seekColor: const Color(0xffeeeeee),
                      child: Center(
                        child: ValueListenableBuilder(
                          valueListenable: _valueNotifier,
                          builder: (_, double value, __) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${value.toInt()}%', //persentage
                                style: const TextStyle(
                                  color: const Color(0xFF2F2E41),
                                  fontWeight: FontWeight.w300,
                                  fontSize: 60,
                                ),
                              ),
                              //Target harian
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${currentIntake.toInt()} ml', // capaian harian
                                    style: TextStyle(
                                      color: currentIntake >= target
                                          ? Colors.blue
                                          : Colors.red, // Warna berubah
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    ' / ${target.toInt()} ml', // target harian
                                    style: TextStyle(
                                      color: const Color(
                                          0xFF2F2E41), // Warna berubah
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // buat yang memilih gelas
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 350,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),

                      // bagian tambah air
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Tambah air default
                          _buildDrinkOption("Air", 100),
                          _buildDrinkOption("Air", 150),
                          _buildDrinkOption("Air", 200),

                          // Tambah air custom
                          GestureDetector(
                            onTap: () => _showAddWaterModal(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: FloatingActionButton(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  onPressed: () {
                                    _showAddWaterModal(context);
                                  },
                                  child: const Icon(Icons.add,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Navigasi(),
        ],
      ),
    );
  }

  // Membuat button untuk menambah jumlah air
  Widget _buildWaterButton(double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _addWater(amount);
          Navigator.pop(context); // Tutup modal setelah memilih
        },
        child: Text("+ ${amount.toInt()} ml",
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // memilih opsi gelas favorit
  Widget _buildDrinkOption(String name, double amount) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.local_drink, color: Colors.blue),
          onPressed: () => _addWater(amount),
          iconSize: 26, // Atur ukuran ikon agar lebih proporsional
          visualDensity:
              VisualDensity.compact, // Mengurangi ruang kosong di sekitar ikon
        ),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2F2E41),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${amount.toInt()} ml',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
