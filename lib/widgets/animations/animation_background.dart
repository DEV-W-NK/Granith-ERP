import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

/// Widget especializado na renderização do fundo dinâmico.
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
              top: -100 + (50 * controller.value),
              left: -50,
              color: AppColors.accentGold.withOpacity(0.05),
              size: 300,
            ),
            _buildAmbientLight(
              bottom: -50,
              right: -100 + (30 * controller.value),
              color: AppColors.accentGold.withOpacity(0.03),
              size: 400,
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}