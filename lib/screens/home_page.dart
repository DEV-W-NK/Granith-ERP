import 'package:flutter/material.dart';
import 'package:project_granith/models/statistics_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/chart_card.dart';
import 'package:project_granith/widgets/recent_activities.dart';
import 'package:project_granith/widgets/stat_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Estatísticas principais
            _buildMainStats(isDesktop),
            
            const SizedBox(height: 24),
            
            // Gráficos e atividades recentes
            _buildChartsAndActivities(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Visão geral das suas obras e projetos',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildMainStats(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 4 : 2;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.5 : 1.3,
          ),
          itemCount: StatisticsModel.mainStats.length,
          itemBuilder: (context, index) {
            final stat = StatisticsModel.mainStats[index];
            return StatCard(
              title: stat.title,
              value: stat.value,
              subtitle: stat.subtitle,
              icon: stat.icon,
              color: stat.color,
              trend: stat.trend,
              trendValue: stat.trendValue,
            );
          },
        );
      },
    );
  }

  Widget _buildChartsAndActivities(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildCharts(),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: const RecentActivities(),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildCharts(),
          const SizedBox(height: 24),
          const RecentActivities(),
        ],
      );
    }
  }

  Widget _buildCharts() {
    return Column(
      children: [
        ChartCard(
          title: 'Projetos por Status',
          subtitle: 'Distribuição dos projetos ativos',
          chartData: StatisticsModel.projectStatusData,
          chartType: ChartType.pie,
        ),
        const SizedBox(height: 24),
        ChartCard(
          title: 'Receita Mensal',
          subtitle: 'Evolução da receita nos últimos 6 meses',
          chartData: StatisticsModel.monthlyRevenueData,
          chartType: ChartType.line,
        ),
      ],
    );
  }
}