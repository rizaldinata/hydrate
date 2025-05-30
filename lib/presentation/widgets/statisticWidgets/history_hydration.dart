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
  const Cadangan({super.key});

  @override
  CadanganState createState() => CadanganState();
}

// Pastikan CadanganState memiliki TickerProviderStateMixin jika belum ada
// karena AnimationController membutuhkan vsync.
class CadanganState extends State<Cadangan> with TickerProviderStateMixin { // Ditambahkan TickerProviderStateMixin
  final Color _primaryColor = const Color(0xFF00A6FB);
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

  // Mode seleksi
  bool _isSelectionMode = false;
  final Set<int> _selectedItems = HashSet<int>();

  // Daftar untuk menyimpan AnimationController agar bisa di-dispose
  final List<AnimationController> _activeAnimationControllers = [];

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
        if (mounted) { // Pastikan widget masih mounted
          isLoading = false;
        }
      });
    }
  }

  Future<void> _loadRiwayatHidrasi() async {
    if (userId == null) return;

    try {
      List<RiwayatHidrasi> history =
          await _controller.getRiwayatHidrasiByTanggal(userId!, today);
      if (mounted) { // Pastikan widget masih mounted
        setState(() {
          waterHistory = history;
        });
      }
    } catch (e) {
      if (mounted) { // Pastikan widget masih mounted
        setState(() {
          errorMessage = "Kesalahan saat memuat riwayat: $e";
        });
      }
    }
  }

  // Fungsi popup yang dimodifikasi
  // amount dipertahankan untuk kompatibilitas jika ada pemanggilan lain,
  // namun untuk notifikasi hapus, kita akan lebih fokus pada customMessage.
  void _showAddedWaterPopup(BuildContext context, double amount,
      {String? customMessage, bool isSuccess = true}) {
    if (!mounted) return; // Check jika widget masih mounted

    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);

    // Setiap pemanggilan fungsi ini harus memiliki AnimationController sendiri
    final animationController = AnimationController(
      vsync: this, // 'this' sekarang merujuk ke CadanganState yang memiliki TickerProviderStateMixin
      duration: const Duration(milliseconds: 500),
    );
    _activeAnimationControllers.add(animationController); // Tambahkan ke daftar

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Tentukan pesan dan ikon berdasarkan isSuccess dan customMessage
    final String messageToDisplay = customMessage ??
        (isSuccess
            ? "Berhasil menambahkan ${amount.toInt()} ml air!"
            : "Gagal melakukan aksi");

    // Anda mungkin ingin ikon yang berbeda untuk sukses dan gagal
    final String iconAsset = isSuccess
        ? 'assets/images/berhasil.svg' // Ikon sukses Anda
        : 'assets/images/gagal_popup.svg'; // Ganti dengan path ikon gagal Anda jika ada, atau gunakan ikon yang sama
    final Color iconColor =
        isSuccess ? const Color(0xFF3EDAC0) : Colors.red; // Warna ikon untuk gagal

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: screenHeight * 0.06,
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, -0.5), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animationController, curve: Curves.easeOut)),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.075, // Bisa disesuaikan jika pesan panjang
                  padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.012,
                      horizontal: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius:
                        BorderRadius.circular(screenWidth * 0.025),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: screenWidth * 0.01),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten jika pesan pendek
                    children: [
                      SvgPicture.asset(
                        iconAsset, // Menggunakan ikon yang sudah ditentukan
                        colorFilter: ColorFilter.mode(
                            iconColor, BlendMode.srcIn), // Menggunakan warna ikon yang sudah ditentukan
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                      ),
                      SizedBox(width: 2),
                      Expanded( // Expanded agar teks tidak overflow jika panjang
                        child: Text(
                          messageToDisplay, // Menggunakan pesan yang sudah ditentukan
                          style: TextStyle(
                              color: const Color(0xFF2F2E41),
                              fontSize: screenWidth * 0.038, // Sedikit kecilkan jika perlu
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis, // Atasi overflow
                          maxLines: 2, // Batasi jumlah baris
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 3), () { // Durasi popup sedikit lebih lama untuk pesan
      if (mounted && animationController.status != AnimationStatus.dismissed) {
        animationController.reverse().whenComplete(() {
          if (overlayEntry?.mounted ?? false) {
             overlayEntry?.remove();
          }
          animationController.dispose();
          _activeAnimationControllers.remove(animationController); // Hapus dari daftar
        });
      } else {
        // Jika tidak mounted atau sudah dismissed, pastikan overlay di-remove jika masih ada
        // dan controller di-dispose
        if (overlayEntry?.mounted ?? false) {
           overlayEntry?.remove();
        }
        if (!_activeAnimationControllers.contains(animationController)) {
            // Controller mungkin sudah di-dispose oleh logic lain atau belum ditambahkan,
            // tapi jika belum dan perlu, dispose di sini.
            // Namun, dengan alur sekarang, harusnya sudah di handle.
        } else if (_activeAnimationControllers.contains(animationController)) {
             animationController.dispose();
            _activeAnimationControllers.remove(animationController);
        }
      }
    });
  }

  // Toggle seleksi item
  void _toggleItemSelection(int id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }
      // Jika tidak ada item terpilih lagi setelah toggle, keluar dari mode seleksi
      if (_selectedItems.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
    });
  }

  // Masuk ke mode seleksi
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
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
        _selectedItems.clear();
      } else {
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
    if (_selectedItems.isEmpty) {
       _showAddedWaterPopup(
        context,
        0, // Amount tidak relevan di sini
        customMessage: "Tidak ada item yang dipilih.",
        isSuccess: false, // Menandakan ini bukan operasi sukses
      );
      return;
    }

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
        ) ?? false; // Memberikan nilai default jika dialog di-dismiss

    if (!confirm) return;

    List<RiwayatHidrasi> itemsToDeletePermanently = [];
    for (var item in waterHistory) {
      if (item.id != null && _selectedItems.contains(item.id)) {
        itemsToDeletePermanently.add(item);
      }
    }

    // Hapus dari tampilan (UI) terlebih dahulu untuk responsivitas
    if (mounted) {
      setState(() {
        waterHistory.removeWhere(
            (item) => item.id != null && _selectedItems.contains(item.id));
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }


    if (userId != null && itemsToDeletePermanently.isNotEmpty) {
      bool allSucceeded = true;
      int successCount = 0;
      for (var item in itemsToDeletePermanently) {
        try {
          await _controller.hapusRiwayatDanKurangiTarget(
            idRiwayat: item.id ?? 0,
            idPengguna: userId!,
            tanggalHidrasi: item.tanggalHidrasi,
            targetController: targetHidrasiController,
          );
          successCount++;
        } catch (e) {
          allSucceeded = false;
          // Jika ingin mengembalikan item yang gagal dihapus ke UI:
          // if (mounted) {
          //   setState(() {
          //     waterHistory.add(item); // Mungkin perlu sortir ulang
          //   });
          // }
        }
      }

      if (allSucceeded) {
        _showAddedWaterPopup(
          context,
          0, // Amount tidak relevan
          customMessage: itemsToDeletePermanently.length == 1
              ? "1 catatan hidrasi telah dihapus."
              : "${itemsToDeletePermanently.length} catatan hidrasi telah dihapus.",
          isSuccess: true,
        );
      } else if (successCount > 0) {
         _showAddedWaterPopup(
          context,
          0,
          customMessage: "$successCount dari ${itemsToDeletePermanently.length} catatan berhasil dihapus. Beberapa gagal.",
          isSuccess: false, // Menandakan ada kegagalan
        );
      }       
      else {
        _showAddedWaterPopup(
          context,
          0, // Amount tidak relevan
          customMessage: "Gagal menghapus catatan hidrasi dari server.",
          isSuccess: false,
        );
        // Jika semua gagal, mungkin ingin memuat ulang data dari server
        // untuk menyinkronkan UI
        _loadRiwayatHidrasi();
      }
      _eventBus.fire('refresh_all');
    } else if (itemsToDeletePermanently.isEmpty) {
        // Ini seharusnya tidak terjadi jika sudah ada konfirmasi dan item dipilih
        // Tapi sebagai fallback:
         _showAddedWaterPopup(
          context,
          0,
          customMessage: "Tidak ada item yang dihapus.",
          isSuccess: false,
        );
    }
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
            color: _primaryColor.withAlpha(25), // 0.1 opacity
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
                Text(
                  _isSelectionMode ? "Pilih item (${_selectedItems.length})" : dateTitle,
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
            if (_isSelectionMode)
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[600]),
                onPressed: _exitSelectionMode,
                tooltip: 'Tutup Mode Seleksi',
              )
            else if (waterHistory.isNotEmpty)
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withAlpha(25), // 0.1 opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                tooltip: 'Menu Opsi',
                elevation: 12,
                shadowColor: _primaryColor.withAlpha(76), // 0.3 opacity
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _primaryColor.withAlpha(25), // 0.1 opacity
                    width: 1,
                  ),
                ),
                color: Colors.white,
                offset: const Offset(0, 8),
                splashRadius: 20,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'select_items',
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryColor.withAlpha(25), // 0.1 opacity
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.checklist_rounded,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pilih Item',
                                  style: TextStyle(
                                    color: _textPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pilih untuk menghapus',
                                  style: TextStyle(
                                    color: _textSecondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _primaryColor.withAlpha(153), // 0.6 opacity
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Opsi refresh jika masih diperlukan
                  // PopupMenuItem<String>(
                  //   value: 'refresh',
                  //   child: Text('Muat Ulang Data'),
                  // ),
                ],
                onSelected: (String value) {
                  switch (value) {
                    case 'select_items':
                      if (waterHistory.isNotEmpty) {
                        _enterSelectionMode();
                      }
                      break;
                    case 'refresh':
                      refresh();
                       _showAddedWaterPopup(
                        context,
                        0,
                        customMessage: "Data berhasil dimuat ulang.",
                        isSuccess: true,
                      );
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView( // Untuk layar kecil agar bisa di-scroll
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withAlpha(25), // 0.1 opacity
                    _primaryColor.withAlpha(51)  // 0.2 opacity
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Lottie.asset('assets/loading.json', width: 180, height: 180), // Sedikit kecilkan
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
        color: isSelected ? _primaryColor.withAlpha(25) : _surfaceColor, // 0.1 opacity for selected
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withAlpha(20), // 0.08 opacity
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? _primaryColor : _primaryColor.withAlpha(25), // 0.1 opacity for border
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _primaryColor.withAlpha(25), // 0.1 opacity
          highlightColor: _primaryColor.withAlpha(12), // 0.05 opacity
          onTap: () {
            if (_isSelectionMode && item.id != null) {
              _toggleItemSelection(item.id!);
            } else if (!_isSelectionMode) {
              // Aksi jika tidak dalam mode seleksi (misal: edit item, tapi tidak diimplementasikan di sini)
              // print("Item tapped: ${item.id}");
            }
          },
          onLongPress: () {
            if (!_isSelectionMode && item.id != null && waterHistory.isNotEmpty) {
              _enterSelectionMode();
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
                if (_isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? _primaryColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withAlpha(25), // 0.1 opacity
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/glass.svg', // Pastikan path ini benar
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
                      Text(
                        "${item.jumlahHidrasi.toInt()} mL",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
                        ),
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
                          color: _primaryColor.withAlpha(12), // 0.05 opacity
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
    final String time = item.waktuHidrasi; // Asumsi format HH:mm
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

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
                  : waterHistory.isEmpty && errorMessage == null // Hanya tampilkan empty state jika tidak ada error dan tidak loading
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: waterHistory.length,
                          itemBuilder: (context, index) =>
                              _buildWaterIntakeItem(waterHistory[index]),
                        ),
            ),
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0,8.0,16.0,16.0), // Sesuaikan padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Beri jarak merata
                  children: [
                    Expanded( // Tombol agar bisa mengambil lebar yang tersedia
                      child: ElevatedButton.icon(
                        icon: Icon(
                          _selectedItems.length == waterHistory.length && waterHistory.isNotEmpty
                              ? Icons.deselect_outlined // Lebih jelas jika ada item
                              : Icons.select_all_outlined,
                          color: _primaryColor,
                        ),
                        label: Text(
                          _selectedItems.length == waterHistory.length && waterHistory.isNotEmpty
                              ? "Batal Semua"
                              : "Pilih Semua",
                          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor.withAlpha(30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, // Padding horizontal bisa lebih kecil
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _primaryColor.withAlpha(80))
                          ),
                          elevation: 0,
                        ),
                        onPressed: waterHistory.isEmpty ? null : _selectAllItems, // Disable jika tidak ada histori
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded( // Tombol agar bisa mengambil lebar yang tersedia
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                        label: Text(
                           _selectedItems.isEmpty
                              ? "Hapus" // Teks default jika tidak ada yang dipilih
                              : "Hapus (${_selectedItems.length})",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedItems.isEmpty ? Colors.grey.shade400 : Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                           elevation: _selectedItems.isEmpty ? 0 : 2,
                        ),
                        onPressed: _selectedItems.isEmpty ? null : _deleteSelectedItems,
                      ),
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
    _eventSubscription?.cancel();
    // Dispose semua AnimationController yang aktif
    for (var controller in _activeAnimationControllers) {
      controller.dispose();
    }
    _activeAnimationControllers.clear();
    super.dispose();
  }
}
