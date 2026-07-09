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
            width: 310,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.primaryDark.withValues(alpha: 0.32),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.32),
                width: 1.4,
              ),
              boxShadow: [
                ...AppColors.glowShadows(AppColors.accentGold),
                ...AppColors.auraShadows(AppColors.accentGold),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/branding/granith_logo_wordmark.png',
                height: 118,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            settings.workspaceTagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
