import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  String? _gender;

  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerHeight = TextEditingController();
  TextEditingController controllerWeight = TextEditingController();

  void _pilihgender(String? value) {
    setState(() {
      _gender = value;
    });
  }

  void kirimData() {
    AlertDialog alertDialog = AlertDialog(
      content: Container(
        height: 200.0,
        padding: EdgeInsets.all(10.0),
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            Text("Nama Lengkap : ${controllerName.text}"),
            Text("Heightword : ${controllerHeight.text}"),
            Text("Weight Hidup : ${controllerWeight.text}"),
            Text("Jenis Kelamin : $_gender"),
            Padding(padding: EdgeInsets.only(top: 20.0)),
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: EdgeInsets.symmetric(vertical: 15.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Mengatur radius sudut
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("Kembali", style: TextStyle(color: Colors.white)),
          ),
          ],
        ),
      ),
    );
    showDialog(context: context, builder: (context) => alertDialog);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Center(
          child: Text(
            "Formulir",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: controllerName,
            decoration: InputDecoration(
              hintText: "Nama Lengkap",
              labelText: "Nama Lengkap",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: controllerHeight,
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Tinggi Badan",
              labelText: "Tinggi Badan",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: controllerWeight,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Berat Badan",
              labelText: "Berat Badan",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          SizedBox(height: 20.0),

          // Radio Button Gender
          RadioListTile(
            value: "Laki-laki",
            title: Text("Laki-laki"),
            groupValue: _gender,
            onChanged: (String? value) {
              _pilihgender(value);
            },
            activeColor: Colors.deepPurple,
            subtitle: Text("Pilih ini jika Anda Laki-laki"),
          ),
          RadioListTile(
            value: "Perempuan",
            title: Text("Perempuan"),
            groupValue: _gender,
            onChanged: (String? value) {
              _pilihgender(value);
            },
            activeColor: Colors.deepPurple,
            subtitle: Text("Pilih ini jika Anda Perempuan"), // Diperbaiki
          ),
          SizedBox(height: 20.0),

          // Dropdown Agama dengan Padding agar tidak error
          SizedBox(height: 20.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(vertical: 15.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Mengatur radius sudut
              ),
            ),
            onPressed: () {
              kirimData();
            },
            child: Text("Simpan", style: TextStyle(color: Colors.white)),
          ),

        ],
      ),
    );
  }
}
