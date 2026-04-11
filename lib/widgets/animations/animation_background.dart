import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const AnimatedBackground({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            _buildAmbientLight(
              top: -120 + (48 * controller.value),
              left: -60,
              color: AppColors.accentBlue.withValues(alpha: 0.12),
              size: 360,
            ),
            _buildAmbientLight(
              top: 120,
              right: -110 + (24 * controller.value),
              color: AppColors.auraCyan.withValues(alpha: 0.09),
              size: 320,
            ),
            _buildAmbientLight(
              bottom: -80,
              right: -120 + (40 * controller.value),
              color: AppColors.accentGold.withValues(alpha: 0.08),
              size: 380,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmbientLight({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 96, sigmaY: 96),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}
