import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

enum TrendType { up, down, neutral }
enum ChartType { pie, line, bar }

class StatisticData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TrendType trend;
  final String trendValue;

  StatisticData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendValue,
  });
}

class ChartData {
  final String label;
  final double value;
  final Color? color;

  ChartData({
    required this.label,
    required this.value,
    this.color,
  });
}

class StatisticsModel {
  static List<StatisticData> get mainStats => [
    StatisticData(
      title: 'Projetos Ativos',
      value: '24',
      subtitle: 'Em andamento',
      icon: Icons.construction,
      color: AppColors.accentBlue,
      trend: TrendType.up,
      trendValue: '+3',
    ),
    StatisticData(
      title: 'Receita Mensal',
      value: 'R\$ 450K',
      subtitle: 'Este mês',
      icon: Icons.trending_up,
      color: AppColors.accentGreen,
      trend: TrendType.up,
      trendValue: '+12%',
    ),
    StatisticData(
      title: 'Materiais',
      value: '89%',
      subtitle: 'Em estoque',
      icon: Icons.inventory_2,
      color: AppColors.accentGold,
      trend: TrendType.down,
      trendValue: '-5%',
    ),
    StatisticData(
      title: 'Equipes',
      value: '18',
      subtitle: 'Trabalhando',
      icon: Icons.groups,
      color: AppColors.textSecondary,
      trend: TrendType.neutral,
      trendValue: '0',
    ),
  ];

  static List<ChartData> get projectStatusData => [
    ChartData(
      label: 'Em Andamento',
      value: 12,
      color: AppColors.accentBlue,
    ),
    ChartData(
      label: 'Planejamento',
      value: 6,
      color: AppColors.accentGold,
    ),
    ChartData(
      label: 'Finalizando',
      value: 4,
      color: AppColors.accentGreen,
    ),
    ChartData(
      label: 'Pausado',
      value: 2,
      color: AppColors.accentRed,
    ),
  ];

  static List<ChartData> get monthlyRevenueData => [
    ChartData(label: 'Jan', value: 320),
    ChartData(label: 'Fev', value: 280),
    ChartData(label: 'Mar', value: 390),
    ChartData(label: 'Abr', value: 420),
    ChartData(label: 'Mai', value: 380),
    ChartData(label: 'Jun', value: 450),
  ];
}