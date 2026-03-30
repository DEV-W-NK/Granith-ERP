import 'package:flutter/material.dart';
import 'package:project_granith/constants/GranitTokens.dart';

// =============================================================================
// GRANIT STAT CARD
// Card de KPI com barra de accent colorida, label, valor e indicador de delta.
// Substitui _StatCard inline da ReportsPage — agora exportado globalmente.
//
// USO TÍPICO:
//   GranitStatCard(
//     label: 'RECEITA TOTAL',
//     value: 'R$ 420k',
//     delta: '+12% vs mês anterior',
//     deltaPositive: true,
//     accent: GranitTokens.green,
//   )
//
// COM ÍCONE OPCIONAL:
//   GranitStatCard(
//     label: 'PROJETOS ATIVOS',
//     value: '7',
//     delta: '+2 este mês',
//     deltaPositive: true,
//     accent: GranitTokens.blue,
//     icon: Icons.folder_open_rounded,
//   )
// =============================================================================

class GranitStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final Color accent;
  final IconData? icon;
  final VoidCallback? onTap;

  const GranitStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.accent,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: GranitTokens.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent bar
            Container(
              width: 28, height: 2,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),

            // Label
            Text(label, style: GranitTokens.labelSmall),
            const SizedBox(height: 5),

            // Value
            Text(
              value,
              style: GranitTokens.valueStyle.copyWith(color: accent),
            ),
            const SizedBox(height: 4),

            // Delta
            Row(children: [
              Icon(
                deltaPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: deltaPositive ? GranitTokens.green : GranitTokens.red,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  delta,
                  style: TextStyle(
                    color: deltaPositive ? GranitTokens.green : GranitTokens.red,
                    fontSize: 10,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// GRANIT STAT CARD SKELETON
// Placeholder animado enquanto os dados carregam.
// =============================================================================

class GranitStatCardSkeleton extends StatefulWidget {
  const GranitStatCardSkeleton({super.key});

  @override
  State<GranitStatCardSkeleton> createState() => _GranitStatCardSkeletonState();
}

class _GranitStatCardSkeletonState extends State<GranitStatCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bone(double w, double h) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: w, height: h,
          decoration: BoxDecoration(
            color: GranitTokens.surface3.withOpacity(_anim.value),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: GranitTokens.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bone(28, 2),
          const SizedBox(height: 10),
          _bone(60, 9),
          const SizedBox(height: 5),
          _bone(100, 18),
          const SizedBox(height: 4),
          _bone(80, 9),
        ],
      ),
    );
  }
}