import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class SuppliersHeader extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback? onAddSupplier;
  final VoidCallback? onLookupCnpj;

  const SuppliersHeader({
    super.key,
    required this.isDesktop,
    this.onAddSupplier,
    this.onLookupCnpj,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        final suppliers = controller.suppliers;
        final activeCount =
            suppliers.where((supplier) => supplier.isActive).length;
        final inactiveCount = suppliers.length - activeCount;
        final lastUpdate = _lastUpdate(suppliers.map((s) => s.updatedAt));

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.cardSurface(
            accent: AppColors.accentBlue,
            elevated: false,
            radius: 16,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < ResponsiveLayout.compact;
              final title = SupplierHeaderTitle(
                isDesktop: isDesktop,
                supplierCount: suppliers.length,
                activeCount: activeCount,
                isLoading: controller.isLoading && suppliers.isEmpty,
              );
              final metrics = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _SupplierHeaderMetric(
                    icon: Icons.business_rounded,
                    label: _plural(
                      suppliers.length,
                      'fornecedor',
                      'fornecedores',
                    ),
                    color: AppColors.accentBlue,
                  ),
                  _SupplierHeaderMetric(
                    icon: Icons.verified_outlined,
                    label: '$activeCount ativos',
                    color: AppColors.accentGreen,
                  ),
                  _SupplierHeaderMetric(
                    icon: Icons.pause_circle_outline_rounded,
                    label: '$inactiveCount inativos',
                    color:
                        inactiveCount == 0
                            ? AppColors.textSecondary
                            : AppColors.accentRed,
                  ),
                  _SupplierHeaderMetric(
                    icon: Icons.update_rounded,
                    label:
                        lastUpdate == null
                            ? 'sem atualizacao'
                            : 'atualizado ${_formatDate(lastUpdate)}',
                    color: AppColors.accentGold,
                  ),
                ],
              );
              final actions = SupplierHeaderActions(
                isDesktop: isDesktop,
                onAddSupplier: onAddSupplier,
                onLookupCnpj: onLookupCnpj,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 14),
                    metrics,
                    const SizedBox(height: 14),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 14), metrics],
                    ),
                  ),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class SupplierHeaderTitle extends StatelessWidget {
  final bool isDesktop;
  final int supplierCount;
  final int activeCount;
  final bool isLoading;

  const SupplierHeaderTitle({
    super.key,
    required this.isDesktop,
    required this.supplierCount,
    required this.activeCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          Container(
            width: 46,
            height: 46,
            decoration: AppDecorations.iconTile(AppColors.accentBlue),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fornecedores',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 24 : 21,
                ),
              ),
              const SizedBox(height: 4),
              if (isLoading)
                const Text(
                  'Carregando...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                )
              else
                Text(
                  supplierCount == 0
                      ? 'Nenhum fornecedor encontrado'
                      : '$supplierCount ${supplierCount == 1 ? 'fornecedor' : 'fornecedores'} cadastrados, $activeCount ativos',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SupplierHeaderActions extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback? onAddSupplier;
  final VoidCallback? onLookupCnpj;

  const SupplierHeaderActions({
    super.key,
    required this.isDesktop,
    this.onAddSupplier,
    this.onLookupCnpj,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isDesktop ? WrapAlignment.end : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (onAddSupplier != null)
              FilledButton.icon(
                onPressed: onAddSupplier,
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Novo fornecedor'),
              ),
            if (onLookupCnpj != null)
              OutlinedButton.icon(
                onPressed: onLookupCnpj,
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('Consultar CNPJ'),
              ),
            SupplierViewToggleButtons(isDesktop: isDesktop),
            if (controller.suppliers.isNotEmpty)
              SupplierExportButton(hasData: controller.suppliers.isNotEmpty),
            SupplierRefreshButton(),
          ],
        );
      },
    );
  }
}

class SupplierViewToggleButtons extends StatelessWidget {
  final bool isDesktop;

  const SupplierViewToggleButtons({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: AppDecorations.cardInnerSurface(
            accent: AppColors.accentBlue,
            radius: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SupplierViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: controller.isGridView,
                onTap: () => controller.setViewMode(true),
                tooltip: 'Visualizacao em grade',
              ),
              SupplierViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !controller.isGridView,
                onTap: () => controller.setViewMode(false),
                tooltip: 'Visualizacao em lista',
              ),
            ],
          ),
        );
      },
    );
  }
}

class SupplierViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tooltip;

  const SupplierViewToggleButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      selected: isSelected,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.accentBlue.withValues(alpha: 0.16)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: button);
    return button;
  }
}

class SupplierExportButton extends StatelessWidget {
  final bool hasData;

  const SupplierExportButton({super.key, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar fornecedores',
      child: IconButton(
        onPressed: hasData ? () => _showExportOptions(context) : null,
        icon: const Icon(Icons.download_rounded),
        style: IconButton.styleFrom(
          foregroundColor:
              hasData ? AppColors.textSecondary : AppColors.textMuted,
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SupplierExportOptionsSheet(),
    );
  }
}

class SupplierRefreshButton extends StatelessWidget {
  const SupplierRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Atualizar',
          child: IconButton(
            onPressed:
                controller.isLoading
                    ? null
                    : () => controller.loadSuppliers(forceRefresh: true),
            icon: Icon(
              Icons.refresh_rounded,
              color:
                  controller.isLoading
                      ? AppColors.textMuted.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class SupplierExportOptionsSheet extends StatelessWidget {
  const SupplierExportOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exportar fornecedores',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          SupplierExportOption(
            icon: Icons.table_chart,
            title: 'Exportar como CSV',
            subtitle: 'Planilha com todos os dados',
            onTap: () => _handleExport(context, 'CSV'),
          ),
          SupplierExportOption(
            icon: Icons.picture_as_pdf,
            title: 'Exportar como PDF',
            subtitle: 'Relatorio formatado',
            onTap: () => _handleExport(context, 'PDF'),
          ),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context, String type) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportacao $type em desenvolvimento'),
        backgroundColor: AppColors.accentBlue,
      ),
    );
  }
}

class SupplierExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SupplierExportOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentGold),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}

class _SupplierHeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SupplierHeaderMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: AppDecorations.cardInnerSurface(accent: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

DateTime? _lastUpdate(Iterable<DateTime> dates) {
  final sorted = dates.toList();
  if (sorted.isEmpty) return null;
  sorted.sort((left, right) => right.compareTo(left));
  return sorted.first;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
