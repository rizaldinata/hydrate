import 'package:flutter/material.dart';
import 'dart:math' as math;

// Enum untuk status progres (tetap sama)
enum ProgressState {
  empty,
  normal,
  exceeded,
  critical,
}

class AnimatedWaterProgressCircle extends StatefulWidget {
  final double currentIntake;
  final double target;
  final double screenWidth;

  const AnimatedWaterProgressCircle({
    Key? key,
    required this.currentIntake,
    required this.target,
    required this.screenWidth,
  }) : super(key: key);

  @override
  State<AnimatedWaterProgressCircle> createState() =>
      _AnimatedWaterProgressCircleState();
}

class _AnimatedWaterProgressCircleState extends State<AnimatedWaterProgressCircle>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _exclamationMarkMovementController; // Hanya untuk gerakan tanda seru
  late AnimationController _progressDisplayController;  // Untuk animasi persentase progres

  // Animations
  late Animation<double> _waveAnimation;
  late Animation<double> _exclamationMarkMovementAnimation;
  late Animation<double> _progressDisplayAnimation;

  double _currentAnimatedProgressPercent = 0.0;
  final double _arcStrokeWidth = 15.0;

  @override
  void initState() {
    super.initState();
    _setupWaveAnimation();
    _setupProgressDisplayAnimation();
    _setupEmptyStateAnimations(); // Sekarang hanya untuk tanda seru
    _updateAnimationPlaybackBasedOnState();
  }

  void _setupWaveAnimation() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));
  }

  void _setupProgressDisplayAnimation() {
    _progressDisplayController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    final initialProgressPercent = widget.target > 0
        ? (widget.currentIntake / widget.target * 100)
        : 0.0;
    _currentAnimatedProgressPercent = math.min(100.0, math.max(0.0, initialProgressPercent));
    _progressDisplayAnimation = Tween<double>(
      begin: _currentAnimatedProgressPercent,
      end: _currentAnimatedProgressPercent,
    ).animate(CurvedAnimation(
      parent: _progressDisplayController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _setupEmptyStateAnimations() {
    // Animasi gerakan tanda seru
    _exclamationMarkMovementController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Durasi untuk satu siklus kiri-kanan
      vsync: this,
    );
    _exclamationMarkMovementAnimation = Tween<double>(begin: -6.0, end: 6.0) // Jarak pergerakan
        .animate(CurvedAnimation(
      parent: _exclamationMarkMovementController,
      curve: Curves.easeInOutSine,
    ));
  }

  void _updateAnimationPlaybackBasedOnState() {
    final progressState = _getProgressState();

    if (progressState == ProgressState.empty) {
      if (!_exclamationMarkMovementController.isAnimating) {
        _exclamationMarkMovementController.repeat(reverse: true);
      }
      if (_waveController.isAnimating) _waveController.stop();
    } else {
      if (_exclamationMarkMovementController.isAnimating) {
        _exclamationMarkMovementController.stop();
        _exclamationMarkMovementController.reset();
      }
      if (progressState != ProgressState.critical) {
        if (!_waveController.isAnimating) _waveController.repeat();
      } else {
        if (_waveController.isAnimating) _waveController.stop();
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedWaterProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgressPercent = widget.target > 0
        ? (widget.currentIntake / widget.target * 100)
        : 0.0;
    final cappedNewProgressPercent = math.min(100.0, math.max(0.0, newProgressPercent));

    if ((cappedNewProgressPercent - _currentAnimatedProgressPercent).abs() > 0.01) {
      _progressDisplayAnimation = Tween<double>(
        begin: _currentAnimatedProgressPercent,
        end: cappedNewProgressPercent,
      ).animate(CurvedAnimation(
        parent: _progressDisplayController,
        curve: Curves.easeInOutCubic,
      ));
      _progressDisplayController.forward(from: 0.0);
      _currentAnimatedProgressPercent = cappedNewProgressPercent;
    } else if (cappedNewProgressPercent != _currentAnimatedProgressPercent) {
       _currentAnimatedProgressPercent = cappedNewProgressPercent;
       if (!_progressDisplayController.isAnimating) {
          _progressDisplayAnimation = ConstantTween<double>(cappedNewProgressPercent)
              .animate(_progressDisplayController);
          // Mungkin perlu setState() jika teks tidak update otomatis,
          // tapi AnimatedBuilder seharusnya menangani ini.
       }
    }
    _updateAnimationPlaybackBasedOnState();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _exclamationMarkMovementController.dispose();
    _progressDisplayController.dispose();
    super.dispose();
  }

  ProgressState _getProgressState() {
    if (widget.target <= 0) return ProgressState.empty;
    if (widget.currentIntake <= 0) return ProgressState.empty;
    if (widget.currentIntake > 2 * widget.target) return ProgressState.critical;
    if (widget.currentIntake > widget.target) return ProgressState.exceeded;
    return ProgressState.normal;
  }

  // Warna untuk teks persentase
  Color _getPercentageTextColor(ProgressState state) {
    if (state == ProgressState.empty) return Colors.transparent;
    switch (state) {
      case ProgressState.critical: return Colors.red.shade700;
      case ProgressState.exceeded: return Colors.orange.shade700;
      default: return const Color(0xFF003D7A); // Biru tua
    }
  }

  // Warna untuk teks "currentIntake"
  Color _getCurrentIntakeValueColor(ProgressState state) {
    if (state == ProgressState.empty) return Colors.transparent;

    // Jika target belum tercapai (dan bukan kondisi empty)
    if (widget.currentIntake < widget.target && widget.target > 0 && state == ProgressState.normal) {
      return Colors.red.shade600; // Warna merah jika target belum terpenuhi
    }

    // Warna berdasarkan state jika target sudah terpenuhi atau kondisi khusus
    switch (state) {
      case ProgressState.critical: return Colors.red.shade800;
      case ProgressState.exceeded: return Colors.orange.shade700;
      case ProgressState.normal: // Target terpenuhi
        return const Color(0xFF007ACC); // Warna biru "sukses"
      default: return const Color(0xFF005A8D); // Fallback
    }
  }

  // Warna untuk teks "/ target mL"
  Color _getTargetUnitTextColor(ProgressState state) {
    if (state == ProgressState.empty) return Colors.transparent;
     switch (state) {
      case ProgressState.critical: return Colors.red.shade600.withOpacity(0.8);
      case ProgressState.exceeded: return Colors.orange.shade600.withOpacity(0.8);
      default: return const Color(0xFF005A8D).withOpacity(0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressState = _getProgressState();

    return Padding(
      padding: EdgeInsets.all(widget.screenWidth * 0.05),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _progressDisplayController,
              _waveController,
              _exclamationMarkMovementController,
            ]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: CircleBackgroundPainter(
                        progressState: progressState,
                        strokeWidth: _arcStrokeWidth),
                    size: Size.infinite,
                  ),
                  progressState == ProgressState.empty
                      ? _buildEmptyStateVisuals()
                      : _buildWaterVisuals(progressState),
                  CustomPaint(
                    painter: ProgressArcPainter(
                      progress: _progressDisplayAnimation.value,
                      startAngleDegrees: -90,
                      sweepAngleDegrees: 360,
                      progressState: progressState,
                      strokeWidth: _arcStrokeWidth,
                    ),
                    size: Size.infinite,
                  ),
                  _buildCentralTextContent(progressState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCentralTextContent(ProgressState progressState) {
    if (progressState == ProgressState.empty) {
      return Container(); 
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_progressDisplayAnimation.value.ceil()}%',
          style: TextStyle(
            color: _getPercentageTextColor(progressState),
            fontWeight: FontWeight.w300,
            fontSize: widget.screenWidth * 0.12,
            fontFamily: 'Roboto',
          ),
        ),
        SizedBox(height: widget.screenWidth * 0.015),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${widget.currentIntake.toInt()}',
              style: TextStyle(
                color: _getCurrentIntakeValueColor(progressState), // Menggunakan warna baru
                fontWeight: FontWeight.w600,
                fontSize: widget.screenWidth * 0.05,
                fontFamily: 'Roboto',
              ),
            ),
            Text(
              ' / ${widget.target.toInt()} mL',
              style: TextStyle(
                color: _getTargetUnitTextColor(progressState), // Warna untuk unit target
                fontWeight: FontWeight.w400,
                fontSize: widget.screenWidth * 0.04,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterVisuals(ProgressState progressState) {
    return CustomPaint(
      painter: WaterWavePainter(
        wavePhase: _waveAnimation.value,
        waterLevel: widget.target > 0 ? widget.currentIntake / widget.target : 0.0,
        progressState: progressState,
        arcStrokeWidth: _arcStrokeWidth,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildEmptyStateVisuals() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gelas statis (sedikit miring)
        Transform.rotate(
          angle: -0.15, // Kemiringan statis yang lebih sedikit
          child: CustomPaint(
            painter: EmptyGlassPainter(screenWidth: widget.screenWidth),
            // Ukuran untuk painter gelas disesuaikan agar tidak terlalu besar
            size: Size(widget.screenWidth * 0.25, widget.screenWidth * 0.35), 
          ),
        ),
        // Tanda seru yang bergerak dan lebih besar
        Transform.translate(
          offset: Offset(_exclamationMarkMovementAnimation.value, -widget.screenWidth * 0.12), // Sesuaikan offset Y
          child: CustomPaint(
            painter: ExclamationPainter(screenWidth: widget.screenWidth, isLarge: true), // Tambah parameter isLarge
            // Ukuran canvas untuk painter tanda seru diperbesar
            size: Size(widget.screenWidth * 0.12, widget.screenWidth * 0.18), 
          ),
        ),
      ],
    );
  }
}

// --- PAINTERS ---

class CircleBackgroundPainter extends CustomPainter {
  // ... (Kode Painter ini tetap sama seperti sebelumnya) ...
  final ProgressState progressState;
  final double strokeWidth;

  CircleBackgroundPainter({required this.progressState, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    Color gradColorLight;
    Color gradColorDark;

    switch (progressState) {
      case ProgressState.critical:
        gradColorLight = Colors.red.shade100;
        gradColorDark = Colors.red.shade200;
        break;
      case ProgressState.exceeded:
        gradColorLight = Colors.orange.shade100;
        gradColorDark = Colors.orange.shade200;
        break;
      case ProgressState.empty:
        gradColorLight = Colors.grey.shade200;
        gradColorDark = Colors.grey.shade300;
        break;
      default: // normal
        gradColorLight = const Color(0xFFCDEBFF); 
        gradColorDark = const Color(0xFFA1D6FF); 
    }

    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [gradColorLight, gradColorDark],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CircleBackgroundPainter oldDelegate) =>
      oldDelegate.progressState != progressState || oldDelegate.strokeWidth != strokeWidth;
}

class ProgressArcPainter extends CustomPainter {
  final double progress; 
  final double startAngleDegrees;
  final double sweepAngleDegrees; 
  final ProgressState progressState;
  final double strokeWidth;

  ProgressArcPainter({
    required this.progress,
    required this.startAngleDegrees,
    required this.sweepAngleDegrees,
    required this.progressState,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Color solidProgressColor; // Warna solid untuk progres

    switch (progressState) {
      case ProgressState.critical:
        solidProgressColor = Colors.red.shade600; // Merah pekat
        break;
      case ProgressState.exceeded:
        solidProgressColor = Colors.orange.shade600; // Oranye pekat
        break;
      case ProgressState.empty: 
         return; // Jangan gambar progres jika kosong
      default: // normal
        solidProgressColor = const Color(0xFF007ACC);  // Biru solid
    }

    final progressPaint = Paint()
      ..color = solidProgressColor // Menggunakan warna solid
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; 

    // Hapus shader untuk gradien
    // progressPaint.shader = SweepGradient(...).createShader(rect);

    final startAngleRad = startAngleDegrees * (math.pi / 180);
    final currentSweepRad = (sweepAngleDegrees * progress / 100) * (math.pi / 180);

    if (currentSweepRad > 0.001) { 
      canvas.drawArc(
        rect,
        startAngleRad,
        currentSweepRad,
        false,
        progressPaint,
      );
    }

    // Indikator (seek) di ujung busur progres
    if (progress > 0 && progress < 100) { 
      final seekAngle = startAngleRad + currentSweepRad;
      final seekX = center.dx + radius * math.cos(seekAngle);
      final seekY = center.dy + radius * math.sin(seekAngle);

      final seekFillPaint = Paint()..color = Colors.white;
      final seekBorderPaint = Paint()
        ..color = solidProgressColor // Border warna sama dengan progres
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(seekX, seekY), strokeWidth * 0.25, seekFillPaint);
      canvas.drawCircle(Offset(seekX, seekY), strokeWidth * 0.25, seekBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressState != progressState ||
      oldDelegate.strokeWidth != strokeWidth;
}


class WaterWavePainter extends CustomPainter {
  // ... (Kode Painter ini tetap sama seperti sebelumnya) ...
  final double wavePhase;
  final double waterLevel; 
  final ProgressState progressState;
  final double arcStrokeWidth;


  WaterWavePainter({
    required this.wavePhase,
    required this.waterLevel,
    required this.progressState,
    required this.arcStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waterLevel <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2);
    final waterRadius = math.min(size.width, size.height) / 2 - arcStrokeWidth - 3.0; 

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);

    final cappedWaterLevelForDrawing = math.min(waterLevel, 1.5); 
    final waterSurfaceY = size.height * (1 - cappedWaterLevelForDrawing);


    Color gradLight, gradDark;
    switch (progressState) {
      case ProgressState.critical:
        gradLight = Colors.red.shade200;
        gradDark = Colors.red.shade400;
        break;
      case ProgressState.exceeded:
        gradLight = Colors.orange.shade200;
        gradDark = Colors.orange.shade400;
        break;
      default: 
        gradLight = const Color(0xFFA0E0FF); 
        gradDark = const Color(0xFF4AA8FF);  
    }

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradLight, gradDark],
        stops: const [0.2, 0.8],
      ).createShader(Rect.fromLTWH(0, waterSurfaceY - 20, size.width, size.height - (waterSurfaceY - 20)))
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    final amplitude = 5.0; 
    final frequency = 2.0; 

    wavePath.moveTo(0, waterSurfaceY); 
    for (double x = 0; x <= size.width; x++) {
      double yOffset;
      if (progressState == ProgressState.critical) {
        yOffset = 0; 
      } else {
        yOffset = amplitude * math.sin(frequency * x * (math.pi / 180) + wavePhase) +
                  amplitude * 0.4 * math.sin(frequency * 0.8 * x * (math.pi / 180) + wavePhase * 1.2 + math.pi / 4);
      }
      wavePath.lineTo(x, waterSurfaceY + yOffset);
    }
    wavePath.lineTo(size.width, size.height); 
    wavePath.lineTo(0, size.height);        
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);

    if (progressState != ProgressState.critical && waterLevel > 0.05) {
      final foamPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      final foamPath = Path();
      foamPath.moveTo(0, waterSurfaceY);
      for (double x = 0; x <= size.width; x+=2) {
         final yOffset = amplitude * 0.3 * math.sin(frequency * 1.5 * x * (math.pi / 180) + wavePhase * 1.5 + math.pi / 2) - 1.0;
         foamPath.lineTo(x, waterSurfaceY + yOffset);
      }
      canvas.drawPath(foamPath, foamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterWavePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.waterLevel != waterLevel ||
      oldDelegate.progressState != progressState ||
      oldDelegate.arcStrokeWidth != arcStrokeWidth;
}


class EmptyGlassPainter extends CustomPainter {
  final double screenWidth;
  EmptyGlassPainter({required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) { 
    final center = Offset(size.width / 2, size.height / 2);
    
    final glassWidth = size.width * 0.8; 
    final glassHeight = size.height * 0.9;
    final glassBaseHeight = glassHeight * 0.15;
    final glassRimHeight = 5.0;

    final glassFillPaint = Paint()
      ..color = const Color(0xFFD0EFFF).withOpacity(0.5) // Warna isi lebih transparan
      ..style = PaintingStyle.fill;

    final glassStrokePaint = Paint()
      ..color = const Color(0xFF87CEFA).withOpacity(0.7) // Warna outline lebih lembut
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Stroke lebih tipis

    final glassPath = Path()
      ..moveTo(center.dx - glassWidth / 2, center.dy - glassHeight / 2 + glassRimHeight) 
      ..lineTo(center.dx - glassWidth / 2 * 0.7, center.dy + glassHeight / 2 - glassBaseHeight) 
      ..quadraticBezierTo( 
          center.dx, center.dy + glassHeight / 2 + glassBaseHeight * 0.3, 
          center.dx + glassWidth / 2 * 0.7, center.dy + glassHeight / 2 - glassBaseHeight) 
      ..lineTo(center.dx + glassWidth / 2, center.dy - glassHeight / 2 + glassRimHeight); 

    canvas.drawPath(glassPath, glassFillPaint);
    canvas.drawPath(glassPath, glassStrokePaint);

    final rimRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - glassHeight / 2 + glassRimHeight / 2),
      width: glassWidth,
      height: glassRimHeight * 1.5,
    );
    canvas.drawOval(rimRect, glassStrokePaint..style = PaintingStyle.fill ..color = const Color(0xFFB0E0E6).withOpacity(0.6));
    canvas.drawOval(rimRect, glassStrokePaint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant EmptyGlassPainter oldDelegate) => oldDelegate.screenWidth != screenWidth;
}

class ExclamationPainter extends CustomPainter {
  final double screenWidth;
  final bool isLarge; // Tambahkan parameter ini

  ExclamationPainter({required this.screenWidth, this.isLarge = false});

  @override
  void paint(Canvas canvas, Size size) { 
    final paint = Paint()
      ..color = Colors.red.shade500 
      ..style = PaintingStyle.fill;

    // Sesuaikan ukuran berdasarkan isLarge
    final scaleFactor = isLarge ? 1.5 : 1.0; // Faktor skala jika isLarge true

    final barWidth = size.width * 0.35 * scaleFactor;
    final barHeight = size.height * 0.6 * scaleFactor;
    final dotRadius = size.width * 0.22 * scaleFactor;

    // Pastikan tidak melebihi bounds jika diperbesar
    final clampedBarHeight = math.min(barHeight, size.height * 0.7);
    final clampedDotRadius = math.min(dotRadius, size.width * 0.3);
    
    final barCenterY = size.height * 0.3;
    final dotCenterY = size.height * 0.82;


    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, barCenterY),
          width: barWidth,
          height: clampedBarHeight,
        ),
        Radius.circular(barWidth / 2), 
      ),
      paint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, dotCenterY - (clampedBarHeight - barHeight)/2 ), // Sesuaikan posisi dot jika barHeight di-clamp
      clampedDotRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ExclamationPainter oldDelegate) => 
      oldDelegate.screenWidth != screenWidth || oldDelegate.isLarge != isLarge;
}