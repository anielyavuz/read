import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated progress bar with gradient fill and shimmer glow effect.
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final Duration animationDuration;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.backgroundColor,
    this.gradientColors,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.borderRadius,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _shimmerController;

  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();

    _fillController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fillAnimation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fillController.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _fillAnimation.value;
      _fillAnimation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
      );
      _fillController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final bgColor = widget.backgroundColor ?? AppColors.backgroundDark;
    final colors = widget.gradientColors ??
        [
          AppColors.primary,
          const Color(0xFF8B5CF6),
        ];

    return AnimatedBuilder(
      animation: Listenable.merge([_fillController, _shimmerController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _ProgressPainter(
            progress: _fillAnimation.value,
            shimmerProgress: _shimmerController.value,
            backgroundColor: bgColor,
            gradientColors: colors,
            borderRadius: radius,
          ),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
          ),
        );
      },
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final double shimmerProgress;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final BorderRadius borderRadius;

  _ProgressPainter({
    required this.progress,
    required this.shimmerProgress,
    required this.backgroundColor,
    required this.gradientColors,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    // Background
    canvas.drawRRect(bgRect, Paint()..color = backgroundColor);

    if (progress <= 0) return;

    final fillWidth = size.width * progress.clamp(0.0, 1.0);

    // Clip to rounded rect for fill
    canvas.save();
    canvas.clipRRect(bgRect);

    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);

    // Gradient fill
    final gradientPaint = Paint()
      ..shader = LinearGradient(colors: gradientColors).createShader(fillRect);
    canvas.drawRect(fillRect, gradientPaint);

    // Shimmer overlay — a bright highlight that sweeps across
    final shimmerWidth = size.width * 0.4;
    final shimmerX = -shimmerWidth + (size.width + shimmerWidth) * shimmerProgress;

    // Only draw shimmer within the filled area
    if (shimmerX < fillWidth) {
      final shimmerRect = Rect.fromLTWH(shimmerX, 0, shimmerWidth, size.height);
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(shimmerRect);
      canvas.drawRect(shimmerRect, shimmerPaint);
    }

    // Glow at the leading edge
    if (fillWidth > 2) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            gradientColors.last.withValues(alpha: 0.5),
            gradientColors.last.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(fillWidth, size.height / 2),
            radius: size.height * 1.5,
          ),
        );
      canvas.drawCircle(
        Offset(fillWidth, size.height / 2),
        size.height * 1.5,
        glowPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.shimmerProgress != shimmerProgress;
}
