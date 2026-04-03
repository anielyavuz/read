import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TimerDisplay extends StatefulWidget {
  final Duration elapsed;
  final Duration? target;
  final bool isRunning;
  final Color? ringColor;

  const TimerDisplay({
    super.key,
    required this.elapsed,
    this.target,
    this.isRunning = false,
    this.ringColor,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation: slow 4-second inhale/exhale cycle
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Ambient glow pulse: slightly offset timing for organic feel
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimations();
  }

  void _updateAnimations() {
    if (widget.isRunning) {
      if (!_breathController.isAnimating) {
        _breathController.repeat(reverse: true);
      }
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    } else {
      _breathController.stop();
      _breathController.value = 0.0;
      _glowController.stop();
      _glowController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.6;
    final color = widget.ringColor ?? AppColors.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnimation, _glowAnimation]),
      builder: (context, child) {
        final breathValue = _breathAnimation.value;
        final glowValue = _glowAnimation.value;

        return SizedBox(
          width: size + 40,
          height: size + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient glow behind the ring
              if (widget.isRunning)
                Container(
                  width: size + 20 + (glowValue * 16),
                  height: size + 20 + (glowValue * 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color
                            .withValues(alpha: 0.08 + glowValue * 0.12),
                        blurRadius: 30 + glowValue * 20,
                        spreadRadius: 4 + glowValue * 8,
                      ),
                    ],
                  ),
                ),
              // Timer ring + text
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _TimerRingPainter(
                    progress: _progress,
                    ringColor: color,
                    trackColor: AppColors.surfaceDark,
                    breathValue: breathValue,
                    isRunning: widget.isRunning,
                    hasTarget: widget.target != null,
                  ),
                  child: Center(
                    child: Text(
                      _displayText,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary.withValues(
                          alpha: widget.isRunning
                              ? 0.85 + breathValue * 0.15
                              : 1.0,
                        ),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double get _progress {
    if (widget.target == null || widget.target!.inSeconds == 0) {
      return 0.0;
    }
    final p = widget.elapsed.inSeconds / widget.target!.inSeconds;
    return p.clamp(0.0, 1.0);
  }

  String get _displayText {
    if (widget.target != null) {
      final remaining = widget.target! - widget.elapsed;
      if (remaining.isNegative) return '00:00';
      return _formatDuration(remaining);
    }
    return _formatDuration(widget.elapsed);
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double breathValue;
  final bool isRunning;
  final bool hasTarget;

  _TimerRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.breathValue,
    required this.isRunning,
    required this.hasTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 6.0;

    // Track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Progress arc (target mode)
      final progressPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );

      // Breathing outer glow on top of progress arc
      if (isRunning) {
        final glowPaint = Paint()
          ..color = ringColor.withValues(alpha: breathValue * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6 + breathValue * 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          2 * pi * progress,
          false,
          glowPaint,
        );
      }
    } else if (isRunning) {
      // Free mode: breathing ring
      final ringAlpha = 0.4 + breathValue * 0.6;
      final ringWidth = strokeWidth + breathValue * 3;

      final breathPaint = Paint()
        ..color = ringColor.withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, breathPaint);

      // Outer breathing glow ring
      final outerRadius = radius + 4 + breathValue * 8;
      final outerGlowPaint = Paint()
        ..color = ringColor.withValues(alpha: breathValue * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + breathValue * 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, outerRadius, outerGlowPaint);

      // Inner subtle glow
      final innerGlowPaint = Paint()
        ..color = ringColor.withValues(alpha: breathValue * 0.06)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(center, radius * 0.85, innerGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.breathValue != breathValue ||
        oldDelegate.isRunning != isRunning;
  }
}
