import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/components/granith_brand.dart';
import 'package:provider/provider.dart';

class LoginLogo extends StatelessWidget {
  final AnimationController parentController;

  const LoginLogo({super.key, required this.parentController});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;
    final logoWidth = (MediaQuery.sizeOf(context).width * 0.72).clamp(
      220.0,
      310.0,
    );
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
          GranithWordmark(width: logoWidth, height: 108),
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
