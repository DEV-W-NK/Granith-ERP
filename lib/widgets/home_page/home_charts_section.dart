import 'package:flutter/material.dart';
import 'package:project_granith/widgets/components/chart_card.dart';
import 'package:project_granith/models/statistics_model.dart'; // Importação limpa
import 'package:project_granith/widgets/home_page/recent_activities.dart';

class HomeChartsSection extends StatelessWidget {
  final bool isDesktop;
  final AnimationController animationController;

  const HomeChartsSection({
    super.key,
    required this.isDesktop,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // Animação de entrada
    final sectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: sectionAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(sectionAnimation),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna Principal (Gráficos) - Ocupa mais espaço (5/8)
        Expanded(flex: 5, child: _buildChartsList()),
        // Espaçamento generoso para não colar as informações
        const SizedBox(width: 32),
        // Coluna Lateral (Atividades) - Ocupa menos espaço (3/8), mas suficiente para leitura
        const Expanded(flex: 3, child: RecentActivities()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildChartsList(),
        const SizedBox(height: 24), // Espaçamento vertical padrão para mobile
        const RecentActivities(),
      ],
    );
  }

  Widget _buildChartsList() {
    return Column(
      children: [
        ChartCard(
          title: 'Projetos por Status',
          subtitle: 'Distribuição dos projetos ativos no momento',
          chartData: StatisticsModel.projectStatusData,
          chartType: ChartType.pie,
        ),
        // Espaçamento condicional: No desktop, damos mais respiro entre os gráficos
        SizedBox(height: isDesktop ? 32 : 24),
        ChartCard(
          title: 'Evolução Financeira',
          subtitle: 'Receita vs Despesas (Últimos 6 meses)',
          chartData: StatisticsModel.monthlyRevenueData,
          chartType: ChartType.line,
        ),
      ],
    );
  }
}
