import 'package:flutter/material.dart';
import 'package:project_granith/widgets/animations/home_header.dart';
import 'package:project_granith/widgets/home_page/home_charts_section.dart';
import 'package:project_granith/widgets/home_page/stats_grid.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/home_controller.dart';
import 'package:project_granith/themes/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Inicia a animação de entrada assim que a página é construída
    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return ChangeNotifierProvider(
      create: (_) => HomeController()..loadDashboardData(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 32 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com animação de fade
                HomeHeader(animationController: _contentController),
                
                const SizedBox(height: 24),
                
                // Banner de Transparência & Custos (clicável)
                _buildTransparencyBanner(context),
                
                const SizedBox(height: 32),
                
                // Grid de estatísticas com entrada staggered
                StatsGrid(
                  isDesktop: isDesktop,
                  animationController: _contentController,
                ),
                
                const SizedBox(height: 32),
                
                // Seção de gráficos e atividades
                HomeChartsSection(
                  isDesktop: isDesktop,
                  animationController: _contentController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransparencyBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/subscription');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentGold.withOpacity(0.2), AppColors.surfaceDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💰 Transparência & Custos', 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Visualize detalhamento de recursos e fatura estimada',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.accentGold, size: 20),
          ],
        ),
      ),
    );
  }
}