import 'package:flutter/material.dart';
import 'dart:math' as math;

// Enum untuk status progres (tetap sama)
enum ProgressState {
  empty,
  normal,
  exceeded, // Target terlampaui (misal 101% - 200%)
  critical, // Jauh melebihi target (misal > 200%)
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
  late AnimationController _exclamationMarkMovementController;
  late AnimationController _progressDisplayController;

  // Animations
  late Animation<double> _waveAnimation;
  late Animation<double> _exclamationMarkMovementAnimation;
  late Animation<double> _progressDisplayAnimation; // Animates the UNCAPPED progress for arc painting

  // Stores the target end value for the _progressDisplayAnimation (uncapped percentage)
  double _targetAnimatedUncappedProgressPercent = 0.0;
  final double _arcStrokeWidth = 15.0;

  @override
  void initState() {
    super.initState();
    _setupWaveAnimation();
    _setupProgressDisplayAnimation();
    _setupEmptyStateAnimations();
    _updateAnimationPlaybackBasedOnState();

    // Start initial animation if needed
    if (_targetAnimatedUncappedProgressPercent > 0) {
      _progressDisplayController.forward();
    }
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
      duration: const Duration(milliseconds: 1000), // Duration for progress change
      vsync: this,
    );

    // Initial uncapped progress percentage
    _targetAnimatedUncappedProgressPercent = widget.target > 0
        ? (widget.currentIntake / widget.target * 100.0)
        : 0.0;

    _progressDisplayAnimation = Tween<double>(
      begin: 0.0, // Always animate from 0 on init, or from previous value in didUpdateWidget
      end: _targetAnimatedUncappedProgressPercent,
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
    _exclamationMarkMovementAnimation = Tween<double>(begin: -6.0, end: 6.0)
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
      // Wave animation stops only if critical, otherwise it repeats
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

    final double newTargetUncappedProgressPercent = widget.target > 0
        ? (widget.currentIntake / widget.target * 100.0)
        : 0.0;

    // Only update and animate if the target progress has changed significantly
    if ((newTargetUncappedProgressPercent - _targetAnimatedUncappedProgressPercent).abs() > 0.01) {
      _progressDisplayAnimation = Tween<double>(
        begin: _progressDisplayAnimation.value, // Start animation from current visual progress
        end: newTargetUncappedProgressPercent,
      ).animate(CurvedAnimation(
        parent: _progressDisplayController,
        curve: Curves.easeInOutCubic,
      ));
      _progressDisplayController.forward(from: 0.0);
      _targetAnimatedUncappedProgressPercent = newTargetUncappedProgressPercent;
    } else if (newTargetUncappedProgressPercent != _targetAnimatedUncappedProgressPercent) {
      // Snap to value if difference is tiny or if it's already at the target (e.g. due to rounding)
       _targetAnimatedUncappedProgressPercent = newTargetUncappedProgressPercent;
      if (!_progressDisplayController.isAnimating) {
        // Update animation to reflect the new target, even if not animating, so .value is correct
        _progressDisplayAnimation = ConstantTween<double>(newTargetUncappedProgressPercent)
            .animate(_progressDisplayController);
        if (mounted) {
          setState(() {}); // Ensure rebuild if not animating to reflect ConstantTween
        }
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
    final ratio = widget.currentIntake / widget.target;
    if (widget.currentIntake <= 0) return ProgressState.empty;
    if (ratio > 2.0) return ProgressState.critical; // More than 200%
    if (ratio > 1.0) return ProgressState.exceeded; // Between 100% and 200%
    return ProgressState.normal;
  }

  Color _getPercentageTextColor(ProgressState state) {
    if (state == ProgressState.empty) return Colors.transparent;
    // For Exceeded and Critical, text color might need to be more prominent against new arc colors
    switch (state) {
      case ProgressState.critical:
        return Colors.red.shade700;
      case ProgressState.exceeded:
        return Colors.orange.shade800; // Darker orange for text
      default:
        return const Color(0xFF003D7A);
    }
  }

  Color _getCurrentIntakeValueColor(ProgressState state) {
    if (state == ProgressState.empty) return Colors.transparent;

    if (widget.currentIntake < widget.target && widget.target > 0 && state == ProgressState.normal) {
      return Colors.red.shade600;
    }
    switch (state) {
      case ProgressState.critical:
        return Colors.red.shade800;
      case ProgressState.exceeded:
        return Colors.orange.shade700; // Orange for current intake value
      case ProgressState.normal:
        return const Color(0xFF007ACC);
      default:
        return const Color(0xFF005A8D);
    }
  }

  Color _getTargetUnitTextColor(ProgressState state) {
    if (state == ProgressState.empty) return Colors.transparent;
    switch (state) {
      case ProgressState.critical:
        return Colors.red.shade600.withOpacity(0.8);
      case ProgressState.exceeded:
        return Colors.orange.shade600.withOpacity(0.8);
      default:
        return const Color(0xFF005A8D).withOpacity(0.8);
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
              _progressDisplayController, // Drives arc and percentage text
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
                      // Pass the animated uncapped progress percentage
                      progressPercent: _progressDisplayAnimation.value,
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
    // Displayed percentage is capped at 100%
    final displayedPercentage = math.min(100.0, _progressDisplayAnimation.value.ceil());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${displayedPercentage.toInt()}%', // Use capped percentage
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
                color: _getCurrentIntakeValueColor(progressState),
                fontWeight: FontWeight.w600,
                fontSize: widget.screenWidth * 0.05,
                fontFamily: 'Roboto',
              ),
            ),
            Text(
              ' / ${widget.target.toInt()} mL',
              style: TextStyle(
                color: _getTargetUnitTextColor(progressState),
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
    // This remains the same as before
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.15,
          child: CustomPaint(
            painter: EmptyGlassPainter(screenWidth: widget.screenWidth),
            size: Size(widget.screenWidth * 0.25, widget.screenWidth * 0.35),
          ),
        ),
        Transform.translate(
          offset: Offset(_exclamationMarkMovementAnimation.value, -widget.screenWidth * 0.12),
          child: CustomPaint(
            painter: ExclamationPainter(screenWidth: widget.screenWidth, isLarge: true),
            size: Size(widget.screenWidth * 0.12, widget.screenWidth * 0.18),
          ),
        ),
      ],
    );
  }
}

