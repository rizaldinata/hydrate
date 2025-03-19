import 'package:flutter/material.dart';
import 'package:bottom_picker/bottom_picker.dart';

class HydrationTracker extends StatefulWidget {
  const HydrationTracker({super.key});

  @override
  _HydrationTrackerState createState() => _HydrationTrackerState();
}

class _HydrationTrackerState extends State<HydrationTracker> {
  int selectedWater = 150; // Default 150mL
  int totalWater = 0; // Total konsumsi air

  // Fungsi untuk menampilkan bottom picker
  void _showBottomPicker(BuildContext context) {
    BottomPicker(
      items: List.generate(20, (index) {
        int value = 50 + (index * 50);
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
              right: 30, // Menjaga jarak dari kanan
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
      height: 300, // Tinggi modal
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
          totalWater += selectedWater; // Langsung menambah total air
        });
      },
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracker Minum Air")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Tampilan Scrollable Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showBottomPicker(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Pilih Jumlah Air",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Menampilkan total air minum
          Text(
            "Total Air Minum: $totalWater mL",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
