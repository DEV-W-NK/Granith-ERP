import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/QuickActionsGrid.dart';
import 'package:project_granith/widgets/RecentActivityList.dart';
import 'package:project_granith/widgets/TransparencyBanner.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';
import 'package:project_granith/widgets/animations/home_header.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:project_granith/widgets/home_page/stats_grid.dart';
import 'package:provider/provider.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

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
    final isDesktop = MediaQuery.of(context).size.width > 800;

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
              padding: EdgeInsets.all(isDesktop ? 28 : 16),
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
                  const GranithReveal(
                    delay: Duration(milliseconds: 220),
                    child: TransparencyBanner(),
                  ),
                  const SizedBox(height: 14),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: GranithReveal(
                            delay: const Duration(milliseconds: 300),
                            child: RecentActivityList(
                              activities: viewModel.recentActivities,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          flex: 1,
                          child: GranithReveal(
                            delay: Duration(milliseconds: 380),
                            child: QuickActionsGrid(),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        GranithReveal(
                          delay: const Duration(milliseconds: 300),
                          child: RecentActivityList(
                            activities: viewModel.recentActivities,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const GranithReveal(
                          delay: Duration(milliseconds: 380),
                          child: QuickActionsGrid(),
                        ),
                      ],
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
