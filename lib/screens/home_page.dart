import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/QuickActionsGrid.dart';
import 'package:project_granith/widgets/RecentActivityList.dart';
import 'package:project_granith/widgets/TransparencyBanner.dart';
import 'package:project_granith/widgets/animations/home_header.dart';
import 'package:project_granith/widgets/home_page/stats_grid.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// 1. Adicionado o "with SingleTickerProviderStateMixin"
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // 2. Criada a variável do controlador
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    // 3. Inicializado o controlador (ajuste a duração se necessário para o seu padrão)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadDashboardData();
    });
  }

  // 4. Importante: Limpar o controlador da memória quando a página for fechada
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.bg, // Token legado, trocar por backgroundDark futuramente
      body: SafeArea(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold));
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 28 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 5. Removido o 'const' e repassado o _animationController para o seu widget
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
                                activities: viewModel.recentActivities)),
                        const SizedBox(width: 14),
                        const Expanded(flex: 1, child: QuickActionsGrid()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        RecentActivityList(activities: viewModel.recentActivities),
                        const SizedBox(height: 14),
                        const QuickActionsGrid(),
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