import 'dart:math' as math;
import 'dart:ui';

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
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.appBackgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: _AuraLayer(animation: _controller)),
          ),
          widget.child,
        ],
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

class _AuraLayer extends StatelessWidget {
  final Animation<double> animation;

  const _AuraLayer({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _AuraOrb(
          animation: animation,
          alignment: Alignment.topLeft,
          size: 340,
          color: AppColors.duskBlue,
          dx: -90,
          dy: -60,
          phase: 0.0,
        ),
        _AuraOrb(
          animation: animation,
          alignment: Alignment.topRight,
          size: 280,
          color: AppColors.accentGold,
          dx: 90,
          dy: -110,
          phase: 0.9,
        ),
        _AuraOrb(
          animation: animation,
          alignment: Alignment.centerRight,
          size: 360,
          color: AppColors.auraCyan,
          dx: 160,
          dy: 40,
          phase: 2.2,
        ),
        _AuraOrb(
          animation: animation,
          alignment: Alignment.bottomLeft,
          size: 320,
          color: AppColors.auraBlue,
          dx: -110,
          dy: 120,
          phase: 3.0,
        ),
      ],
    );
  }
}

class _AuraOrb extends StatelessWidget {
  final Animation<double> animation;
  final Alignment alignment;
  final double size;
  final Color color;
  final double dx;
  final double dy;
  final double phase;

  const _AuraOrb({
    required this.animation,
    required this.alignment,
    required this.size,
    required this.color,
    required this.dx,
    required this.dy,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final wave = math.sin((animation.value * math.pi * 2) + phase);
        final driftX = dx + (wave * 18);
        final driftY =
            dy + (math.cos((animation.value * math.pi * 2) + phase) * 14);
        final scale = 0.96 + ((wave + 1) * 0.025);

        return Align(
          alignment: alignment,
          child: Transform.translate(
            offset: Offset(driftX, driftY),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ),
      ),
    );
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
          ..color = Colors.white.withValues(alpha: 0.018)
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
