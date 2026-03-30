import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/AppCard.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppCardTitle('Ações rápidas'),
        Row(children: [
          Expanded(child: _buildQuickAction(
            context: context,
            icon: Icons.add_rounded, label: 'Nova receita', color: AppColors.green,
            route: '/nova-receita',
          )),
          const SizedBox(width: 8),
          Expanded(child: _buildQuickAction(
            context: context,
            icon: Icons.remove_rounded, label: 'Nova despesa', color: AppColors.red,
            route: '/nova-despesa',
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildQuickAction(
            context: context,
            icon: Icons.bar_chart_rounded, label: 'Ver DRE', color: AppColors.gold,
            route: '/reports',
          )),
          const SizedBox(width: 8),
          Expanded(child: _buildQuickAction(
            context: context,
            icon: Icons.people_outline_rounded, label: 'Clientes', color: AppColors.blue,
            route: '/clientes',
          )),
        ]),
        const SizedBox(height: 8),
        _buildSystemStatus(),
      ]),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.s2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 7),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.tx2, fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.s2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.green.withOpacity(0.5),
                  blurRadius: 4, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Todos os sistemas operacionais',
              style: TextStyle(color: AppColors.tx2, fontSize: 10)),
        ),
        const Text('Atualizado agora',
            style: TextStyle(color: AppColors.tx3, fontSize: 9)),
      ]),
    );
  }
}