import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class ActivityItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  static final List<ActivityItem> activities = [
    ActivityItem(
      title: 'Projeto Residencial Alpha',
      description: 'Orçamento aprovado pelo cliente',
      time: '2h atrás',
      icon: Icons.check_circle,
      color: AppColors.accentGreen,
    ),
    ActivityItem(
      title: 'Material de Construção',
      description: 'Estoque de cimento baixo (15%)',
      time: '4h atrás',
      icon: Icons.warning,
      color: AppColors.accentRed,
    ),
    ActivityItem(
      title: 'Equipe Bravo',
      description: 'Iniciou trabalho na obra Beta',
      time: '6h atrás',
      icon: Icons.groups,
      color: AppColors.accentBlue,
    ),
    ActivityItem(
      title: 'Pagamento Recebido',
      description: 'R\$ 85.000 - Projeto Gamma',
      time: '1d atrás',
      icon: Icons.payment,
      color: AppColors.accentGold,
    ),
    ActivityItem(
      title: 'Nova Proposta',
      description: 'Complexo comercial downtown',
      time: '2d atrás',
      icon: Icons.business,
      color: AppColors.accentBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atividades Recentes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navegar para página de atividades completa
                  },
                  child: const Text(
                    'Ver todas',
                    style: TextStyle(color: AppColors.accentGold, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de atividades
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder:
                  (context, index) =>
                      const Divider(color: AppColors.dividerColor, height: 1),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Ícone
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity.icon, color: activity.color, size: 16),
          ),

          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Tempo
          Text(
            activity.time,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
