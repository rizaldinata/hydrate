import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        'iconPath': 'assets/images/glass.svg' // Simpan path, bukan widget
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 242, 253),
      appBar: AppBar(
        title: Center(
          child: Text(
            "Riwayat Minum Air",
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false, // Hilangkan tombol back
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
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
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Ikon Gelas
                                SvgPicture.asset(
                                  waterHistory[index]['iconPath'],
                                  width: 40,
                                  height: 40,
                                ),

                                SizedBox(width: 15), // Jarak antar elemen

                                // Ukuran Gelas (Jumlah mL)
                                Text(
                                  "${waterHistory[index]['amount']} mL",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2F2E41)),
                                ),

                                SizedBox(width: 15), // Jarak antar elemen

                                // Waktu (Dilebarkan agar fleksibel)
                                Expanded(
                                  child: Text(
                                    "${waterHistory[index]['time']}",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2F2E41)),
                                    textAlign: TextAlign.right, // Rata kanan
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tambahkan garis pemisah biru di antara item
                          Divider(
                            color: Color(0xFF00A6FB), // Warna garis biru
                            thickness: 0.3, // Ketebalan garis
                            indent: 20, // Jarak dari kiri
                            endIndent: 20, // Jarak dari kanan
                          ),
                        ],
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
