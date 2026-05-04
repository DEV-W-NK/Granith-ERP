import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/themes/app_theme.dart';

/// Barra de filtros da FinancialPage.
/// Controla: período, projeto e exibe alerta de vencidos.
class FinancialFilterBar extends StatelessWidget {
  const FinancialFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FinancialController>();
    final overdueCount = ctrl.overdueTransactions.length;
    final hasFilters =
        ctrl.activeProjectId != null ||
        ctrl.periodFrom != null ||
        ctrl.periodTo != null;

    return Row(
      children: [
        // Filtro de período
        _FilterChip(
          icon: Icons.calendar_month_outlined,
          label: _periodLabel(ctrl),
          active: ctrl.periodFrom != null,
          onTap: () => _showPeriodPicker(context, ctrl),
        ),
        const SizedBox(width: 8),

        // Filtro de projeto
        _ProjectFilterChip(),
        const SizedBox(width: 8),

        // Badge de vencidos (clicável — filtra por overdue)
        if (overdueCount > 0) ...[
          _FilterChip(
            icon: Icons.warning_amber_rounded,
            label: '$overdueCount vencido${overdueCount > 1 ? 's' : ''}',
            active: true,
            activeColor: Colors.redAccent,
            onTap: () {
              // Scroll ou highlight — por ora só mostra snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$overdueCount transação(ões) vencida(s)'),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Limpar filtros
        if (hasFilters)
          GestureDetector(
            onTap: () => ctrl.clearFilters(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.close, size: 13, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'Limpar',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Period picker ────────────────────────────────────────────────────────────

  Future<void> _showPeriodPicker(
    BuildContext context,
    FinancialController ctrl,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PeriodPickerSheet(controller: ctrl),
    );
  }

  String _periodLabel(FinancialController ctrl) {
    if (ctrl.periodFrom == null) return 'Período';
    final fmt = DateFormat('MMM/yy', 'pt_BR');
    if (ctrl.periodTo == null) return 'Desde ${fmt.format(ctrl.periodFrom!)}';
    final sameMonth =
        ctrl.periodFrom!.month == ctrl.periodTo!.month &&
        ctrl.periodFrom!.year == ctrl.periodTo!.year;
    if (sameMonth) return fmt.format(ctrl.periodFrom!);
    return '${fmt.format(ctrl.periodFrom!)} – ${fmt.format(ctrl.periodTo!)}';
  }
}

// ─── Chip de filtro genérico ──────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.accentGold;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withOpacity(0.4) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? color : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppColors.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chip de projeto ──────────────────────────────────────────────────────────

class _ProjectFilterChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FinancialController>();
    final projects = context.watch<ProjectsController>().projects;
    final active = ctrl.activeProjectId != null;

    final label =
        active
            ? (projects
                    .where((p) => p.id == ctrl.activeProjectId)
                    .firstOrNull
                    ?.name ??
                'Projeto')
            : 'Projeto';

    return GestureDetector(
      onTap: () => _showProjectPicker(context, ctrl, projects),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.accentGold.withOpacity(0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active ? AppColors.accentGold.withOpacity(0.4) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 13,
              color: active ? AppColors.accentGold : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.accentGold : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectPicker(
    BuildContext context,
    FinancialController ctrl,
    List projects,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Filtrar por projeto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.all_inclusive,
                  color: AppColors.textMuted,
                ),
                title: const Text(
                  'Todos os projetos',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ctrl.setProjectFilter(null);
                  Navigator.of(context).pop();
                },
              ),
              ...projects.map(
                (p) => ListTile(
                  leading: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.accentGold,
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  selected: ctrl.activeProjectId == p.id,
                  selectedTileColor: AppColors.accentGold.withOpacity(0.08),
                  onTap: () {
                    ctrl.setProjectFilter(p.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
    );
  }
}

// ─── Sheet de período ─────────────────────────────────────────────────────────

class _PeriodPickerSheet extends StatelessWidget {
  final FinancialController controller;

  const _PeriodPickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por período',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _periodOption(context, 'Mês atual', () {
            controller.setCurrentMonthFilter();
            Navigator.of(context).pop();
          }),
          _periodOption(context, 'Últimos 3 meses', () {
            final now = DateTime.now();
            controller.setPeriodFilter(
              DateTime(now.year, now.month - 2, 1),
              DateTime(now.year, now.month + 1, 0),
            );
            Navigator.of(context).pop();
          }),
          _periodOption(context, 'Este ano', () {
            final now = DateTime.now();
            controller.setPeriodFilter(
              DateTime(now.year, 1, 1),
              DateTime(now.year, 12, 31),
            );
            Navigator.of(context).pop();
          }),
          _periodOption(context, 'Personalizado...', () async {
            Navigator.of(context).pop();
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder:
                  (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.accentGold,
                      ),
                    ),
                    child: child!,
                  ),
            );
            if (range != null) {
              controller.setPeriodFilter(range.start, range.end);
            }
          }),
          if (controller.periodFrom != null) ...[
            const Divider(color: Colors.white12),
            _periodOption(context, 'Limpar filtro de período', () {
              controller.setPeriodFilter(null, null);
              Navigator.of(context).pop();
            }, color: Colors.redAccent),
          ],
        ],
      ),
    );
  }

  Widget _periodOption(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(color: color ?? Colors.white, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
