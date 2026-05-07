import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ViewModels e Themes
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

// Widgets específicos da Home
// Note: Ajustamos os caminhos dos imports para refletir a estrutura do seu projeto
import 'package:project_granith/widgets/QuickActionsGrid.dart';
import 'package:project_granith/widgets/RecentActivityList.dart';
import 'package:project_granith/widgets/TransparencyBanner.dart';
import 'package:project_granith/widgets/animations/home_header.dart';
import 'package:project_granith/widgets/home_page/stats_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Inicialização do controlador de animação para os headers e entradas
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Carregamento inicial dos dados via ViewModel
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
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadDashboardData(),
              color: AppColors.accentGold,
              backgroundColor: AppColors.surfaceDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: ResponsiveLayout.pagePadding(width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Repassando o controlador para o Widget de Header animado
                    HomeHeader(animationController: _animationController),

                    const SizedBox(height: 18),
                    StatsGrid(isDesktop: isDesktop, stats: viewModel.stats),

                    const SizedBox(height: 14),
                    const TransparencyBanner(),

                    const SizedBox(height: 14),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: RecentActivityList(
                              activities: viewModel.recentActivities,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(flex: 1, child: QuickActionsGrid()),
                        ],
                      )
                    else
                      Column(
                        children: [
                          RecentActivityList(
                            activities: viewModel.recentActivities,
                          ),
                          const SizedBox(height: 14),
                          const QuickActionsGrid(),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
