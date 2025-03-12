import 'package:flutter/material.dart';

class ButtonPicker extends StatefulWidget {
  const ButtonPicker({Key? key}) : super(key: key);

  @override
  State<ButtonPicker> createState() => _ButtonPickerState();
}

class _ButtonPickerState extends State<ButtonPicker> {
  int selectedWater = 250; // Default ukuran air

  void _showWaterPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Setengah layar
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pilih Ukuran Air",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Row untuk menampilkan icon edit, ukuran air, dan teks "mL"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Edit (Tidak Bergerak)
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.edit, size: 32, color: Colors.grey),
                  ),

                  // Scroll ukuran air
                  Expanded(
                    child: SizedBox(
                      height: 250, // Menghindari overflow
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        physics: FixedExtentScrollPhysics(),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 20,
                          builder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedWater = (index + 1) * 50;
                                });
                                Navigator.pop(context);
                              },
                              child: WaterSized(water: (index + 1) * 50),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Teks "mL" (Tidak Bergerak)
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      "mL",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Ukuran Air: $selectedWater mL",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showWaterPicker,
              child: Text("Pilih Ukuran Air"),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterSized extends StatelessWidget {
  final int water;

  WaterSized({required this.water});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$water",
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}
