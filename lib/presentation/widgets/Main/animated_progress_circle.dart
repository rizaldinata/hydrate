import 'package:flutter/material.dart';
import 'dart:math' as math;

// Enum ProgressState tetap sama
enum ProgressState {
  empty,
  normal,
  exceeded,
  critical,
}

// Warna latar belakang utama aplikasi Anda
const Color appPageBackgroundColor = Color(0xFFE8F7FF);
// Warna untuk track pinggiran/arc, sedikit lebih gelap dari background agar terlihat
const Color arcTrackColorEmpty = Color(0xFFCCE7F8); // Sedikit lebih gelap dari abu-abu standar
const Color arcTrackColorActive = Color(0xFFCCE7F8); // Sedikit lebih gelap dari appPageBackgroundColor

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
  late AnimationController _waveController;
  late AnimationController _exclamationMarkMovementController;
  late AnimationController _progressDisplayController;

  late Animation<double> _waveAnimation;
  late Animation<double> _exclamationMarkMovementAnimation;
  late Animation<double> _progressDisplayAnimation;

  // Variabel _currentAnimatedProgressPercent tidak lagi secara langsung digunakan untuk mengontrol tampilan
  // _progressDisplayAnimation.value menjadi sumber utama untuk nilai animasi

  final double _arcStrokeWidth = 15.0;

  @override
  void initState() {
    super.initState();
    _setupWaveAnimation();
    _setupProgressDisplayAnimation(); // Dipanggil setelah _waveController
    _setupEmptyStateAnimations(); // Dipanggil setelah _progressDisplayController
    _updateAnimationPlaybackBasedOnState(); // Dipanggil setelah semua controller
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Nilai awal untuk animasi (bisa > 100%)
    final initialProgressForAnimation = widget.target > 0
        ? (widget.currentIntake / widget.target * 100)
        : 0.0;

    _progressDisplayAnimation = Tween<double>(
      begin: initialProgressForAnimation,
      end: initialProgressForAnimation,
    ).animate(CurvedAnimation(
      parent: _progressDisplayController,
      curve: Curves.easeInOutCubic,
    ));
    // Jalankan controller sekali agar nilai awal diterapkan jika tidak ada update awal
    // _progressDisplayController.forward(); // Tidak perlu forward di sini, didUpdateWidget akan handle
  }

  void _setupEmptyStateAnimations() {
    _exclamationMarkMovementController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _exclamationMarkMovementAnimation = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(
      parent: _exclamationMarkMovementController,
      curve: Curves.easeInOutSine,
    ));
  }

