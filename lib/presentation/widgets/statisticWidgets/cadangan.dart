import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:lottie/lottie.dart';
import 'dart:collection';

class Cadangan extends StatefulWidget {
  const Cadangan({Key? key}) : super(key: key);

  @override
  CadanganState createState() => CadanganState();
}

class CadanganState extends State<Cadangan> {
  final Color _primaryColor = const Color(0xFF00A6FB);
  final Color _accentColor = const Color(0xFF38BDF8);
  final Color _backgroundColor = const Color(0xFFE8F7FF);
  final Color _textPrimaryColor = const Color(0xFF0F172A);
  final Color _textSecondaryColor = const Color(0xFF475569);
  final Color _surfaceColor = Colors.white;

  List<RiwayatHidrasi> waterHistory = [];
  final DateTime today = DateTime.now();
  final RiwayatHidrasiController _controller = RiwayatHidrasiController();
  final TargetHidrasiController targetHidrasiController =
      TargetHidrasiController();
  bool isLoading = true;
  int? userId;
  String? errorMessage;
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();
  Timer? _undoTimer;
  
  // Mode seleksi
  bool _isSelectionMode = false;
  final Set<int> _selectedItems = HashSet<int>();

  @override
  void initState() {
    super.initState();
    _initData();
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event.type == 'refresh_statistics' || event.type == 'refresh_all') {
        refresh();
      }
    });
  }

  void refresh() {
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      userId = await SessionManager().getUserId();
      if (userId != null) {
        await _loadRiwayatHidrasi();
      } else {
        setState(() {
          errorMessage = "Pengguna tidak teridentifikasi";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Gagal memuat data: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRiwayatHidrasi() async {
    if (userId == null) return;

    try {
      List<RiwayatHidrasi> history =
          await _controller.getRiwayatHidrasiByTanggal(userId!, today);
      setState(() {
        waterHistory = history;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Kesalahan saat memuat riwayat: $e";
      });
    }
  }

  void _showSnackBarNotification({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    bool isSuccess = false,
  }) {
    _undoTimer?.cancel();
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      duration: duration,
      backgroundColor: isSuccess ? Colors.green.shade600 : _accentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(10),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Toggle seleksi item
  void _toggleItemSelection(int id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }
    });
  }

  // Masuk ke mode seleksi - dimodifikasi untuk tidak otomatis memilih item pertama
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      // Tidak perlu menambahkan item apapun ke _selectedItems di sini
    });
  }

  // Keluar dari mode seleksi
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }
  
  // Pilih semua item
  void _selectAllItems() {
    setState(() {
      if (_selectedItems.length == waterHistory.length) {
        // Jika semua item sudah dipilih, batalkan semua
        _selectedItems.clear();
      } else {
        // Pilih semua item
        _selectedItems.clear();
        for (var item in waterHistory) {
          if (item.id != null) {
            _selectedItems.add(item.id!);
          }
        }
      }
    });
  }

  // Hapus item yang dipilih
 Future<void> _deleteSelectedItems() async {
   if (_selectedItems.isEmpty) return;
   
   bool confirm = await showDialog(
     context: context,
     builder: (context) => AlertDialog(
       backgroundColor: Colors.white,
       title: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           Image.asset(
             'assets/images/delete.png',
             width: 60,
             height: 60,
           ),
           const SizedBox(height: 12),
         ],
       ),
       contentTextStyle: TextStyle(
         color: _textPrimaryColor,
         fontSize: 16,
         fontWeight: FontWeight.w500,
       ),
       content: Text(
         _selectedItems.length == 1
             ? "Apakah kamu yakin ingin menghapus 1 catatan hidrasi?"
             : "Apakah kamu yakin ingin menghapus ${_selectedItems.length} catatan hidrasi?",
         textAlign: TextAlign.center,
         style: const TextStyle(height: 1.5),
       ),
       actions: [
         SizedBox(
           width: 80,
           child: TextButton(
             onPressed: () => Navigator.of(context).pop(false),
             style: ElevatedButton.styleFrom(
               foregroundColor: Colors.blueGrey,
               backgroundColor: Colors.grey[300],
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(16),
               ),
             ),
             child: const Text(
               "Batal",
               style: TextStyle(color: Color(0xFF0F172A)),
             ),
           ),
         ),
         SizedBox(
           width: 80,
           child: TextButton(
             onPressed: () => Navigator.of(context).pop(true),
             style: ElevatedButton.styleFrom(
               foregroundColor: Colors.red,
               backgroundColor: Colors.red,
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(16),
               ),
             ),
             child: const Text(
               "Hapus",
               style: TextStyle(color: Colors.white),
             ),
           ),
         ),
       ],
     ),
   );

   if (confirm != true) return;

   // Backup item yang akan dihapus
   List<RiwayatHidrasi> deletedItems = [];
   for (var item in waterHistory) {
     if (item.id != null && _selectedItems.contains(item.id)) {
       deletedItems.add(item);
     }
   }
   
   // Hapus dari tampilan
   setState(() {
     waterHistory.removeWhere((item) => 
         item.id != null && _selectedItems.contains(item.id));
     // Kosongkan item terpilih setelah di-backup untuk dihapus
     _selectedItems.clear(); 
     // Keluar dari mode seleksi setelah konfirmasi hapus
     _isSelectionMode = false;
   });

   // Tampilkan notifikasi dengan opsi batalkan
   _showSnackBarNotification(
     message: deletedItems.length == 1
         ? "1 catatan hidrasi telah dihapus"
         : "${deletedItems.length} catatan hidrasi telah dihapus",
     actionLabel: "BATALKAN",
     onAction: () {
       // Hentikan timer penghapusan permanen jika "BATALKAN" ditekan
       _undoTimer?.cancel();
       
       setState(() {
         waterHistory.addAll(deletedItems);
         waterHistory.sort((a, b) =>
             (b.waktuHidrasi ?? "").compareTo(a.waktuHidrasi ?? ""));
       });
       _showSnackBarNotification(
         message: "Catatan telah dipulihkan",
         duration: const Duration(seconds: 2),
         isSuccess: true,
       );
     },
   );

   // Timer untuk menghapus data secara permanen jika tidak dibatalkan
   _undoTimer = Timer(const Duration(seconds: 4), () async { // Tambahkan 'async' di sini
     if (userId != null) {
       print("Melakukan penghapusan permanen untuk ${deletedItems.length} item...");
       for (var item in deletedItems) {
         try {
           // ==== PERUBAHAN UTAMA DI SINI ====
           // Gunakan 'await' untuk menunggu setiap operasi selesai
           await _controller.hapusRiwayatDanKurangiTarget(
             idRiwayat: item.id ?? 0,
             idPengguna: userId!,
             tanggalHidrasi: item.tanggalHidrasi ?? "",
             targetController: targetHidrasiController,
           );
           print("Berhasil menghapus item ID: ${item.id}");
         } catch (e) {
           print("Gagal menghapus item ID: ${item.id}. Error: $e");
           // Anda bisa menambahkan notifikasi error di sini jika perlu
         }
       }
       // Kirim event untuk refresh halaman lain SETELAH semua penghapusan selesai
       _eventBus.fire('refresh_all');
     }
   });
 }

