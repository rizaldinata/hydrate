import 'package:flutter/material.dart';

class NotificationOverlayService {
  OverlayEntry? _overlayEntry;
  bool _isOverlayShown = false;

  // Method untuk menampilkan overlay notification
  void showOverlayNotification({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    bool isSuccess = false,
    bool showAction = true,
    Color primaryColor = const Color(0xFF00A6FB),
  }) {
    // Jika overlay sudah ditampilkan, hapus terlebih dahulu
    hideOverlay();
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    
    // Create the overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 16 + MediaQuery.of(context).padding.top, // Allow some space for status bar
          left: screenWidth * 0.05,
          right: screenWidth * 0.05,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.shade600 : primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess ? Colors.green.shade600 : primaryColor).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess ? Icons.check : Icons.info_outline,
                        color: Colors.white,
                        size: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showAction && actionLabel != null && onAction != null)
                      TextButton(
                        onPressed: () {
                          hideOverlay();
                          onAction();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    // Show the overlay entry
    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayShown = true;
    
    // Auto-hide after duration
    Future.delayed(duration, () {
      hideOverlay();
    });
  }

  // Method untuk menghilangkan overlay
  void hideOverlay() {
    if (_isOverlayShown && _overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isOverlayShown = false;
    }
  }

  // Getter untuk cek apakah overlay sedang ditampilkan
  bool get isShowing => _isOverlayShown;
}