void _updateAnimationPlaybackBasedOnState() {
  final progressState = _getProgressState();
  if (!mounted) return;

  if (progressState == ProgressState.empty) {
    if (!_exclamationMarkMovementController.isAnimating) {
      _exclamationMarkMovementController.repeat(reverse: true);
    }
    // Hentikan animasi gelombang jika kosong
    if (_waveController.isAnimating) {
      _waveController.stop();
    }
  } else { // Mencakup Normal, Exceeded, dan Critical
    if (_exclamationMarkMovementController.isAnimating) {
      _exclamationMarkMovementController.stop();
      _exclamationMarkMovementController.reset();
    }

    // Jika ada air (currentIntake > 0), jalankan animasi gelombang
    // Ini akan membuat air tetap bergelombang meskipun sudah exceeded atau critical
    if (widget.currentIntake > 0) {
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
    } else {
      // Jika tidak ada air (misalnya, target > 0 tapi intake = 0), hentikan gelombang
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
    }
  }
}

  @override
  void didUpdateWidget(AnimatedWaterProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgressForAnimation = widget.target > 0
        ? (widget.currentIntake / widget.target * 100)
        : 0.0;

    if ((newProgressForAnimation - _progressDisplayAnimation.value).abs() > 0.01) {
      _progressDisplayAnimation = Tween<double>(
        begin: _progressDisplayAnimation.value,
        end: newProgressForAnimation,
      ).animate(CurvedAnimation(
        parent: _progressDisplayController,
        curve: Curves.easeInOutCubic,
      ));
      _progressDisplayController.forward(from: 0.0);
    } else if (newProgressForAnimation != _progressDisplayAnimation.value) {
        if (mounted && !_progressDisplayController.isAnimating) {
         setState(() { // Pastikan UI di-rebuild untuk perubahan nilai instan
            _progressDisplayAnimation = ConstantTween<double>(newProgressForAnimation)
                .animate(_progressDisplayController);
         });
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
    final ratio = widget.currentIntake / widget.target;
    if (ratio > 2.0) return ProgressState.critical;
    if (ratio > 1.0) return ProgressState.exceeded;
    return ProgressState.normal;
  }

  // MODIFIED: Disesuaikan agar warna teks persen lebih cocok dengan gambar sampel
 Color _getPercentageTextColor(ProgressState state) {
    if (state == ProgressState.empty && widget.currentIntake <=0) return Colors.transparent;

    if (state == ProgressState.critical) {
      // Untuk state critical (arc merah), teks "100%" berwarna gelap seperti di gambar
      return Colors.black.withOpacity(0.85);
    }
    if (state == ProgressState.exceeded) {
      // Untuk state exceeded (arc oranye), teks "100%" berwarna oranye
      return Colors.orange.shade700;
    }
    // Untuk state normal:
    // Jika sudah mencapai atau melebihi target (teks akan "100%"), warna oranye
    // Jika kurang dari target, warna biru tua standar
    return (widget.target > 0 && widget.currentIntake >= widget.target)
        ? Colors.orange.shade700
        : const Color(0xFF003D7A);
  }


  Color _getCurrentIntakeValueColor(ProgressState state) {
    if (state == ProgressState.empty && widget.currentIntake <=0) return Colors.transparent;
    if (state == ProgressState.exceeded || state == ProgressState.critical) {
      return Colors.black.withOpacity(0.75); // Gelap agar kontras dengan latar air/warna arc
    }
    if (widget.target > 0 && widget.currentIntake < widget.target && state == ProgressState.normal) {
      return Colors.red.shade600;
    }
    return Colors.orange.shade700;
  }

  Color _getTargetUnitTextColor(ProgressState state) {
    if (state == ProgressState.empty && widget.currentIntake <=0) return Colors.transparent;
    if (state == ProgressState.exceeded || state == ProgressState.critical) {
      return Colors.black.withOpacity(0.65);
    }
    return (widget.target > 0 && widget.currentIntake >= widget.target)
        ? Colors.orange.shade600.withOpacity(0.8)
        : const Color(0xFF005A8D).withOpacity(0.8);
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
              _progressDisplayController, _waveController, _exclamationMarkMovementController,
            ]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: CircleBackgroundPainter(progressState: progressState),
                    size: Size.infinite,
                  ),
                  if (progressState != ProgressState.empty && widget.currentIntake > 0)
                     _buildWaterVisuals(progressState)
                  else if (progressState == ProgressState.empty)
                    _buildEmptyStateVisuals(),

                  CustomPaint(
                    painter: ProgressArcPainter(
                      progress: _progressDisplayAnimation.value, // Nilai aktual untuk warna arc
                      startAngleDegrees: -90,
                      sweepAngleDegrees: 360,
                      progressState: progressState,
                      strokeWidth: _arcStrokeWidth,
                    ),
                    size: Size.infinite,
                  ),
                  _buildCentralTextContent(progressState), // Akan menggunakan nilai yang di-cap untuk teks %
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // MODIFIED: Teks persentase di-cap pada 100%
  Widget _buildCentralTextContent(ProgressState progressState) {
    if (progressState == ProgressState.empty && widget.currentIntake <=0 ) return Container();

    // Ambil nilai animasi aktual (bisa > 100)
    final double animatedProgressValue = _progressDisplayAnimation.value;
    // Cap nilai persentase yang akan ditampilkan di teks menjadi maksimal 100.0
    final double displayPercentageForText = math.min(animatedProgressValue, 100.0);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${displayPercentageForText.ceil()}%', // Gunakan nilai yang sudah di-cap
          style: TextStyle(color: _getPercentageTextColor(progressState), fontWeight: FontWeight.w300, fontSize: widget.screenWidth * 0.12, fontFamily: 'Roboto')),
      SizedBox(height: widget.screenWidth * 0.015),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text('${widget.currentIntake.toInt()}',
            style: TextStyle(color: _getCurrentIntakeValueColor(progressState), fontWeight: FontWeight.w600, fontSize: widget.screenWidth * 0.05, fontFamily: 'Roboto')),
        Text(' / ${widget.target.toInt()} mL',
            style: TextStyle(color: _getTargetUnitTextColor(progressState), fontWeight: FontWeight.w400, fontSize: widget.screenWidth * 0.04, fontFamily: 'Roboto')),
      ])]);
  }

  Widget _buildWaterVisuals(ProgressState progressState) {
    return CustomPaint(painter: WaterWavePainter(
      wavePhase: _waveAnimation.value,
      waterLevel: widget.target > 0 ? widget.currentIntake / widget.target : 0.0,
      progressState: progressState,
      arcStrokeWidth: _arcStrokeWidth),
      size: Size.infinite);
  }

  Widget _buildEmptyStateVisuals() {
    return Stack(alignment: Alignment.center, children: [
      Transform.rotate(angle: -0.15, child: CustomPaint(painter: EmptyGlassPainter(screenWidth: widget.screenWidth), size: Size(widget.screenWidth * 0.25, widget.screenWidth * 0.35))),
      Transform.translate(offset: Offset(_exclamationMarkMovementAnimation.value, -widget.screenWidth * 0.12),
          child: CustomPaint(painter: ExclamationPainter(screenWidth: widget.screenWidth, isLarge: true), size: Size(widget.screenWidth * 0.12, widget.screenWidth * 0.18)))]
    );
  }
}

