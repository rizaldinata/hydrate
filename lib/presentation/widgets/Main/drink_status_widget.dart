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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return Row(
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
              "${widget.formatTime(widget.remainingTime)}",
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
      if (mounted && widget.isCountdownActive && widget.remainingTime.inSeconds > 0) {
        setState(() {
          _showFullMessage = false;
        });
        // Notify parent widget about status change
        widget.onStatusChange?.call();
      }
    });
  }

  // Method untuk memulai animasi setelah minum
  void startDrinkAnimation() {
    setState(() {
      _showFullMessage = true;
    });
    
    // Start timer untuk menutup setelah 5 detik
    _startCloseTimer();
  }

  @override
  void initState() {
    super.initState();
    _lastIntake = widget.currentIntake;
  }

  @override
  void didUpdateWidget(DrinkStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Deteksi jika ada perubahan intake (user minum)
    bool intakeChanged = widget.currentIntake != _lastIntake;
    _lastIntake = widget.currentIntake;
    
    // Jika countdown baru dimulai (dari tidak aktif menjadi aktif) atau intake berubah
    if ((!oldWidget.isCountdownActive && widget.isCountdownActive) || intakeChanged) {
      startDrinkAnimation();
    }
    
    // Reset jika countdown berhenti
    if (oldWidget.isCountdownActive && !widget.isCountdownActive) {
      _messageTimer?.cancel();
      setState(() {
        _showFullMessage = true;
      });
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
                      const Color(0xFF4EE9BD),
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
              if (!(widget.isCountdownActive && widget.remainingTime.inSeconds > 0) || 
                  (widget.isCountdownActive && _showFullMessage)) ...[
                Container(
                  // width: 24,
                  // height: 24,
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  // Gunakan icon jam untuk countdown aktif, icon drink untuk status minum
                  child: (widget.isCountdownActive && widget.remainingTime.inSeconds > 0)
                      ? Icon(Icons.access_time, color: Colors.white,size: 16,)
                      : Icon(Icons.local_drink, color: Colors.white,size: 16,),
                  
                ),
                const SizedBox(width: 8),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                  _getStatusMessage(),
                  key: ValueKey(_getStatusMessage()),
                ),
        
            ],
          ),
        ),
      ),
    );
  }
}