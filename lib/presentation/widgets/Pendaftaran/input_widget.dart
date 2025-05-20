import 'package:flutter/material.dart';

class InputTextWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController weightController;

  const InputTextWidget({
    super.key,
    required this.nameController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Masukkan Nama Pengguna",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Masukkan Berat Badan",
            suffixText: "Kg",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
