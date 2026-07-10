import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: widget.beginScale, end: 1).animate(curved);

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
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

typedef GranithPressableBuilder =
    Widget Function(BuildContext context, GranithPressableSnapshot state);

class GranithPressableSnapshot {
  final bool hovered;
  final bool pressed;
  final bool selected;
  final double glowProgress;

  const GranithPressableSnapshot({
    required this.hovered,
    required this.pressed,
    required this.selected,
    required this.glowProgress,
  });

  bool get active => hovered || pressed || selected;
}

class GranithPressable extends StatefulWidget {
  final Widget child;
  final GranithPressableBuilder? builder;
  final VoidCallback? onTap;
  final Duration duration;
  final double hoverScale;
  final double pressedScale;
  final Offset hoverOffset;
  final bool selected;
  final bool premium;
  final Color premiumColor;
  final BorderRadiusGeometry borderRadius;

  const GranithPressable({
    super.key,
    required this.child,
    this.onTap,
    this.builder,
    this.duration = const Duration(milliseconds: 180),
    this.hoverScale = 1.015,
    this.pressedScale = 0.985,
    this.hoverOffset = const Offset(0, -0.012),
    this.selected = false,
    this.premium = false,
    this.premiumColor = AppColors.accentGold,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<GranithPressable> createState() => _GranithPressableState();
}

class _GranithPressableState extends State<GranithPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final canTap = widget.onTap != null;
    final targetScale =
        disableAnimations
            ? 1.0
            : (_pressed
                ? widget.pressedScale
                : (_hovered && canTap ? widget.hoverScale : 1.0));
    final targetOffset =
        disableAnimations || !canTap || !_hovered || _pressed
            ? Offset.zero
            : widget.hoverOffset;

    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter:
          canTap
              ? (_) => setState(() {
                _hovered = true;
                if (widget.premium && !disableAnimations) {
                  _glowController.forward(from: 0);
                }
              })
              : null,
      onExit:
          canTap
              ? (_) => setState(() {
                _hovered = false;
                _pressed = false;
                if (!widget.selected) {
                  _glowController.stop();
                  _glowController.value = 0;
                }
              })
              : null,
      child: GestureDetector(
        behavior:
            canTap ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
        onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          offset: targetOffset,
          child: AnimatedScale(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            scale: targetScale,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                final snapshot = GranithPressableSnapshot(
                  hovered: _hovered,
                  pressed: _pressed,
                  selected: widget.selected,
                  glowProgress: _glowController.value,
                );
                final content =
                    widget.builder?.call(context, snapshot) ?? widget.child;

                if (!widget.premium || !canTap && !widget.selected) {
                  return content;
                }

                return RepaintBoundary(
                  child: Stack(
                    children: [
                      content,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            opacity: snapshot.active ? 1 : 0,
                            child: CustomPaint(
                              painter: _PremiumBorderPainter(
                                color: widget.premiumColor,
                                radius: _resolveRadius(context),
                                progress:
                                    disableAnimations
                                        ? 1
                                        : snapshot.glowProgress,
                                selected: widget.selected,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _resolveRadius(BuildContext context) {
    return widget.borderRadius.resolve(Directionality.of(context)).topLeft.x;
  }
}

class GranithPremiumIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final double progress;
  final double size;
  final double iconSize;
  final double radius;

  const GranithPremiumIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.active = false,
    this.progress = 0,
    this.size = 36,
    this.iconSize = 18,
    this.radius = 11,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveProgress = disableAnimations ? 1.0 : progress;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: color.withValues(alpha: active ? 0.48 : 0.20),
              ),
              boxShadow: active ? AppColors.auraShadows(color) : null,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          if (active)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _IconGlintPainter(
                    color: AppColors.accentGold,
                    radius: radius,
                    progress: effectiveProgress,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double progress;
  final bool selected;

  const _PremiumBorderPainter({
    required this.color,
    required this.radius,
    required this.progress,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final basePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.45 : 1.25
          ..color = color.withValues(alpha: selected ? 0.56 : 0.38);
    canvas.drawRRect(rrect, basePaint);

    if (progress <= 0) return;

    final glowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.2
          ..color = color.withValues(alpha: 0.92)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);

    final sparklePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: 0.72);

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      final segment = math.max(24.0, length * 0.18);
      final start = (length * progress) % length;
      _drawMetricSegment(canvas, metric, start, segment, glowPaint);
      _drawMetricSegment(
        canvas,
        metric,
        start + 4,
        segment * 0.42,
        sparklePaint,
      );
    }
  }

  void _drawMetricSegment(
    Canvas canvas,
    PathMetric metric,
    double start,
    double length,
    Paint paint,
  ) {
    final metricLength = metric.length;
    final normalizedStart = start % metricLength;
    final end = normalizedStart + length;

    if (end <= metricLength) {
      canvas.drawPath(metric.extractPath(normalizedStart, end), paint);
      return;
    }

    canvas
      ..drawPath(metric.extractPath(normalizedStart, metricLength), paint)
      ..drawPath(metric.extractPath(0, end - metricLength), paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.progress != progress ||
        oldDelegate.selected != selected;
  }
}

class _IconGlintPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double progress;

  const _IconGlintPainter({
    required this.color,
    required this.radius,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..color = color.withValues(alpha: 0.82)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      final start = (length * progress) % length;
      final segment = math.max(10.0, length * 0.24);
      final end = start + segment;

      if (end <= length) {
        canvas.drawPath(metric.extractPath(start, end), paint);
      } else {
        canvas
          ..drawPath(metric.extractPath(start, length), paint)
          ..drawPath(metric.extractPath(0, end - length), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IconGlintPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.progress != progress;
  }
}
