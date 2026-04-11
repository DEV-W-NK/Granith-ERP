import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class GranithAppBackdrop extends StatelessWidget {
  final Widget child;

  const GranithAppBackdrop({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appBackgroundGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: _AuraLayer()),
          child,
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
    final content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

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
  const _AuraLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _AuraOrb(
          alignment: Alignment.topLeft,
          size: 340,
          color: AppColors.duskBlue,
          dx: -90,
          dy: -60,
        ),
        _AuraOrb(
          alignment: Alignment.topRight,
          size: 280,
          color: AppColors.accentGold,
          dx: 90,
          dy: -110,
        ),
        _AuraOrb(
          alignment: Alignment.centerRight,
          size: 360,
          color: AppColors.auraCyan,
          dx: 160,
          dy: 40,
        ),
        _AuraOrb(
          alignment: Alignment.bottomLeft,
          size: 320,
          color: AppColors.auraBlue,
          dx: -110,
          dy: 120,
        ),
      ],
    );
  }
}

class _AuraOrb extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;
  final double dx;
  final double dy;

  const _AuraOrb({
    required this.alignment,
    required this.size,
    required this.color,
    required this.dx,
    required this.dy,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(dx, dy),
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
      ),
    );
  }
}

class _SoftGridOverlay extends StatelessWidget {
  const _SoftGridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SoftGridPainter(),
    );
  }
}

class _SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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
