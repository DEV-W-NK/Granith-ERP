import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

// Enum para tendência
enum TrendType { up, down, neutral }

// Classe de dados para os cards de estatística
class StatItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TrendType trend;
  final String trendValue;

  StatItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendValue,
  });
}

class StatisticsModel {
  // Dados para o Gráfico de Pizza (Status dos Projetos)
  static const Map<String, double> projectStatusData = {
    'Em Andamento': 45.0,
    'Concluídos': 30.0,
    'Atrasados': 15.0,
    'Planejamento': 10.0,
  };

  // Dados para o Gráfico de Linha (Receita)
  static const List<double> monthlyRevenueData = [
    120000.0,
    135000.0,
    128000.0,
    150000.0,
    142000.0,
    180000.0,
  ];

  // Adicionando a lista mainStats que estava faltando para o Controller
  static List<StatItem> get mainStats => [
    StatItem(
      title: 'Obras Ativas',
      value: '12',
      subtitle: '3 com prazo crítico',
      icon: Icons.construction,
      color: AppColors.accentGold,
      trend: TrendType.up,
      trendValue: '+2',
    ),
    StatItem(
      title: 'Funcionários',
      value: '48',
      subtitle: '42 presentes hoje',
      icon: Icons.engineering,
      color: AppColors.accentBlue,
      trend: TrendType.neutral,
      trendValue: '0',
    ),
    StatItem(
      title: 'Gastos (Mês)',
      value: 'R\$ 142k',
      subtitle: '85% do orçamento',
      icon: Icons.attach_money,
      color: AppColors.accentRed,
      trend: TrendType.down,
      trendValue: '12%',
    ),
    StatItem(
      title: 'Materiais',
      value: '350',
      subtitle: 'Itens em estoque baixo',
      icon: Icons.inventory_2,
      color: AppColors.accentGreen,
      trend: TrendType.down,
      trendValue: '-5',
    ),
  ];
}
