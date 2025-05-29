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
    Duration duration = const Duration(seconds: 3),
    bool isSuccess = false,
  }) {
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      duration: duration,
      backgroundColor: isSuccess ? Colors.green.shade600 : _accentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(10),
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

    // Simpan item yang akan dihapus untuk operasi backend
    List<RiwayatHidrasi> itemsToDeletePermanently = [];
    for (var item in waterHistory) {
      if (item.id != null && _selectedItems.contains(item.id)) {
        itemsToDeletePermanently.add(item);
      }
    }

    // Hapus dari tampilan (UI) terlebih dahulu untuk responsivitas
    setState(() {
      waterHistory.removeWhere(
          (item) => item.id != null && _selectedItems.contains(item.id));
      _selectedItems.clear();
      _isSelectionMode = false;
    });

    // Lakukan penghapusan permanen di backend
    if (userId != null && itemsToDeletePermanently.isNotEmpty) {
      print(
          "Melakukan penghapusan permanen untuk ${itemsToDeletePermanently.length} item...");
      bool allSucceeded = true;
      for (var item in itemsToDeletePermanently) {
        try {
          await _controller.hapusRiwayatDanKurangiTarget(
            idRiwayat: item.id ?? 0,
            idPengguna: userId!,
            tanggalHidrasi: item.tanggalHidrasi ?? "",
            targetController: targetHidrasiController,
          );
          print("Berhasil menghapus permanen item ID: ${item.id}");
        } catch (e) {
          allSucceeded = false;
          print("Gagal menghapus permanen item ID: ${item.id}. Error: $e");
        }
      }

      if (allSucceeded) {
        _showSnackBarNotification(
          message: itemsToDeletePermanently.length == 1
              ? "1 catatan hidrasi telah dihapus"
              : "${itemsToDeletePermanently.length} catatan hidrasi telah dihapus",
          isSuccess: true,
        );
      } else {
         _showSnackBarNotification(
          message: "Beberapa catatan gagal dihapus dari server.",
          isSuccess: false,
        );
      }
      _eventBus.fire('refresh_all');
    } else {
      _showSnackBarNotification(
          message: "Tidak ada item yang dihapus dari server.",
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
            if (_isSelectionMode)
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[600]),
                onPressed: _exitSelectionMode,
                tooltip: 'Tutup',
              )
            else if (waterHistory.isNotEmpty)
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
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
                shadowColor: _primaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _primaryColor.withOpacity(0.1),
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
                              color: _primaryColor.withOpacity(0.1),
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
                            color: _primaryColor.withOpacity(0.6),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      _showSnackBarNotification(
                        message: "Data berhasil dimuat ulang",
                        isSuccess: true,
                        duration: const Duration(seconds: 2),
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
            }
          },
          onLongPress: () {
            if (!_isSelectionMode && item.id != null) {
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
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
    _eventSubscription?.cancel();
    super.dispose();
  }
}