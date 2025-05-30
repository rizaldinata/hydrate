import 'dart:async';
import 'package:flutter/material.dart';

class DrinkStatusWidget extends StatefulWidget {
  final bool isCountdownActive;
  final Duration remainingTime;
  final int currentIntake;
  final double screenHeight;
  final Function(Duration) formatTime;
  final VoidCallback? onStatusChange; // Callback untuk memberitahu parent widget

  const DrinkStatusWidget({
    Key? key,
    required this.isCountdownActive,
    required this.remainingTime,
    required this.currentIntake,
    required this.screenHeight,
    required this.formatTime,
    this.onStatusChange,
  }) : super(key: key);

  @override
  State<DrinkStatusWidget> createState() => _DrinkStatusWidgetState();
}

class _DrinkStatusWidgetState extends State<DrinkStatusWidget> {
  bool _showFullMessage = true;
  Timer? _messageTimer;
  int _lastIntake = 0; // Untuk tracking perubahan intake

  // Method untuk mendapatkan pesan status dengan animasi
  Widget _getStatusMessage() {
    if (widget.isCountdownActive && widget.remainingTime.inSeconds > 0) {
      if (_showFullMessage) {
        return Text(
          "${widget.formatTime(widget.remainingTime)} Hidrasi selanjutnya",
          key: const ValueKey('full_message'), // Tambahkan key untuk AnimatedSwitcher
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return Row(
          key: const ValueKey('short_message'), // Tambahkan key untuk AnimatedSwitcher
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFF07BAE4),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.formatTime(widget.remainingTime),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }
    } else {
      return const Text(
        "SAATNYA MINUM !",
        key: ValueKey('drink_now_message'), // Tambahkan key untuk AnimatedSwitcher
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  // Method untuk handle klik pada tampilan
  void _handleTap() {
    // Hanya toggle jika countdown aktif dan sedang menampilkan format singkat
    if (widget.isCountdownActive &&
        widget.remainingTime.inSeconds > 0 &&
        !_showFullMessage) {
      setState(() {
        _showFullMessage = true;
      });

      // Notify parent widget about status change
      widget.onStatusChange?.call();

      // Start timer untuk menutup kembali setelah 5 detik
      _startCloseTimer();
    }
  }

  // Method untuk memulai timer penutupan
  void _startCloseTimer() {
    // Cancel timer sebelumnya jika ada
    _messageTimer?.cancel();

    // Start timer untuk menyembunyikan bagian "Hidrasi selanjutnya" setelah 5 detik
    _messageTimer = Timer(const Duration(seconds: 5), () {
      if (mounted &&
          widget.isCountdownActive &&
          widget.remainingTime.inSeconds > 0) {
        setState(() {
          _showFullMessage = false;
        });
        // Notify parent widget about status change
        widget.onStatusChange?.call();
      }
    });
  }

  // Method untuk memulai animasi setelah minum atau countdown dimulai
  void startDrinkAnimation() {
    if (mounted) { // Pastikan widget masih mounted
      setState(() {
        _showFullMessage = true;
      });
      // Start timer untuk menutup setelah 5 detik, hanya jika countdown aktif
      if (widget.isCountdownActive && widget.remainingTime.inSeconds > 0) {
        _startCloseTimer();
      }
    }
  }

  /// [NEW METHOD]
  /// Panggil method ini dari parent widget sebelum navigasi untuk menutup pesan.
  void collapseMessageOnNavigate() {
    if (mounted &&
        widget.isCountdownActive &&
        widget.remainingTime.inSeconds > 0 &&
        _showFullMessage) {
      _messageTimer?.cancel(); // Batalkan timer yang mungkin akan membuka/menutup lagi
      setState(() {
        _showFullMessage = false;
      });
      // Anda bisa mempertimbangkan memanggil widget.onStatusChange?.call();
      // jika parent perlu tahu tentang perubahan ini,
      // namun karena ini dipicu oleh parent, mungkin tidak perlu.
    }
  }


  @override
  void initState() {
    super.initState();
    _lastIntake = widget.currentIntake;
    // Jika countdown sudah aktif saat widget pertama kali dibuat
    if (widget.isCountdownActive && widget.remainingTime.inSeconds > 0) {
        // Awalnya tampilkan pesan singkat jika diinginkan, atau biarkan full dan timer akan menutupnya.
        // Untuk kasus ini, kita biarkan _showFullMessage = true (default)
        // dan _startCloseTimer akan dipanggil di didUpdateWidget jika kondisi terpenuhi,
        // atau jika user minum.
        // Jika ingin langsung singkat saat init:
        // _showFullMessage = false;
        // Namun, lebih konsisten jika startDrinkAnimation yang mengaturnya.
        // Jika widget dimulai dengan countdown aktif, kita mungkin ingin langsung memulai animasi juga.
        startDrinkAnimation();
    } else if (!widget.isCountdownActive) {
        // Jika dimulai dengan "SAATNYA MINUM!"
        _showFullMessage = true;
    }
  }

  @override
  void didUpdateWidget(DrinkStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool intakeChanged = widget.currentIntake != _lastIntake;
    

    // Deteksi jika countdown baru dimulai (dari tidak aktif menjadi aktif)
    bool countdownJustStarted = !oldWidget.isCountdownActive && widget.isCountdownActive;

    if (countdownJustStarted || intakeChanged) {
      _lastIntake = widget.currentIntake; // Update _lastIntake di sini agar lebih akurat
      startDrinkAnimation();
    }

    // Reset jika countdown berhenti (misalnya, timer habis dan belum minum)
    // Atau jika menjadi tidak aktif karena alasan lain.
    if (oldWidget.isCountdownActive && !widget.isCountdownActive) {
      _messageTimer?.cancel();
      if (mounted) { // Pastikan widget masih mounted
        setState(() {
          _showFullMessage = true; // Tampilkan "SAATNYA MINUM!"
        });
      }
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.screenHeight * 0.22, // Adjust this value to position above circle
      right: 0, // Menempel ke sisi kanan
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: (widget.isCountdownActive && widget.remainingTime.inSeconds > 0)
                  ? [
                      const Color(0xFF2AD1D1),
                      const Color(0xFF07BAE4),
                    ]
                  : [
                      const Color(0xFF4EE9BD), // Warna berbeda saat "SAATNYA MINUM!"
                      const Color(0xFF07BAE4),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              bottomLeft: Radius.circular(25),
              topRight: Radius.circular(0), // Tidak ada radius di kanan atas
              bottomRight: Radius.circular(0), // Tidak ada radius di kanan bawah
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07BAE4).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(-2, 4), // Shadow ke kiri karena menempel kanan
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon hanya tampil untuk status tertentu
              // Kondisi untuk icon:
              // 1. Tampil jika BUKAN countdown aktif (berarti "SAATNYA MINUM")
              // 2. ATAU jika countdown aktif DAN pesan penuh ditampilkan
              if (!(widget.isCountdownActive && widget.remainingTime.inSeconds > 0) ||
                  (widget.isCountdownActive && widget.remainingTime.inSeconds > 0 && _showFullMessage)) ...[
                Container(
                  decoration: BoxDecoration(
                    // color: Colors.white, // Tidak perlu background lagi jika icon sudah putih
                    borderRadius: BorderRadius.circular(50),
                  ),
                  // Gunakan icon jam untuk countdown aktif (pesan penuh), icon drink untuk status minum
                  child: (widget.isCountdownActive && widget.remainingTime.inSeconds > 0)
                      ? const Icon(Icons.access_time, color: Colors.white, size: 16)
                      : const Icon(Icons.local_drink, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal, // Atau Axis.vertical sesuai preferensi
                      axisAlignment: -1.0, // Mulai dari kiri
                      child: child,
                    ),
                  );
                },
                child: _getStatusMessage(), // Key sudah diatur di dalam _getStatusMessage
              ),
            ],
          ),
        ),
      ),
    );
  }
}
