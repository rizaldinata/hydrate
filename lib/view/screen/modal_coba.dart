import 'package:flutter/material.dart';
import 'package:bottom_picker/bottom_picker.dart';

class HydrationPicker extends StatelessWidget {
  const HydrationPicker({super.key});

  void _showBottomPicker(BuildContext context) {
    BottomPicker(
      items: List.generate(20, (index) {
        int value = 50 + (index * 50); // 50, 100, 150, ..., 1000
        return Center(
          child: Text(
            "$value ML",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      }),
      pickerTitle: const Text(
        'Pilih Jumlah Air',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
      ),
      titleAlignment: Alignment.center,
      pickerTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      closeIconColor: Colors.red,
      onChange: (index) {
        int selectedValue = (50 + (index * 50)).toInt();
        print("Selected: $selectedValue ML");
      },
      onSubmit: (index) {
        int selectedValue = (50 + (index * 50)).toInt();
        print("User memilih: $selectedValue ML");
      },
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Air Minum")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showBottomPicker(context),
          child: const Text("Pilih Jumlah ML"),
        ),
      ),
    );
  }
}
