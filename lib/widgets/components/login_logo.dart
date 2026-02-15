import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

/// Componente de Logo com animação de escala.
class LoginLogo extends StatelessWidget {
  final AnimationController parentController;

  const LoginLogo({super.key, required this.parentController});

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: parentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.home_work_outlined, size: 64, color: AppColors.accentGold),
          ),
          const SizedBox(height: 24),
          Text(
            'GRANITH',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
    );
  }
}