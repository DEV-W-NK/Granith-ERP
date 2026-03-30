import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

// Entidades de UI temporárias (depois devem vir do Domain mapeadas)
class StatItem {
  final String label;
  final String value;
  final String delta;
  final bool deltaUp;
  final Color accent;
  final IconData icon;

  StatItem({required this.label, required this.value, required this.delta, required this.deltaUp, required this.accent, required this.icon});
}

class ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String time;
  final bool isPositive;

  ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    required this.isPositive,
  });
}

class HomeViewModel extends ChangeNotifier {
  bool isLoading = true;
  List<StatItem> stats = [];
  List<ActivityItem> recentActivities = [];

  Future<void> loadDashboardData() async {
    isLoading = true;
    notifyListeners();

    // Simulação de chamada de UseCase/Repository (Domain/Data)
    await Future.delayed(const Duration(milliseconds: 800));

    stats = [
      StatItem(label: 'RECEITA DO MÊS', value: 'R\$ 84.500', delta: '+12,3% vs mês anterior', deltaUp: true, accent: AppColors.green, icon: Icons.trending_up_rounded),
      StatItem(label: 'DESPESAS DO MÊS', value: 'R\$ 61.200', delta: '+4,1% vs mês anterior', deltaUp: false, accent: AppColors.red, icon: Icons.trending_down_rounded),
      StatItem(label: 'SALDO ATUAL', value: 'R\$ 23.300', delta: 'Margem 27,6%', deltaUp: true, accent: AppColors.gold, icon: Icons.account_balance_wallet_rounded),
      StatItem(label: 'CLIENTES ATIVOS', value: '142', delta: '+8 novos este mês', deltaUp: true, accent: AppColors.blue, icon: Icons.people_outline_rounded),
    ];

    recentActivities = [
      ActivityItem(icon: Icons.arrow_downward_rounded, iconColor: AppColors.green, title: 'Pagamento recebido — Cliente A', subtitle: '+ R\$ 8.400', value: '', time: 'Hoje, 14:32', isPositive: true),
      ActivityItem(icon: Icons.arrow_upward_rounded, iconColor: AppColors.red, title: 'Fornecedor — Nota fiscal #1821', subtitle: '− R\$ 2.100', value: '', time: 'Hoje, 11:05', isPositive: false),
      ActivityItem(icon: Icons.arrow_downward_rounded, iconColor: AppColors.green, title: 'Assinatura mensal — Cliente B', subtitle: '+ R\$ 3.200', value: '', time: 'Ontem, 18:00', isPositive: true),
      ActivityItem(icon: Icons.arrow_upward_rounded, iconColor: AppColors.orange, title: 'Aluguel escritório — Mar/25', subtitle: '− R\$ 4.500', value: '', time: 'Ontem, 09:15', isPositive: false),
    ];

    isLoading = false;
    notifyListeners();
  }
}