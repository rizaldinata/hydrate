import 'package:flutter/material.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PenggunaRepository _penggunaRepository = PenggunaRepository();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _beratBadanController = TextEditingController();
  String _jenisKelamin = "Laki-laki";
  String _jamBangun = "06:00";
  String _jamTidur = "22:00";

  void _register() async {
    String nama = _namaController.text.trim();
    String beratBadanInput = _beratBadanController.text.trim();

    if (nama.isEmpty || beratBadanInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap isi semua field")),
      );
      return;
    }

    double? beratBadan = double.tryParse(beratBadanInput);
    if (beratBadan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Berat badan harus berupa angka")),
      );
      return;
    }

    try {
      await _penggunaRepository.tambahPenggunaDanProfil(
          nama, _jenisKelamin, beratBadan, _jamBangun, _jamTidur);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print("Error saat registrasi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan saat registrasi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrasi")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: _beratBadanController,
              decoration: InputDecoration(labelText: "Berat Badan (kg)"),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _jenisKelamin,
              onChanged: (newValue) =>
                  setState(() => _jenisKelamin = newValue!),
              items: ["Laki-laki", "Perempuan"]
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text("Daftar")),
          ],
        ),
      ),
    );
  }
}
