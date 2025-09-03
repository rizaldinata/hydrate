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
const Color arcTrackColorEmpty =
    Color(0xFFCCE7F8); // Sedikit lebih gelap dari abu-abu standar
const Color arcTrackColorActive =
    Color(0xFFCCE7F8); // Sedikit lebih gelap dari appPageBackgroundColor

class AnimatedWaterProgressCircle extends StatefulWidget {
  final double currentIntake;
  final double target;
  final double screenWidth;

  const AnimatedWaterProgressCircle({
    super.key,
    required this.currentIntake,
    required this.target,
    required this.screenWidth,
  });

  @override
  State<AnimatedWaterProgressCircle> createState() =>
      _AnimatedWaterProgressCircleState();
}

class _AnimatedWaterProgressCircleState
    extends State<AnimatedWaterProgressCircle> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _exclamationMarkMovementController;
  late AnimationController _progressDisplayController;

  late Animation<double> _waveAnimation;
  late Animation<double> _exclamationMarkMovementAnimation;
  late Animation<double> _progressDisplayAnimation;

  final double _arcStrokeWidth = 15.0;

  @override
  void initState() {
    super.initState();
    _setupWaveAnimation();
    _setupProgressDisplayAnimation();
    _setupEmptyStateAnimations();
    _updateAnimationPlaybackBasedOnState();
  }

  void _setupWaveAnimation() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
        CurvedAnimation(parent: _waveController, curve: Curves.linear));
  }

  void _setupProgressDisplayAnimation() {
    _progressDisplayController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final initialProgressForAnimation =
        widget.target > 0 ? (widget.currentIntake / widget.target * 100) : 0.0;

    _progressDisplayAnimation = Tween<double>(
      begin: initialProgressForAnimation,
      end: initialProgressForAnimation,
    ).animate(CurvedAnimation(
      parent: _progressDisplayController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _setupEmptyStateAnimations() {
    _exclamationMarkMovementController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _exclamationMarkMovementAnimation =
        Tween<double>(begin: -6.0, end: 6.0).animate(CurvedAnimation(
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
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
    } else {
      if (_exclamationMarkMovementController.isAnimating) {
        _exclamationMarkMovementController.stop();
        _exclamationMarkMovementController.reset();
      }

      if (widget.currentIntake > 0) {
        if (!_waveController.isAnimating) {
          _waveController.repeat();
        }
      } else {
        if (_waveController.isAnimating) {
          _waveController.stop();
        }
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedWaterProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgressForAnimation =
        widget.target > 0 ? (widget.currentIntake / widget.target * 100) : 0.0;

    if ((newProgressForAnimation - _progressDisplayAnimation.value).abs() >
        0.01) {
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
        setState(() {
          _progressDisplayAnimation =
              ConstantTween<double>(newProgressForAnimation)
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
    if (ratio > 2.0) return ProgressState.critical; // Lebih dari 200%
    if (ratio > 1.0)
      return ProgressState.exceeded; // Lebih dari 100% hingga 200%
    return ProgressState.normal; // Hingga 100%
  }

  Color _getPercentageTextColor(ProgressState state) {
    if (state == ProgressState.empty && widget.currentIntake <= 0)
      return Colors.transparent;

    if (state == ProgressState.critical) {
      return Color(0xFF003D7A);
    }
    if (state == ProgressState.exceeded) {
      return Color(0xFF003D7A);
    }
    return (widget.target > 0 && widget.currentIntake >= widget.target)
        ? const Color(0xFF003D7A)
        : const Color(0xFF003D7A);
  }

  Color _getCurrentIntakeValueColor(ProgressState state) {
    if (state == ProgressState.empty && widget.currentIntake <= 0)
      return Colors.transparent;
    if (state == ProgressState.critical) {
      return Color.fromARGB(
          255, 228, 128, 70); // Warna lebih gelap untuk critical
    }
    if (state == ProgressState.exceeded) {
      return Color(0xFF003D7A);
    }
    if (widget.target > 0 &&
        widget.currentIntake < widget.target &&
        state == ProgressState.normal) {
      return Colors.red.shade600;
    }
    return const Color(0xFF003D7A);
  }

  Color _getTargetUnitTextColor(ProgressState state) {
    if (state == ProgressState.empty && widget.currentIntake <= 0)
      return Colors.transparent;
    if (state == ProgressState.exceeded || state == ProgressState.critical) {
      return Colors.black.withOpacity(0.65);
    }
    return (widget.target > 0 && widget.currentIntake >= widget.target)
        ? const Color(0xFF005A8D).withOpacity(0.8)
        : const Color(0xFF005A8D).withOpacity(0.8);
  }

  @override
Widget build(BuildContext context) {
  final progressState = _getProgressState();
  
  // Calculate circle size as 0.8 of screen width
  final circleSize = widget.screenWidth * 0.75;

    return Padding(
      padding: EdgeInsets.all(widget.screenWidth * 0.05),
      child: Center(
        child: SizedBox(
          width: circleSize,
          height: circleSize,
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
                    painter:
                        CircleBackgroundPainter(progressState: progressState),
                    size: Size(circleSize, circleSize),
                  ),
                  if (progressState != ProgressState.empty &&
                      widget.currentIntake > 0)
                    _buildWaterVisuals(progressState)
                  else if (progressState == ProgressState.empty)
                    _buildEmptyStateVisuals(),
                  CustomPaint(
                    painter: ProgressArcPainter(
                      progress: _progressDisplayAnimation.value,
                      startAngleDegrees: -90,
                      sweepAngleDegrees: 360,
                      progressState: progressState,
                      strokeWidth: _arcStrokeWidth,
                    ),
                    size: Size(circleSize, circleSize),
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
    if (progressState == ProgressState.empty && widget.currentIntake <= 0)
      return Container();

    final double animatedProgressValue = _progressDisplayAnimation.value;
    final double displayPercentageForText =
        math.min(animatedProgressValue, 100.0);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${displayPercentageForText.ceil()}%',
          style: TextStyle(
              color: _getPercentageTextColor(progressState),
              fontWeight: FontWeight.w300,
              fontSize: widget.screenWidth * 0.12,
              fontFamily: 'Roboto')),
      SizedBox(height: widget.screenWidth * 0.015),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${widget.currentIntake.toInt()}',
                style: TextStyle(
                    color: _getCurrentIntakeValueColor(progressState),
                    fontWeight: FontWeight.w600,
                    fontSize: widget.screenWidth * 0.05,
                    fontFamily: 'Roboto')),
            Text(' / ${widget.target.toInt()} mL',
                style: TextStyle(
                    color: _getTargetUnitTextColor(progressState),
                    fontWeight: FontWeight.w400,
                    fontSize: widget.screenWidth * 0.04,
                    fontFamily: 'Roboto')),
          ])
    ]);
  }

  Widget _buildWaterVisuals(ProgressState progressState) {
    return CustomPaint(
        painter: WaterWavePainter(
            wavePhase: _waveAnimation.value,
            waterLevel:
                widget.target > 0 ? widget.currentIntake / widget.target : 0.0,
            progressState: progressState,
            arcStrokeWidth: _arcStrokeWidth),
        size: Size.infinite);
  }

  Widget _buildEmptyStateVisuals() {
    return Stack(alignment: Alignment.center, children: [
      Transform.rotate(
          angle: -0.15,
          child: CustomPaint(
              painter: EmptyGlassPainter(screenWidth: widget.screenWidth),
              size:
                  Size(widget.screenWidth * 0.25, widget.screenWidth * 0.35))),
      Transform.translate(
          offset: Offset(_exclamationMarkMovementAnimation.value,
              -widget.screenWidth * 0.12),
          child: CustomPaint(
              painter: ExclamationPainter(
                  screenWidth: widget.screenWidth, isLarge: true),
              size: Size(widget.screenWidth * 0.12, widget.screenWidth * 0.18)))
    ]);
  }
}

// --- PAINTERS ---
const double _globalArcStrokeWidth = 15.0;

class CircleBackgroundPainter extends CustomPainter {
  final ProgressState progressState;

  CircleBackgroundPainter({required this.progressState});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 -
        (_globalArcStrokeWidth / 2) -
        1.0;

    Color fillColor;
    switch (progressState) {
      case ProgressState.exceeded:
      case ProgressState.critical:
      case ProgressState.empty:
      case ProgressState.normal:
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
    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngleRad = startAngleDegrees * (math.pi / 180);

    Color currentTrackColor;
    if (progressState == ProgressState.empty) {
      currentTrackColor = arcTrackColorEmpty;
    } else {
      currentTrackColor = arcTrackColorActive;
    }

    // Draw background track
    final trackPaint = Paint()
      ..color = currentTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, startAngleRad, sweepAngleDegrees * (math.pi / 180),
        false, trackPaint);

    if (progressState != ProgressState.empty && progress > 0) {
      double actualAnimatedProgress = progress;

      // MODIFIED: Draw both layers for exceeded and critical states
      switch (progressState) {
        case ProgressState.critical: // Progress > 200%
          // Draw blue background layer (full circle for first 100%)
          _drawProgressArc(
              canvas,
              rect,
              startAngleRad,
              sweepAngleDegrees,
              const Color(0xFF007ACC), // Blue color
              100.0, // Full circle
              strokeWidth,
              center,
              radius,
              false // No seek indicator for background layer
              );

          // Draw RED layer (full circle - orange layer becomes red when critical)
          _drawProgressArc(
              canvas,
              rect,
              startAngleRad,
              sweepAngleDegrees,
              Colors.red.shade600, // RED color instead of orange
              100.0, // Full circle
              strokeWidth, // SAME size as blue layer
              center,
              radius,
              false // No seek indicator - critical state is static
              );
          break;

        case ProgressState.exceeded: // Progress > 100% and <= 200%
          // Draw blue background layer (full circle for first 100%)
          _drawProgressArc(
              canvas,
              rect,
              startAngleRad,
              sweepAngleDegrees,
              const Color(0xFF007ACC), // Blue color
              100.0, // Full circle
              strokeWidth,
              center,
              radius,
              false // No seek indicator for background layer
              );

          // Draw orange layer (current progress in second rotation)
          double orangeSweepPercent =
              (actualAnimatedProgress - 100.0).clamp(0.0, 100.0);
          _drawProgressArc(
              canvas,
              rect,
              startAngleRad,
              sweepAngleDegrees,
              Colors.orange.shade600, // Orange color
              orangeSweepPercent,
              strokeWidth, // SAME size as blue layer - will cover blue completely
              center,
              radius,
              orangeSweepPercent <
                  100.0 // Show seek indicator only if not complete
              );
          break;

        case ProgressState.normal: // Progress <= 100%
        default:
          double blueSweepPercent = actualAnimatedProgress.clamp(0.0, 100.0);
          _drawProgressArc(
              canvas,
              rect,
              startAngleRad,
              sweepAngleDegrees,
              const Color(0xFF007ACC), // Blue color
              blueSweepPercent,
              strokeWidth,
              center,
              radius,
              blueSweepPercent <
                  100.0 // Show seek indicator only if not complete
              );
          break;
      }
    }
  }

  void _drawProgressArc(
    Canvas canvas,
    Rect rect,
    double startAngleRad,
    double sweepAngleDegrees,
    Color color,
    double sweepPercent,
    double strokeWidth,
    Offset center,
    double radius,
    bool showSeekIndicator,
  ) {
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final currentSweepRad =
        (sweepAngleDegrees * sweepPercent / 100) * (math.pi / 180);

    if (currentSweepRad.abs() > 0.0001) {
      canvas.drawArc(
          rect, startAngleRad, currentSweepRad, false, progressPaint);
    }

    // Draw seek indicator (white dot at the end of progress)
    if (showSeekIndicator && sweepPercent > 0 && sweepPercent < 100) {
      final seekAngle = startAngleRad + currentSweepRad;
      final seekX = center.dx + radius * math.cos(seekAngle);
      final seekY = center.dy + radius * math.sin(seekAngle);
      final seekRadius = strokeWidth * 0.35;

      final seekFillPaint = Paint()..color = Colors.white;
      final seekBorderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.15;

      canvas.drawCircle(Offset(seekX, seekY), seekRadius, seekFillPaint);
      canvas.drawCircle(Offset(seekX, seekY), seekRadius, seekBorderPaint);
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
    if (progressState == ProgressState.empty && waterLevel <= 0.001) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final waterRadius =
        math.min(size.width, size.height) / 2 - arcStrokeWidth - 1.5;
    if (waterRadius <= 0) return;

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);

    final cappedVisualWaterLevel = math.min(waterLevel, 1.0).clamp(0.0, 1.0);

    final waterContainerTopY = center.dy - waterRadius;
    final waterContainerHeight = 2 * waterRadius;
    final waterSurfaceY = waterContainerTopY +
        (waterContainerHeight * (1 - cappedVisualWaterLevel));

    if (cappedVisualWaterLevel < 0.01 && waterLevel > 0) {
      return;
    }

    const Color gradLight = Color(0xFFA0E0FF);
    const Color gradDark = Color(0xFF4AA8FF);

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradLight, gradDark],
        stops: const [0.2, 0.8],
      ).createShader(Rect.fromLTWH(0, waterSurfaceY - size.height * 0.1,
          size.width, size.height - (waterSurfaceY - size.height * 0.1)))
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    final amplitude = 5.0;
    final frequency = 2.0;

    wavePath.moveTo(0, waterSurfaceY);
    for (double x = 0; x <= size.width; x++) {
      double yOffset =
          amplitude * math.sin(frequency * x * (math.pi / 180) + wavePhase) +
              amplitude *
                  0.4 *
                  math.sin(frequency * 0.8 * x * (math.pi / 180) +
                      wavePhase * 1.2 +
                      math.pi / 4);
      wavePath.lineTo(x, waterSurfaceY + yOffset);
    }
    wavePath.lineTo(size.width, center.dy + waterRadius);
    wavePath.lineTo(0, center.dy + waterRadius);
    wavePath.close();
    canvas.drawPath(wavePath, waterPaint);

    if (cappedVisualWaterLevel > 0.05) {
      final foamPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final foamPath = Path();
      foamPath.moveTo(0, waterSurfaceY);
      for (double x = 0; x <= size.width; x += 2) {
        final yOffset = amplitude *
                0.3 *
                math.sin(frequency * 1.5 * x * (math.pi / 180) +
                    wavePhase * 1.5 +
                    math.pi / 2) -
            1.0;
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
      ..color = const Color(0xFFD0EFFF).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final glassStrokePaint = Paint()
      ..color = const Color(0xFF87CEFA).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final glassPath = Path()
      ..moveTo(center.dx - glassWidth / 2,
          center.dy - glassHeight / 2 + glassRimHeight)
      ..lineTo(center.dx - glassWidth / 2 * 0.7,
          center.dy + glassHeight / 2 - glassBaseHeight)
      ..quadraticBezierTo(
          center.dx,
          center.dy + glassHeight / 2 + glassBaseHeight * 0.3,
          center.dx + glassWidth / 2 * 0.7,
          center.dy + glassHeight / 2 - glassBaseHeight)
      ..lineTo(center.dx + glassWidth / 2,
          center.dy - glassHeight / 2 + glassRimHeight);
    canvas.drawPath(glassPath, glassFillPaint);
    canvas.drawPath(glassPath, glassStrokePaint);
    final rimRect = Rect.fromCenter(
        center:
            Offset(center.dx, center.dy - glassHeight / 2 + glassRimHeight / 2),
        width: glassWidth,
        height: glassRimHeight * 1.5);
    canvas.drawOval(
        rimRect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFB0E0E6).withOpacity(0.6));
    canvas.drawOval(rimRect, glassStrokePaint);
  }

  @override
  bool shouldRepaint(covariant EmptyGlassPainter oldDelegate) =>
      oldDelegate.screenWidth != screenWidth;
}

class ExclamationPainter extends CustomPainter {
  final double screenWidth;
  final bool isLarge;
  ExclamationPainter({required this.screenWidth, this.isLarge = false});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade500
      ..style = PaintingStyle.fill;
    final scaleFactor = isLarge ? 1.5 : 1.0;
    final barWidth = size.width * 0.35 * scaleFactor;
    final barHeight = size.height * 0.6 * scaleFactor;
    final dotRadius = size.width * 0.22 * scaleFactor;
    final clampedBarHeight = math.min(barHeight, size.height * 0.7);
    final clampedDotRadius = math.min(dotRadius, size.width * 0.3);
    final barTopY = size.height * 0.15;
    final dotCenterY = barTopY + clampedBarHeight + clampedDotRadius * 1.5;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(size.width / 2, barTopY + clampedBarHeight / 2),
                width: barWidth,
                height: clampedBarHeight),
            Radius.circular(barWidth / 3)),
        paint);
    canvas.drawCircle(
        Offset(size.width / 2, dotCenterY), clampedDotRadius, paint);
  }

  @override
  bool shouldRepaint(covariant ExclamationPainter oldDelegate) =>
      oldDelegate.screenWidth != screenWidth || oldDelegate.isLarge != isLarge;
}
