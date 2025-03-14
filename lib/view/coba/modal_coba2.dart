import 'package:flutter/material.dart';

class ButtonPicker extends StatefulWidget {
  const ButtonPicker({Key? key}) : super(key: key);

  @override
  State<ButtonPicker> createState() => _ButtonPickerState();
}

class _ButtonPickerState extends State<ButtonPicker> {
  int selectedWater = 50; // Default ukuran air

  void _showWaterPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempSelectedWater = selectedWater; // Variabel sementara
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Pilih Ukuran Air",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Stack agar teks di tengah tetap diam
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      

                      // Highlight tetap di tengah
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2), // Highlight
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 24, color: Colors.blueGrey),
                            SizedBox(width: 20),
                            Padding(
                              padding: EdgeInsets.only(left: 50.0, right: 40.0),
                              child: Text(
                                "$tempSelectedWater",
                                style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                            ),
                            SizedBox(width: 20),
                            Text(
                              "mL",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Tombol "Pilih" untuk konfirmasi ukuran air
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          selectedWater = tempSelectedWater;
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: Text("Pilih"),
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

// Widget untuk menampilkan ukuran air
class WaterSized extends StatelessWidget {
  final int water;

  WaterSized({required this.water});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$water",
        style: TextStyle(
            fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