// --- PAINTERS ---
const double _GLOBAL_ARC_STROKE_WIDTH = 15.0;

class CircleBackgroundPainter extends CustomPainter {
  final ProgressState progressState;

  CircleBackgroundPainter({required this.progressState});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - (_GLOBAL_ARC_STROKE_WIDTH / 2) - 1.0; 

    Color fillColor;
    switch (progressState) {
      case ProgressState.exceeded:
      case ProgressState.critical:
      case ProgressState.empty:
      case ProgressState.normal:
      default:
        fillColor = appPageBackgroundColor;
        break;
    }

    final backgroundPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    if (radius > 0) {
      canvas.drawCircle(center, radius, backgroundPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CircleBackgroundPainter oldDelegate) =>
      oldDelegate.progressState != progressState;
}

class ProgressArcPainter extends CustomPainter {
  final double progress; 
  final double startAngleDegrees;
  final double sweepAngleDegrees;
  final ProgressState progressState;
  final double strokeWidth;

  ProgressArcPainter({
    required this.progress, // progress di sini adalah nilai animasi aktual, bisa > 100
    required this.startAngleDegrees,
    required this.sweepAngleDegrees,
    required this.progressState,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngleRad = startAngleDegrees * (math.pi / 180);

    Color currentTrackColor;
    if (progressState == ProgressState.empty) {
      currentTrackColor = arcTrackColorEmpty;
    } else {
      currentTrackColor = arcTrackColorActive;
    }

    final trackPaint = Paint()
      ..color = currentTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, startAngleRad, sweepAngleDegrees * (math.pi / 180), false, trackPaint);

    if (progressState != ProgressState.empty && progress > 0) {
      Color solidProgressColor;
      switch (progressState) {
        case ProgressState.critical:
          solidProgressColor = Colors.red.shade600;
          break;
        case ProgressState.exceeded:
          solidProgressColor = Colors.orange.shade600;
          break;
        case ProgressState.normal:
        default:
          solidProgressColor = const Color(0xFF007ACC);
          break;
      }

      final progressPaint = Paint()
        ..color = solidProgressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Panjang visual busur di-cap pada 100% (satu lingkaran penuh)
      final actualProgressForArcDisplay = math.min(progress, 100.0); 
      final currentSweepRad = (sweepAngleDegrees * actualProgressForArcDisplay / 100) * (math.pi / 180);


      if (currentSweepRad.abs() > 0.001) {
        canvas.drawArc(rect, startAngleRad, currentSweepRad, false, progressPaint);
      }
      
      // Seek indicator hanya untuk state normal dan progress < 100%
      if (progress > 0 && progress < 100 && progressState == ProgressState.normal) {
        final seekAngle = startAngleRad + currentSweepRad;
        final seekX = center.dx + radius * math.cos(seekAngle);
        final seekY = center.dy + radius * math.sin(seekAngle);
        final seekRadius = strokeWidth * 0.35;
        final seekFillPaint = Paint()..color = Colors.white;
        final seekBorderPaint = Paint()..color = solidProgressColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth * 0.15;
        canvas.drawCircle(Offset(seekX, seekY), seekRadius, seekFillPaint);
        canvas.drawCircle(Offset(seekX, seekY), seekRadius, seekBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressState != progressState ||
      oldDelegate.strokeWidth != strokeWidth;
}

class WaterWavePainter extends CustomPainter {
  final double wavePhase;
  final double waterLevel; // Ini adalah rasio aktual, bisa > 1.0
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
    if (progressState == ProgressState.empty && waterLevel <= 0.001) { // Tambahkan pengecekan waterLevel juga untuk empty state
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    // waterRadius adalah radius dari area lingkaran DALAM tempat air bergelombang
    final waterRadius = math.min(size.width, size.height) / 2 - arcStrokeWidth - 1.5; // Pengurangan 1.5 agar ada sedikit jarak dari arc
    if (waterRadius <= 0) return;

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);

    // cappedVisualWaterLevel menentukan seberapa penuh lingkaran secara visual (0.0 hingga 1.0)
    final cappedVisualWaterLevel = math.min(waterLevel, 1.0).clamp(0.0, 1.0); // Pastikan clamp 0-1

    // Hitung Y permukaan air berdasarkan bagian atas dan tinggi wadah air visual (lingkaran dalam)
    final waterContainerTopY = center.dy - waterRadius;
    final waterContainerHeight = 2 * waterRadius;
    final waterSurfaceY = waterContainerTopY + (waterContainerHeight * (1 - cappedVisualWaterLevel));

    // Jika level air sangat rendah (hampir kosong tapi tidak 0), jangan gambar gelombang agar tidak aneh
    if (cappedVisualWaterLevel < 0.01 && waterLevel > 0) {
        // Gambar lapisan air tipis statis jika mau, atau return saja
        // Untuk sekarang, jika sangat rendah, kita tidak gambar gelombangnya
        // agar tidak ada gelombang aneh di dasar yang hampir kosong.
        // Jika ingin ada air statis tipis:
        // final waterPaint = Paint()..color = const Color(0xAA4AA8FF); // Warna air solid tipis
        // canvas.drawRect(Rect.fromLTRB(0, waterSurfaceY, size.width, center.dy + waterRadius), waterPaint);
        return;
    }
    
    // Jika setelah perhitungan di atas, waterSurfaceY melebihi dasar lingkaran (karena floating point)
    // atau intake sangat kecil sehingga cappedVisualWaterLevel mendekati 0,
    // pastikan gelombang tidak "meluap" ke bawah.
    // Ini seharusnya sudah ditangani oleh cappedVisualWaterLevel yang di-clamp(0.0, 1.0)
    // dan perhitungan waterSurfaceY yang baru.

    const Color gradLight = Color(0xFFA0E0FF);
    const Color gradDark = Color(0xFF4AA8FF);

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [gradLight, gradDark], stops: const [0.2, 0.8],
      ).createShader(Rect.fromLTWH(0, waterSurfaceY - size.height * 0.1, size.width, size.height - (waterSurfaceY - size.height * 0.1)))
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    final amplitude = 5.0; // Amplitudo gelombang
    final frequency = 2.0; // Frekuensi gelombang

    wavePath.moveTo(0, waterSurfaceY);
    for (double x = 0; x <= size.width; x++) {
      double yOffset = amplitude * math.sin(frequency * x * (math.pi / 180) + wavePhase) +
          amplitude * 0.4 * math.sin(frequency * 0.8 * x * (math.pi / 180) + wavePhase * 1.2 + math.pi / 4);
      wavePath.lineTo(x, waterSurfaceY + yOffset);
    }
    // Tutup path dengan menggambar hingga ke dasar area kliping
    wavePath.lineTo(size.width, center.dy + waterRadius); // Ke sudut kanan bawah area air
    wavePath.lineTo(0, center.dy + waterRadius); // Ke sudut kiri bawah area air
    wavePath.close();
    canvas.drawPath(wavePath, waterPaint);

    // Busa hanya jika ada cukup air
    if (cappedVisualWaterLevel > 0.05) {
      final foamPaint = Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5;
      final foamPath = Path();
      foamPath.moveTo(0, waterSurfaceY);
      for (double x = 0; x <= size.width; x += 2) {
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
    final glassWidth = size.width * 0.8; final glassHeight = size.height * 0.9;
    final glassBaseHeight = glassHeight * 0.15; final glassRimHeight = 5.0;
    final glassFillPaint = Paint()..color = const Color(0xFFD0EFFF).withOpacity(0.5)..style = PaintingStyle.fill;
    final glassStrokePaint = Paint()..color = const Color(0xFF87CEFA).withOpacity(0.7)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final glassPath = Path()
      ..moveTo(center.dx - glassWidth / 2, center.dy - glassHeight / 2 + glassRimHeight)
      ..lineTo(center.dx - glassWidth / 2 * 0.7, center.dy + glassHeight / 2 - glassBaseHeight)
      ..quadraticBezierTo(center.dx, center.dy + glassHeight / 2 + glassBaseHeight * 0.3, center.dx + glassWidth / 2 * 0.7, center.dy + glassHeight / 2 - glassBaseHeight)
      ..lineTo(center.dx + glassWidth / 2, center.dy - glassHeight / 2 + glassRimHeight);
    canvas.drawPath(glassPath, glassFillPaint); canvas.drawPath(glassPath, glassStrokePaint);
    final rimRect = Rect.fromCenter(center: Offset(center.dx, center.dy - glassHeight / 2 + glassRimHeight / 2), width: glassWidth, height: glassRimHeight * 1.5);
    canvas.drawOval(rimRect, Paint()..style = PaintingStyle.fill ..color = const Color(0xFFB0E0E6).withOpacity(0.6));
    canvas.drawOval(rimRect, glassStrokePaint);
  }
  @override
  bool shouldRepaint(covariant EmptyGlassPainter oldDelegate) => oldDelegate.screenWidth != screenWidth;
}

class ExclamationPainter extends CustomPainter {
  final double screenWidth; final bool isLarge;
  ExclamationPainter({required this.screenWidth, this.isLarge = false});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red.shade500..style = PaintingStyle.fill;
    final scaleFactor = isLarge ? 1.5 : 1.0;
    final barWidth = size.width * 0.35 * scaleFactor; final barHeight = size.height * 0.6 * scaleFactor;
    final dotRadius = size.width * 0.22 * scaleFactor;
    final clampedBarHeight = math.min(barHeight, size.height * 0.7); final clampedDotRadius = math.min(dotRadius, size.width * 0.3);
    final barTopY = size.height * 0.15; final dotCenterY = barTopY + clampedBarHeight + clampedDotRadius * 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, barTopY + clampedBarHeight / 2), width: barWidth, height: clampedBarHeight), Radius.circular(barWidth / 3)), paint);
    canvas.drawCircle(Offset(size.width / 2, dotCenterY), clampedDotRadius, paint);
  }
  @override
  bool shouldRepaint(covariant ExclamationPainter oldDelegate) => oldDelegate.screenWidth != screenWidth || oldDelegate.isLarge != isLarge;
}