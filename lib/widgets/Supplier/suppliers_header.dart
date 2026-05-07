import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class SuppliersHeader extends StatelessWidget {
  final bool isDesktop;

  const SuppliersHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Container(
          padding: EdgeInsets.all(isDesktop ? 32 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, Color(0xFF1a1a2e)],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = SupplierHeaderTitle(
                isDesktop: isDesktop,
                supplierCount: controller.suppliers.length,
                activeCount:
                    controller.suppliers.where((s) => s.isActive).length,
                isLoading: controller.isLoading,
              );
              final actions = SupplierHeaderActions(isDesktop: isDesktop);

              if (constraints.maxWidth < ResponsiveLayout.compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), actions],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
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
    required this.isDesktop,
    required this.supplierCount,
    required this.activeCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fornecedores',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isDesktop ? 28 : 24,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          Text(
            'Carregando...',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 14,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                supplierCount == 0
                    ? 'Nenhum fornecedor encontrado'
                    : '$supplierCount ${supplierCount == 1 ? 'fornecedor' : 'fornecedores'}',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              if (supplierCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCount ativos',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class SupplierHeaderActions extends StatelessWidget {
  final bool isDesktop;

  const SupplierHeaderActions({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SupplierViewToggleButtons(isDesktop: isDesktop),
            if (isDesktop) const SizedBox(width: 16),
            if (controller.suppliers.isNotEmpty) ...[
              if (!isDesktop) const SizedBox(width: 12),
              SupplierExportButton(hasData: controller.suppliers.isNotEmpty),
            ],
            if (isDesktop) ...[
              const SizedBox(width: 16),
              SupplierRefreshButton(),
            ],
          ],
        );
      },
    );
  }
}

class SupplierViewToggleButtons extends StatelessWidget {
  final bool isDesktop;

  const SupplierViewToggleButtons({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SupplierViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: controller.isGridView,
                onTap: () => controller.setViewMode(true),
                tooltip: 'Visualização em Grade',
              ),
              SupplierViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !controller.isGridView,
                onTap: () => controller.setViewMode(false),
                tooltip: 'Visualização em Lista',
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
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.accentGold.withOpacity(0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.accentGold : AppColors.textMuted,
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: button);
    return Semantics(
      button: true,
      label:
          isSelected
              ? 'Modo de visualização ativo'
              : 'Alternar modo de visualização',
      child: button,
    );
  }
}

class SupplierExportButton extends StatelessWidget {
  final bool hasData;

  const SupplierExportButton({required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar Fornecedores',
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
      builder: (context) => SupplierExportOptionsSheet(),
    );
  }
}

class SupplierRefreshButton extends StatelessWidget {
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
                      ? AppColors.textMuted.withOpacity(0.5)
                      : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class SupplierExportOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exportar Fornecedores',
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
            subtitle: 'Relatório formatado',
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
        content: Text('Exportação $type em desenvolvimento'),
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
