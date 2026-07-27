import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/QuickActionsGrid.dart';
import 'package:project_granith/widgets/RecentActivityList.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';
import 'package:project_granith/widgets/animations/home_header.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:project_granith/widgets/home_page/stats_grid.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'package:provider/provider.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({
    super.key,
    this.modules = const <NavigationModule>[],
    this.onModuleSelected,
  });

  final List<NavigationModule> modules;
  final ValueChanged<int>? onModuleSelected;

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > ResponsiveLayout.compact;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }

            return GranithPageBackground(
              scrollable: true,
              padding: ResponsiveLayout.pagePadding(width),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GranithReveal(
                    delay: const Duration(milliseconds: 40),
                    child: HomeHeader(
                      animationController: _animationController,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 120),
                    child: StatsGrid(
                      isDesktop: isDesktop,
                      stats: viewModel.stats,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GranithReveal(
                    delay: const Duration(milliseconds: 300),
                    child: RecentActivityList(
                      activities: viewModel.recentActivities,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 380),
                    child: QuickActionsGrid(
                      modules: widget.modules,
                      onModuleSelected: widget.onModuleSelected,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
