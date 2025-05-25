import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/presentation/controllers/riwayat_hidrasi_controller.dart';
import 'package:hydrate/core/utils/app_event_bus.dart';
import 'package:hydrate/locator.dart';
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
  final RiwayatHidrasiController _riwayatController = RiwayatHidrasiController();

  bool isLoading = true;
  int? userId;
  String? errorMessage;
  StreamSubscription? _eventSubscription;
  final _eventBus = AppEventBus();
  Timer? _undoTimer;

  List<RiwayatHidrasi> _lastBatchDeletedItems = [];
  
  // Mode seleksi
  bool _isSelectionMode = false;
  Set<String> _selectedItems = HashSet<String>();

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
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final sessionManager = locator<SessionManager>();
      userId = await sessionManager.getUserId();
      if (userId != null) {
        await _loadRiwayatHidrasi(today);
      } else {
        setState(() { errorMessage = "Pengguna tidak teridentifikasi"; });
      }
    } catch (e) {
      setState(() { errorMessage = "Gagal memuat data: $e"; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _loadRiwayatHidrasi(DateTime dateToLoad) async {
    if (userId == null) return;
    setState(() { isLoading = true; errorMessage = null; });

    try {
      List<RiwayatHidrasi> history =
          await _riwayatController.getRiwayatHidrasiByTanggal(userId!, dateToLoad);
      if (mounted) {
        setState(() {
          waterHistory = _riwayatController.sortRiwayatByWaktuDescending(history);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { errorMessage = "Kesalahan saat memuat riwayat: $e"; });
      }
    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
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
  void _toggleItemSelection(String syncId) { // Ubah parameter ke String syncId
    setState(() {
      if (_selectedItems.contains(syncId)) {
        _selectedItems.remove(syncId);
      } else {
        _selectedItems.add(syncId);
      }
      // Jika tidak ada item yang dipilih, keluar dari mode seleksi
      if (_selectedItems.isEmpty && _isSelectionMode) {
          _exitSelectionMode(); 
      }
    });
  }

  void _enterSelectionMode() {
    setState(() { _isSelectionMode = true; });
  }

  void _exitSelectionMode() {
    setState(() { _isSelectionMode = false; _selectedItems.clear(); });
  }
  
  // Pilih semua item
  void _selectAllItems() {
    setState(() {
      if (_selectedItems.length == waterHistory.length && waterHistory.isNotEmpty) {
        _selectedItems.clear();
      } else {
        _selectedItems.clear();
        for (var item in waterHistory) {
          if (item.syncId != null) { // Pastikan syncId ada
            _selectedItems.add(item.syncId!);
          }
        }
      }
    });
  }

  // Hapus item yang dipilih
  Future<void> _deleteSelectedItems() async {
    if (_selectedItems.isEmpty || userId == null) return;
    
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
    ) ?? false;

    if (confirm != true) return;

    _lastBatchDeletedItems.clear();
    for (var syncId in _selectedItems) {
      final item = waterHistory.firstWhere((element) => element.syncId == syncId, orElse: () => RiwayatHidrasi(jumlahHidrasi: 0, fkIdPengguna: userId!)); // orElse untuk keamanan
      if(item.syncId != null) _lastBatchDeletedItems.add(item);
    }
    
    // Hapus dari tampilan
    setState(() {
      waterHistory.removeWhere((item) => item.syncId != null && _selectedItems.contains(item.syncId!));
      // _selectedItems.clear(); // Jangan clear dulu, biarkan user melihat apa yang dihapus
      // _isSelectionMode = false; // Jangan keluar dari mode seleksi dulu
    });

    // Tampilkan notifikasi dengan opsi batalkan
    _showSnackBarNotification(
      message: _lastBatchDeletedItems.length == 1
          ? "1 catatan hidrasi telah dihapus"
          : "${_lastBatchDeletedItems.length} catatan hidrasi telah dihapus",
      actionLabel: "BATALKAN",
      onAction: () {
        setState(() {
          waterHistory.addAll(_lastBatchDeletedItems);
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
    _undoTimer = Timer(const Duration(seconds: 4), () async {
      if (_lastBatchDeletedItems.isNotEmpty) {
        for (var itemToDelete in _lastBatchDeletedItems) {
          if (itemToDelete.syncId != null) {
            await _riwayatController.hapusRiwayatDanUpdateTotal( 
              riwayatSyncId: itemToDelete.syncId!,
              idPengguna: userId!,
              tanggalHidrasi: itemToDelete.tanggalHidrasi ?? DateFormat('yyyy-MM-dd').format(today),
            );
          } 
        }
        _lastBatchDeletedItems.clear();
        if(mounted) {
             setState(() {
                _selectedItems.clear();
                _isSelectionMode = false;
            });
        }
      }
    });
  }

Widget _buildItemCard(RiwayatHidrasi item, String time, bool isSmallScreen, double screenWidth) {
  final String itemKey = item.syncId ?? item.id?.toString() ?? UniqueKey().toString();
  final bool isSelected = item.syncId != null && _selectedItems.contains(item.syncId!);

  return Container(
    key: ValueKey(itemKey),
    height: 56,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isSelected ? _accentColor : _surfaceColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [  
        BoxShadow(
          color: _primaryColor.withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode && item.syncId != null) {
            _toggleItemSelection(item.syncId!);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode && item.syncId != null) {
            _enterSelectionMode();
            _toggleItemSelection(item.syncId!);
          }
        },
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
                    _isSelectionMode
                        ? "Pilih item"
                        : item.jumlahHidrasi.toString(),
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
                  _primaryColor.withValues(alpha: 0.1),
                  _primaryColor.withValues(alpha: 0.2)
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

  Widget _buildTodayHeader() {
    final String dateTitle = "Hari Ini"; // Karena layar ini difokuskan untuk hari ini

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1),
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

  Widget _buildWaterIntakeItem(RiwayatHidrasi item) {
    final String time = item.waktuHidrasi ?? "00:00";
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    final String itemKey = item.syncId ?? item.id?.toString() ?? UniqueKey().toString();

    // Tetap mempertahankan fitur swipe-to-delete namun juga menambahkan tombol hapus langsung
    return Dismissible(
      key: Key(itemKey),
      background: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent.shade200, Colors.red.shade800],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: screenWidth * 0.06),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Hapus",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: isSmallScreen ? 22 : 26,
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
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
              "Apakah kamu yakin menghapus catatan ${item.jumlahHidrasi.toInt()} mL ini?",
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
      },
      onDismissed: (direction) {
        _lastBatchDeletedItems = [item];
        setState(() => waterHistory.remove(item));

        _showSnackBarNotification(
          message: "Catatan hidrasi telah dihapus",
          actionLabel: "BATALKAN",
          onAction: () {
            if (_lastBatchDeletedItems.isNotEmpty) {
              final itemToRestore = _lastBatchDeletedItems.first;
              setState(() {
                waterHistory.add(itemToRestore);
                waterHistory = _riwayatController.sortRiwayatByWaktuDescending(waterHistory);
              });
              _lastBatchDeletedItems.clear();
              _showSnackBarNotification(
                message: "Catatan telah dipulihkan",
                duration: const Duration(seconds: 2),
                isSuccess: true,
              );
            }
          },
        );

        _undoTimer = Timer(const Duration(seconds: 4), () async {
          if (_lastBatchDeletedItems.isNotEmpty) {
            final itemToDelete = _lastBatchDeletedItems.first;
            if (itemToDelete.syncId != null && userId != null) {
              await _riwayatController.hapusRiwayatDanUpdateTotal(
                riwayatSyncId: itemToDelete.syncId!,
                idPengguna: userId!,
                tanggalHidrasi: itemToDelete.tanggalHidrasi ?? DateFormat('yyyy-MM-dd').format(today),
              );
            }
            _lastBatchDeletedItems.clear();
          }
        });
      },
      child: _buildItemCard(item, time, isSmallScreen, screenWidth),
    );
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