Widget _buildTodayHeader() {
  final String dateTitle = "Hari Ini";

  return Container(
    height: 56,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _primaryColor.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: _primaryColor, size: 24),
              const SizedBox(width: 8),
              // Expanded agar teks tidak overflow
              Text(
                _isSelectionMode ? "Pilih item" : dateTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _isSelectionMode ? Colors.orange : _primaryColor,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Tombol kanan
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: _exitSelectionMode,
              tooltip: 'Tutup',
            )
          else if (waterHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.more_vert, color: _primaryColor),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit, color: _primaryColor),
                        title: Text(
                          'Pilih Item',
                          style: TextStyle(
                            color: _textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (waterHistory.isNotEmpty) {
                            _enterSelectionMode();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Menu',
            ),
        ],
      ),
    ),
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.1),
                  _primaryColor.withOpacity(0.2)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset('assets/loading.json', width: 200, height: 200),
          ),
          const SizedBox(height: 24),
          Text(
            "Ayo Minum Air!",
            style: TextStyle(
              fontSize: 20,
              color: _textPrimaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Yuk catat konsumsi air mineralmu hari ini",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondaryColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(RiwayatHidrasi item, String time, bool isSmallScreen, double screenWidth) {
    final bool isSelected = item.id != null && _selectedItems.contains(item.id);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor.withOpacity(0.1) : _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _primaryColor.withOpacity(0.1),
          highlightColor: _primaryColor.withOpacity(0.05),
          onTap: () {
            if (_isSelectionMode && item.id != null) {
              _toggleItemSelection(item.id!);
            } else if (!_isSelectionMode && item.id != null) {
              // Panjang tekan sudah menangani mode seleksi
            }
          },
          onLongPress: () {
            if (!_isSelectionMode && item.id != null) {
              _enterSelectionMode();
              // Tambahkan item yang di-long press ke selected items
              _toggleItemSelection(item.id!);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 16,
            ),
            child: Row(
              children: [
                // Checkbox saat mode seleksi
                if (_isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? _primaryColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/glass.svg',
                    width: isSmallScreen ? 24 : 32,
                    height: isSmallScreen ? 24 : 32,
                    colorFilter:
                        ColorFilter.mode(_primaryColor, BlendMode.srcIn),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${item.jumlahHidrasi.toInt()} mL",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Konsumsi Air",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: _textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: isSmallScreen ? 12 : 14,
                              color: _primaryColor,
                            ),
                            SizedBox(width: isSmallScreen ? 2 : 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                fontWeight: FontWeight.w500,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterIntakeItem(RiwayatHidrasi item) {
    final String time = item.waktuHidrasi ?? "00:00";
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    // Tetap mempertahankan fitur swipe-to-delete namun juga menambahkan tombol hapus langsung
    return _buildItemCard(item, time, isSmallScreen, screenWidth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTodayHeader(),
            if (errorMessage != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor))
                  : waterHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: waterHistory.length,
                          itemBuilder: (context, index) =>
                              _buildWaterIntakeItem(waterHistory[index]),
                        ),
            ),
            // Tampilkan tombol aksi seleksi meskipun tidak ada item yang dipilih
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tombol Pilih semua
                    ElevatedButton.icon(
                      icon: Icon(
                        _selectedItems.length == waterHistory.length
                            ? Icons.deselect
                            : Icons.select_all,
                        color: Colors.white,
                      ),
                      label: Text(
                        _selectedItems.length == waterHistory.length
                            ? "Batal Pilih"
                            : "Pilih Semua",
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selectAllItems,
                    ),
                    const SizedBox(width: 16),
                    // Tombol Hapus selection - diubah untuk selalu menampilkan jumlah item yang dipilih
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      label: Text(
                        _selectedItems.isEmpty
                            ? "Hapus 0 Item"
                            : _selectedItems.length == 1
                                ? "Hapus 1 Item"
                                : "Hapus ${_selectedItems.length} Item",
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selectedItems.isEmpty ? null : _deleteSelectedItems,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}