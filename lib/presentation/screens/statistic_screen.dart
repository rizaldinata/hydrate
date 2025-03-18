import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticScreen extends StatefulWidget {
  @override
  _StatisticScreenState createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  List<Map<String, dynamic>> waterHistory = [];

  // Fungsi untuk menambahkan riwayat minum
  void _addWaterEntry(int amount) {
    setState(() {
      waterHistory.insert(0, {
        'time': DateFormat('HH:mm').format(DateTime.now()), // Format waktu
        'amount': amount,
        'icon': Icons.local_drink,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Minum Air", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: waterHistory.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada riwayat minum",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: waterHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        trailing: Text(
                          "${waterHistory[index]['amount']} mL",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        leading: Icon(waterHistory[index]['icon'], color: Colors.blue),
                        title: Text(
                          "${waterHistory[index]['time']}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _addWaterEntry(200); // Tambah 200 mL ke riwayat
            },
            child: Text("Minum 200 mL"),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
