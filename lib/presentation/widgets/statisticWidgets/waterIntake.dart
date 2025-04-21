import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrate/data/models/riwayat_hidrasi_model.dart';
import 'dart:math';

class WaterIntakeItemWidget extends StatelessWidget {
  final RiwayatHidrasi item;
  final Function(RiwayatHidrasi) onDelete;
  final Color primaryColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color surfaceColor;
  
  const WaterIntakeItemWidget({
    Key? key,
    required this.item,
    required this.onDelete,
    required this.primaryColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.surfaceColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String time = item.waktuHidrasi ?? "00:00";
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    
    return Dismissible(
      key: Key(item.id.toString()),
      background: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, // 4% of screen width
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.redAccent.shade200,
              Colors.red.shade800,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: screenWidth * 0.06), // 6% of screen width
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
        return await showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Dismiss",
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, anim1, anim2) {
            final double dialogWidth = screenWidth * 0.85;
            final double maxDialogWidth = 450;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, // 5% of screen width
                vertical: 24,
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  const Text("Konfirmasi Hapus"),
                ],
              ),
              content: Container(
                constraints: BoxConstraints(
                  maxWidth: min(dialogWidth, maxDialogWidth),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Anda yakin ingin menghapus catatan hidrasi ${item.jumlahHidrasi.toInt()} mL ini?",
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: textPrimaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tindakan ini tidak dapat dibatalkan.",
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: textSecondaryColor),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actionsPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // 4% of screen width
                vertical: 12,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: textSecondaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05, // 5% of screen width
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "BATAL", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05, // 5% of screen width
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "HAPUS", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ],
            );
          },
          transitionBuilder: (context, anim1, anim2, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                child: child,
              ),
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete(item);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, // 4% of screen width
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: primaryColor.withOpacity(0.1),
            highlightColor: primaryColor.withOpacity(0.05),
            onTap: () {
              // Handling tap if needed
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // 4% of screen width
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/glass.svg',
                      width: isSmallScreen ? 24 : 32,
                      height: isSmallScreen ? 24 : 32,
                      colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
                    ),
                  ),

                  SizedBox(width: screenWidth * 0.03), // 3% of screen width

                  // Water Amount with responsive layout
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
                                color: textPrimaryColor,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 8),
                            // Responsive visual indicator
                            LayoutBuilder(builder: (context, constraints) {
                              // Calculate number of dots based on container width
                              final int maxDots = isSmallScreen ? 3 : 5;
                              final int dots = min(
                                (item.jumlahHidrasi / 100).clamp(1, maxDots).toInt(),
                                maxDots
                              );
                              
                              return Row(
                                children: List.generate(
                                  dots,
                                  (index) => Container(
                                    margin: const EdgeInsets.only(right: 2),
                                    width: isSmallScreen ? 4 : 6,
                                    height: isSmallScreen ? 4 : 6,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        Text(
                          "Konsumsi Air",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        
                        // Responsive time badge
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: isSmallScreen ? 12 : 14,
                                color: primaryColor,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hint icon for swipe action
                  Icon(
                    Icons.chevron_left,
                    color: textSecondaryColor.withOpacity(0.5),
                    size: isSmallScreen ? 18 : 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}