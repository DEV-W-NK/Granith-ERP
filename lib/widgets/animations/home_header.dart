import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatelessWidget {
  final AnimationController animationController;

  const HomeHeader({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;
    final fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < ResponsiveLayout.compact;
          final titleStyle = Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 22 : null,
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.dashboardGreetingTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.dashboardGreetingSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (settings.aiAssistantPreviewEnabled) ...[
                const SizedBox(width: 12),
                _buildAiButton(context),
              ],
            ],
          );
        },
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
