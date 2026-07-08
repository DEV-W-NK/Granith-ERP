import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const AnimatedBackground({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (context, child) => RepaintBoundary(
            child: CustomPaint(
              painter: _LoginBackdropPainter(progress: controller.value),
              child: const SizedBox.expand(),
            ),
          ),
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  final double progress;

  const _LoginBackdropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(progress * math.pi * 2);
    final width = size.width;
    final height = size.height;

    final topPanel =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x2441D9BE), Color(0x00000000)],
          ).createShader(Rect.fromLTWH(0, 0, width, height * 0.62));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height * 0.62), topPanel);

    final warmPanel =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [Color(0x1AE3B84A), Color(0x00000000)],
          ).createShader(Rect.fromLTWH(0, height * 0.35, width, height * 0.65));
    canvas.drawRect(
      Rect.fromLTWH(0, height * 0.35, width, height * 0.65),
      warmPanel,
    );

    final bandPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x0041D9BE), Color(0x1841D9BE), Color(0x00E3B84A)],
          ).createShader(Rect.fromLTWH(0, 0, width, height));

    final shift = wave * 28;
    final band =
        Path()
          ..moveTo(-80 + shift, height * 0.14)
          ..lineTo(width * 0.42 + shift, height * 0.04)
          ..lineTo(width + 90 + shift, height * 0.78)
          ..lineTo(width * 0.64 + shift, height * 0.94)
          ..close();
    canvas.drawPath(band, bandPaint);

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.032);
    for (double x = -height; x < width + height; x += 140) {
      canvas.drawLine(
        Offset(x - shift, height),
        Offset(x + height * 0.46 - shift, 0),
        linePaint,
      );
    }

    final accentPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = AppColors.auraCyan.withValues(alpha: 0.13);
    canvas.drawLine(
      Offset(width * 0.08, height * 0.22),
      Offset(width * 0.82, height * 0.08),
      accentPaint,
    );

    final goldPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.accentGold.withValues(alpha: 0.10);
    canvas.drawLine(
      Offset(width * 0.30, height * 0.98),
      Offset(width * 0.94, height * 0.30),
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
