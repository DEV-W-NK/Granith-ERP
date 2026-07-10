import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class GranithAppBackdrop extends StatefulWidget {
  final Widget child;

  const GranithAppBackdrop({super.key, required this.child});

  @override
  State<GranithAppBackdrop> createState() => _GranithAppBackdropState();
}

class _GranithAppBackdropState extends State<GranithAppBackdrop>
    with SingleTickerProviderStateMixin {
  static const bool _animateWebBackdrop = bool.fromEnvironment(
    'GRANITH_ANIMATE_WEB_BACKDROP',
    defaultValue: false,
  );

  late final AnimationController _controller;
  late final bool _shouldAnimate;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = !kIsWeb || _animateWebBackdrop;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
      value: 0.38,
    );

    if (_shouldAnimate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: _AtmosphereLayer(animation: _controller),
              ),
            ),
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class GranithPageBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const GranithPageBackground({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: _SoftGridOverlay())),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.015),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (scrollable)
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: content,
          )
        else
          content,
      ],
    );
  }
}

class _AtmosphereLayer extends StatelessWidget {
  final Animation<double> animation;

  const _AtmosphereLayer({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder:
          (context, _) => IgnorePointer(
            child: CustomPaint(
              painter: _AtmospherePainter(progress: animation.value),
            ),
          ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final double progress;

  const _AtmospherePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(progress * math.pi * 2);
    final width = size.width;
    final height = size.height;

    final topWash =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x2441D9BE), Color(0x00000000)],
          ).createShader(Rect.fromLTWH(0, 0, width, height * 0.46));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height * 0.46), topWash);

    final lowerWash =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [Color(0x1FE3B84A), Color(0x00000000)],
          ).createShader(Rect.fromLTWH(0, height * 0.46, width, height * 0.54));
    canvas.drawRect(
      Rect.fromLTWH(0, height * 0.46, width, height * 0.54),
      lowerWash,
    );

    final diagonalPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.026);
    final offset = wave * 18;
    for (double x = -height; x < width + height; x += 172) {
      canvas.drawLine(
        Offset(x + offset, height),
        Offset(x + height * 0.42 + offset, 0),
        diagonalPaint,
      );
    }

    final architecturalBand =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x0041D9BE), Color(0x1241D9BE), Color(0x00E3B84A)],
          ).createShader(Rect.fromLTWH(0, 0, width, height));
    final bandPath =
        Path()
          ..moveTo(width * 0.08, height * 0.16)
          ..lineTo(width * 0.42, height * 0.08)
          ..lineTo(width * 0.92, height * 0.82)
          ..lineTo(width * 0.70, height * 0.92)
          ..close();
    canvas.drawPath(bandPath, architecturalBand);

    final goldLine =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.accentGold.withValues(alpha: 0.06);
    canvas.drawLine(
      Offset(width * 0.18, 0),
      Offset(width * 0.72, height),
      goldLine,
    );

    final cyanLine =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.auraCyan.withValues(alpha: 0.055);
    canvas.drawLine(
      Offset(width * 0.82, 0),
      Offset(width * 0.42, height),
      cyanLine,
    );

    final tickPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.borderColor.withValues(alpha: 0.28);
    for (double y = height * 0.18; y < height; y += 132) {
      canvas.drawLine(Offset(width - 96, y), Offset(width - 48, y), tickPaint);
      canvas.drawLine(
        Offset(width - 48, y),
        Offset(width - 48, y + 26),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SoftGridOverlay extends StatelessWidget {
  const _SoftGridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SoftGridPainter());
  }
}

class _SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.014)
          ..strokeWidth = 1;

    const gap = 48.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
