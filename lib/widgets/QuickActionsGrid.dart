import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/AppCard.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    this.modules = const <NavigationModule>[],
    this.onModuleSelected,
  });

  final List<NavigationModule> modules;
  final ValueChanged<int>? onModuleSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions =
              modules.isEmpty
                  ? const [
                    _QuickActionData(
                      icon: Icons.business_rounded,
                      label: 'Projetos',
                      section: 'Operacional',
                      color: AppColors.accentGold,
                      route: '/projects',
                    ),
                    _QuickActionData(
                      icon: Icons.menu_book_rounded,
                      label: 'Diarios',
                      section: 'Operacional',
                      color: AppColors.auraCyan,
                      route: '/daily-logs',
                    ),
                    _QuickActionData(
                      icon: Icons.assignment_turned_in_rounded,
                      label: 'Requisicoes',
                      section: 'Operacional',
                      color: AppColors.accentBlue,
                      route: '/requisitions',
                    ),
                    _QuickActionData(
                      icon: Icons.badge_rounded,
                      label: 'Recursos Humanos',
                      section: 'Recursos Humanos',
                      color: AppColors.accentGreen,
                      route: '/hr',
                    ),
                  ]
                  : modules
                      .map(
                        (module) => _QuickActionData(
                          icon: module.icon,
                          label: _shortcutTitle(module),
                          section: module.section,
                          color: _sectionColor(module.section),
                          moduleIndex: module.index,
                        ),
                      )
                      .toList(growable: false);
          final gap =
              ResponsiveLayout.gap(
                constraints.maxWidth,
              ).clamp(8.0, 12.0).toDouble();
          final columns = _columnCount(constraints.maxWidth);
          final itemWidth =
              (constraints.maxWidth - (gap * (columns - 1))) / columns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCardTitle('Modulos disponiveis'),
                        Text(
                          'Acesse qualquer area liberada para o seu perfil.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: AppDecorations.cardInnerSurface(
                      accent: AppColors.accentGold,
                      radius: 10,
                    ),
                    child: Text(
                      '${actions.length} ${actions.length == 1 ? 'atalho' : 'atalhos'}',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children:
                    actions
                        .map(
                          (action) => SizedBox(
                            width: itemWidth,
                            child: _buildQuickAction(
                              context: context,
                              icon: action.icon,
                              label: action.label,
                              section: action.section,
                              color: action.color,
                              route: action.route,
                              moduleIndex: action.moduleIndex,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String section,
    required Color color,
    String? route,
    int? moduleIndex,
  }) {
    return GranithPressable(
      onTap: () {
        if (moduleIndex != null && onModuleSelected != null) {
          onModuleSelected!(moduleIndex);
          return;
        }
        if (route != null) {
          Navigator.of(context).pushNamed(route);
        }
      },
      premium: true,
      premiumColor: AppColors.accentGold,
      borderRadius: BorderRadius.circular(16),
      hoverScale: 1.015,
      builder: (context, state) {
        return Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  state.active
                      ? AppColors.accentGold.withValues(alpha: 0.48)
                      : AppColors.borderColor.withValues(alpha: 0.6),
            ),
            boxShadow:
                state.active
                    ? AppColors.auraShadows(AppColors.accentGold)
                    : AppColors.glowShadows(color),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: GranithPremiumIconTile(
                  icon: icon,
                  color: color,
                  size: 38,
                  iconSize: 19,
                  radius: 11,
                  active: state.active,
                  progress: state.glowProgress,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: state.active ? Colors.white : AppColors.tx,
                        fontSize: 11,
                        fontWeight:
                            state.active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      section,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.tx3, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                color:
                    state.active ? AppColors.accentGold : AppColors.textMuted,
                size: 15,
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }

  int _columnCount(double width) {
    if (width >= 1500) return 5;
    if (width >= 1120) return 4;
    if (width >= 760) return 3;
    if (width >= 430) return 2;
    return 1;
  }

  String _shortcutTitle(NavigationModule module) {
    return switch (module.index) {
      0 => 'Inicio',
      2 => 'Medicoes',
      3 => 'Diario de Obras',
      4 => 'Requisicoes',
      5 => 'Recursos Humanos',
      9 => 'Tipos de Orcamento',
      11 => 'Catalogo de Itens',
      12 => 'Compras e Pedidos',
      13 => 'Coletas e Entregas',
      15 => 'Frota e Veiculos',
      17 => 'Entradas e Saidas',
      19 => 'Compras a Pagar',
      20 => 'DRE',
      21 => 'Acessos',
      28 => 'Resultado Administrativo',
      _ => module.title,
    };
  }

  Color _sectionColor(String section) {
    return switch (section) {
      'Inicio' => AppColors.accentGold,
      'Operacional' => AppColors.accentBlue,
      'Recursos Humanos' => AppColors.purple,
      'Comercial' => AppColors.orange,
      'Suprimentos' => AppColors.accentGreen,
      'Administrativo' => AppColors.duskBlue,
      'Financeiro' => AppColors.accentGold,
      'I.A' => AppColors.auraCyan,
      _ => AppColors.accentBlue,
    };
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final String section;
  final Color color;
  final String? route;
  final int? moduleIndex;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.section,
    required this.color,
    this.route,
    this.moduleIndex,
  });
}
