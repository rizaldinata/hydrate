import 'package:flutter/material.dart';
import 'package:water_bottle/water_bottle.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CobaAir extends StatefulWidget {
  CobaAir({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _CobaAirState createState() => _CobaAirState();
}

class _CobaAirState extends State<CobaAir> {
  final plainBottleRef = GlobalKey<WaterBottleState>();
  final sphereBottleRef = GlobalKey<SphericalBottleState>();
  final triangleBottleRef = GlobalKey<TriangularBottleState>();

  final PageController _pageController = PageController();
  double waterLevel = 0.05; // 50% dari total kapasitas
  double maxCapacity = 1000.0; // Kapasitas total dalam mililiter (1 liter)

  // Fungsi untuk menambah air
  void addWater(double amount) {
    setState(() {
      waterLevel += amount / maxCapacity;
      if (waterLevel > 1.0) {
        waterLevel = 1.0; // Batasi agar tidak melebihi kapasitas
      }
      plainBottleRef.currentState?.waterLevel = waterLevel;
      sphereBottleRef.currentState?.waterLevel = waterLevel;
      triangleBottleRef.currentState?.waterLevel = waterLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plain = WaterBottle(
      key: plainBottleRef,
      waterColor: Colors.blue,
      bottleColor: Colors.lightBlue,
      capColor: Colors.blueGrey,
    );

    final sphere = SphericalBottle(
      key: sphereBottleRef,
      waterColor: Colors.red,
      bottleColor: Colors.redAccent,
      capColor: Colors.grey.shade700,
    );

    final triangle = TriangularBottle(
      key: triangleBottleRef,
      waterColor: Colors.lime,
      bottleColor: Colors.limeAccent,
      capColor: Colors.red,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Spacer(),

            // PageView untuk swipe botol dengan ukuran lebih kecil
            SizedBox(
              height: 250, // Ukuran yang lebih kecil agar tidak terlalu besar
              width: 200,
              child: PageView(
                controller: _pageController,
                children: [
                  SizedBox(width: 150, height: 200, child: plain),
                  SizedBox(width: 150, height: 200, child: sphere),
                  SizedBox(width: 150, height: 200, child: triangle),
                ],
              ),
            ),

            // Smooth Page Indicator
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: Colors.blue,
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                "${(waterLevel * maxCapacity).toInt()} ml dari ${maxCapacity.toInt()} ml",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            Spacer(),

            // Tombol tambah air dengan Expanded agar lebih rapi
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => addWater(100), 
                      child: Text("+100 ml"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => addWater(200), 
                      child: Text("+200 ml"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => addWater(500), 
                      child: Text("+500 ml"),
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),
          ],
        ),
      ),
    );
  }
}
