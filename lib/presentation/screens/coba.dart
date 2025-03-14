import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String name;
  final String gender;
  final String weight;
  final String wakeUpTime;
  final String sleepTime;

  const HomePage({
    Key? key,
    required this.name,
    required this.gender,
    required this.weight,
    required this.wakeUpTime,
    required this.sleepTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Nama: $name"),
            Text("Jenis Kelamin: $gender"),
            Text("Berat Badan: $weight kg"),
            Text("Jam Bangun: $wakeUpTime"),
            Text("Jam Tidur: $sleepTime"),
          ],
        ),
      ),
    );
  }
}