// --- PAINTERS ---

class CircleBackgroundPainter extends CustomPainter {
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
  final double progressPercent; // Uncapped progress percentage (e.g., 0 to 200+)
  final double startAngleDegrees;
  final double sweepAngleDegrees;
  final ProgressState progressState;
  final double strokeWidth;

  ProgressArcPainter({
    required this.progressPercent,
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
    final startAngleRad = startAngleDegrees * (math.pi / 180.0);

    const Color normalColor = Color(0xFF007ACC);
    final Color exceededColor = Colors.orange.shade600;
    final Color criticalColor = Colors.red.shade600;
    Color currentIndicatorBorderColor = normalColor;

    if (progressState == ProgressState.empty) return;

    if (progressState == ProgressState.critical) {
      // Draw full red arc
      final criticalPaint = Paint()
        ..color = criticalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngleRad, sweepAngleDegrees * (math.pi / 180.0), false, criticalPaint);
      currentIndicatorBorderColor = criticalColor;
    } else if (progressState == ProgressState.exceeded) {
      // Draw full blue arc (0-100%)
      final bluePaint = Paint()
        ..color = normalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final fullBlueSweepRad = (sweepAngleDegrees * 100.0 / 100.0) * (math.pi / 180.0);
      canvas.drawArc(rect, startAngleRad, fullBlueSweepRad, false, bluePaint);

      // Draw orange arc for the exceeded part (100% up to 200%)
      final double orangeExcessPercent = progressPercent - 100.0;
      if (orangeExcessPercent > 0) {
        final orangePaint = Paint()
          ..color = exceededColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        // Orange arc starts where the full blue arc ends
        final double orangeStartAngleActualRad = startAngleRad + fullBlueSweepRad;
        final double orangeSweepActualRad = (sweepAngleDegrees * math.min(orangeExcessPercent, 100.0) / 100.0) * (math.pi / 180.0);
         if (orangeSweepActualRad > 0.001) {
            canvas.drawArc(rect, orangeStartAngleActualRad, orangeSweepActualRad, false, orangePaint);
        }
      }
      currentIndicatorBorderColor = exceededColor;
    } else { // Normal progress (0-100%)
      final normalPaint = Paint()
        ..color = normalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final currentSweepRad = (sweepAngleDegrees * progressPercent / 100.0) * (math.pi / 180.0);
      if (currentSweepRad > 0.001) {
        canvas.drawArc(rect, startAngleRad, currentSweepRad, false, normalPaint);
      }
      currentIndicatorBorderColor = normalColor;
    }

    // --- Indicator (Seeker) ---
    if (progressState == ProgressState.critical) {
      // Indicator at the start for critical state
      final seekAngle = startAngleRad;
      final seekX = center.dx + radius * math.cos(seekAngle);
      final seekY = center.dy + radius * math.sin(seekAngle);
      final seekFillPaint = Paint()..color = Colors.white;
      final seekBorderPaint = Paint()
        ..color = currentIndicatorBorderColor // Should be criticalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(seekX, seekY), strokeWidth * 0.25, seekFillPaint);
      canvas.drawCircle(Offset(seekX, seekY), strokeWidth * 0.25, seekBorderPaint);
    } else if (progressPercent > 0) {
      // For normal and exceeded, indicator follows the actual progressPercent (up to 200% for exceeded)
      final double effectiveProgressPercentForIndicator = math.min(progressPercent, 200.0);
      final double indicatorSweepRad = (sweepAngleDegrees * effectiveProgressPercentForIndicator / 100.0) * (math.pi / 180.0);
      final seekAngle = startAngleRad + indicatorSweepRad;
      final seekX = center.dx + radius * math.cos(seekAngle);
      final seekY = center.dy + radius * math.sin(seekAngle);

      final seekFillPaint = Paint()..color = Colors.white;
      final seekBorderPaint = Paint()
        ..color = currentIndicatorBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(seekX, seekY), strokeWidth * 0.25, seekFillPaint);
      canvas.drawCircle(Offset(seekX, seekY), strokeWidth * 0.25, seekBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) =>
      oldDelegate.progressPercent != progressPercent ||
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
    if (waterLevel <= 0.001 && progressState != ProgressState.empty) return; // Allow drawing if empty for background perhaps? No, water should be gone.
    if (progressState == ProgressState.empty && waterLevel <=0) return;


    final center = Offset(size.width / 2, size.height / 2);
    final waterRadius = math.min(size.width, size.height) / 2 - arcStrokeWidth - 3.0;

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: waterRadius));
    canvas.clipPath(clipPath);

    // Water level can visually go above 100% (e.g., 1.5 for 150%) for visual effect if desired,
    // but cappedWaterLevelForDrawing ensures it doesn't go excessively high for wave calculations.
    final cappedWaterLevelForDrawing = math.min(waterLevel, 1.5); // Cap at 150% for drawing water height
    final waterSurfaceY = size.height * (1 - cappedWaterLevelForDrawing);

    // Water color is always blue, regardless of ProgressState
    const Color gradLight = Color(0xFFA0E0FF);
    const Color gradDark = Color(0xFF4AA8FF);

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
      if (progressState == ProgressState.critical) { // No wave if critical
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

    // Foam
    if (progressState != ProgressState.critical && waterLevel > 0.05) {
      final foamPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

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
      Offset(size.width / 2, dotCenterY - (clampedBarHeight - barHeight)/2 ),
      clampedDotRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ExclamationPainter oldDelegate) =>
      oldDelegate.screenWidth != screenWidth || oldDelegate.isLarge != isLarge;
}
