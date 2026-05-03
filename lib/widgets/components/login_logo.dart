import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class LoginLogo extends StatelessWidget {
  final AnimationController parentController;

  const LoginLogo({super.key, required this.parentController});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.95),
                  AppColors.auraCyan.withValues(alpha: 0.78),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.4,
              ),
              boxShadow: [
                ...AppColors.glowShadows(AppColors.accentBlue),
                ...AppColors.auraShadows(AppColors.accentBlue),
              ],
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 64,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            settings.workspaceName.toUpperCase(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            settings.workspaceTagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}
