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
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [AppColors.accentGold, AppColors.accentGold.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.auto_awesome, color: AppColors.primaryDark),
        onPressed: () {
          // Trigger IA Analysis
        },
      ),
    );
  }
}