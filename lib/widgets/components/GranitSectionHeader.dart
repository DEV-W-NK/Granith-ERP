import 'package:flutter/material.dart';
import 'package:project_granith/constants/GranitTokens.dart';

// =============================================================================
// GRANIT SECTION HEADER
// Cabeçalho padrão de tela/seção: ícone dourado + título + subtítulo + slot
// para widget de ação (ex: PeriodSelector, botão de filtro).
//
// USO SIMPLES:
//   GranitSectionHeader(
//     icon: Icons.home_rounded,
//     title: 'Visão Geral',
//     subtitle: 'Panorama atual das obras',
//   )
//
// COM AÇÃO:
//   GranitSectionHeader(
//     icon: Icons.bar_chart_rounded,
//     title: 'DRE Gerencial',
//     subtitle: 'Demonstrativo de resultado',
//     trailing: PeriodSelector(...),
//   )
// =============================================================================

class GranitSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? iconBg;

  const GranitSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Ícone
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconBg ?? GranitTokens.goldDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (iconColor ?? GranitTokens.gold).withOpacity(0.3),
          ),
        ),
        child: Icon(icon, color: iconColor ?? GranitTokens.gold, size: 20),
      ),
      const SizedBox(width: 12),

      // Textos
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GranitTokens.headingStyle),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: GranitTokens.bodySmall.copyWith(
                color: GranitTokens.textMuted, fontSize: 12,
              )),
            ],
          ],
        ),
      ),

      // Slot de ação (opcional)
      if (trailing != null) trailing!,
    ]);
  }
}

// =============================================================================
// GRANIT BADGE
// Chip de status colorido para usar em qualquer contexto.
//
// USO:
//   GranitBadge(label: '2 alertas', color: GranitTokens.red)
//   GranitBadge(label: 'Em andamento', color: GranitTokens.blue)
//   GranitBadge(label: 'Pago', color: GranitTokens.green)
// =============================================================================

class GranitBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const GranitBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// GRANIT PERIOD BUTTON
// Botão de filtro de período — extraído da ReportsPage para uso global.
// =============================================================================

class GranitPeriodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;

  const GranitPeriodButton({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? GranitTokens.goldDim : GranitTokens.surface2,
          borderRadius: GranitTokens.btnRadius,
          border: Border.all(
            color: active
                ? GranitTokens.gold.withOpacity(0.4)
                : GranitTokens.border2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? GranitTokens.gold : GranitTokens.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}