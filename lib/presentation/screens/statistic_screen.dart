import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';

class StatisticScreen extends StatefulWidget {
  @override
  _StatisticScreenState createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  List<RiwayatHidrasi> waterHistory = [];
  DateTime selectedDate = DateTime.now();
  final RiwayatHidrasiController _controller = RiwayatHidrasiController();
  bool isLoading = true;
  int? userId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ambil ID pengguna dari session
      userId = await SessionManager().getUserId();
      print("[DEBUG StatisticScreen] userId: $userId");
      
      if (userId != null) {
        await _loadRiwayatHidrasi();
      } else {
        setState(() {
          errorMessage = "User ID tidak tersedia";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error saat inisialisasi: $e";
      });
      print("[ERROR StatisticScreen] Error saat inisialisasi: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRiwayatHidrasi() async {
    if (userId == null) return;

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      print("[DEBUG StatisticScreen] Memuat data untuk tanggal: $formattedDate, userId: $userId");
      
      List<RiwayatHidrasi> history = await _controller.getRiwayatHidrasiByTanggal(userId!, selectedDate);
      print("[DEBUG StatisticScreen] Jumlah data yang ditemukan: ${history.length}");
      
      if (history.isNotEmpty) {
        // Debug data pertama
        print("[DEBUG StatisticScreen] Data pertama: jumlah=${history[0].jumlahHidrasi}, waktu=${history[0].waktuHidrasi}");
      }

      setState(() {
        waterHistory = history;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error saat memuat data: $e";
      });
      print("[ERROR StatisticScreen] Error saat memuat data: $e");
    }
  }

  // Fungsi untuk mengubah tanggal yang ditampilkan
  void _changeDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      errorMessage = null;
    });
    _loadRiwayatHidrasi();
  }

  // Fungsi untuk memilih tanggal dari date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      _changeDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) == 
                         DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String dateTitle = isToday ? "Hari Ini" : DateFormat('dd MMMM yyyy').format(selectedDate);

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
          
          // Widget untuk tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    _changeDate(selectedDate.subtract(Duration(days: 1)));
                  },
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Text(
                    dateTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: isToday
                      ? null // Disable jika sudah hari ini
                      : () {
                          _changeDate(selectedDate.add(Duration(days: 1)));
                        },
                  color: isToday ? Colors.grey : null,
                ),
              ],
            ),
          ),
          
          // Debug info
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Debug: $errorMessage",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            
          // UserId debug info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "User ID: ${userId ?? 'null'}, Data count: ${waterHistory.length}",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Konten utama
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : waterHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 64, 
                              color: Colors.blue.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              isToday
                                  ? "Waktunya minum air!"
                                  : "Tidak ada riwayat hidrasi pada tanggal ini",
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.grey,
                                fontWeight: FontWeight.w500
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: waterHistory.length,
                        itemBuilder: (context, index) {
                          final item = waterHistory[index];
                          // Ambil waktu dari objek riwayat hidrasi
                          final String time = item.waktuHidrasi != null ? "${item.waktuHidrasi} WIB" : "00:00 WIB";
                          
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
                                      'assets/images/glass.svg',
                                      width: 40,
                                      height: 40,
                                    ),

                                    SizedBox(width: 15), // Jarak antar elemen

                                    // Ukuran Gelas (Jumlah mL)
                                    Text(
                                      "${item.jumlahHidrasi.toInt()} mL",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2F2E41)),
                                    ),

                                    SizedBox(width: 15), // Jarak antar elemen

                                    // Waktu (Dilebarkan agar fleksibel)
                                    Expanded(
                                      child: Text(
                                        time, // Gunakan waktu dari database
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
        ],
      ),
    );
  }
}