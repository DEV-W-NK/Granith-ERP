import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final AnimationController animationController;

  const HomeHeader({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, Gestor',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aqui está o panorama atual das suas obras.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Botão de IA (Preview do que está por vir)
          _buildAiButton(context),
        ],
      ),
    );
  }

  Widget _buildAiButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.accentBlue,
            AppColors.auraCyan.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: AppColors.auraShadows(AppColors.accentBlue),
      ),
      child: IconButton(
        icon: const Icon(Icons.auto_awesome, color: AppColors.textPrimary),
        onPressed: () {
          // Trigger IA Analysis
        },
      ),
    );
  }
}
