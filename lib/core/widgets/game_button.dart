import 'package:flutter/material.dart';

/// A Duolingo-style 3D button with a bottom shadow that creates a raised look.
/// On press the button translates down and the shadow shrinks; on release it
/// bounces back. Only [Transform] and [BoxShadow] change per frame — layout
/// is completely static, avoiding semantics / hasSize assertions.
class GameButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? shadowColor;
  final double shadowHeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final BoxBorder? border;

  const GameButton({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.shadowColor,
    this.shadowHeight = 6,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.border,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _pressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.bounceOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? const Color(0xFF1E1E2E);
    final shadow = widget.shadowColor ??
        HSLColor.fromColor(bgColor)
            .withLightness(
              (HSLColor.fromColor(bgColor).lightness - 0.08).clamp(0, 1),
            )
            .toColor();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      // Static bottom margin reserves space for the shadow so it never
      // overlaps neighbouring widgets. This value NEVER changes.
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.shadowHeight),
        child: AnimatedBuilder(
          animation: _pressAnimation,
          builder: (context, child) {
            final t = _pressAnimation.value.clamp(0.0, 1.0);

            return Transform.translate(
              offset: Offset(0, widget.shadowHeight * t),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.gradient != null ? null : bgColor,
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: widget.border,
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      offset: Offset(0, widget.shadowHeight * (1 - t)),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
