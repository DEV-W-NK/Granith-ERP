import 'package:flutter/material.dart';

class GranithReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final double beginScale;

  const GranithReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 720),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.06),
    this.beginScale = 0.985,
  });

  @override
  State<GranithReveal> createState() => _GranithRevealState();
}

class _GranithRevealState extends State<GranithReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(
      begin: widget.beginScale,
      end: 1,
    ).animate(curved);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}

class GranithPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double hoverScale;
  final double pressedScale;
  final Offset hoverOffset;

  const GranithPressable({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 180),
    this.hoverScale = 1.015,
    this.pressedScale = 0.985,
    this.hoverOffset = const Offset(0, -0.012),
  });

  @override
  State<GranithPressable> createState() => _GranithPressableState();
}

class _GranithPressableState extends State<GranithPressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final targetScale = _pressed
        ? widget.pressedScale
        : (_hovered ? widget.hoverScale : 1.0);
    final targetOffset = _hovered && !_pressed ? widget.hoverOffset : Offset.zero;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _pressed = false)
            : null,
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          offset: targetOffset,
          child: AnimatedScale(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            scale: targetScale,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
