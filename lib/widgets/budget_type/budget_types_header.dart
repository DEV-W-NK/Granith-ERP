import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/budget_type_controller.dart';
import 'package:project_granith/themes/app_theme.dart';

class BudgetTypesHeader extends StatelessWidget {
  final bool isDesktop;

  const BudgetTypesHeader({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
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
          child: Row(
            children: [
              Expanded(
                child: BudgetTypeHeaderTitle(
                  isDesktop: isDesktop,
                  budgetTypeCount: controller.budgetTypes.length,
                  isLoading: controller.isLoading,
                ),
              ),
              BudgetTypeHeaderActions(isDesktop: isDesktop),
            ],
          ),
        );
      },
    );
  }
}

class BudgetTypeHeaderTitle extends StatelessWidget {
  final bool isDesktop;
  final int budgetTypeCount;
  final bool isLoading;

  const BudgetTypeHeaderTitle({
    super.key,
    required this.isDesktop,
    required this.budgetTypeCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipos de Orçamento',
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
          Text(
            budgetTypeCount == 0
                ? 'Nenhum tipo de orçamento encontrado'
                : '$budgetTypeCount ${budgetTypeCount == 1 ? 'tipo' : 'tipos'} de orçamento',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}

class BudgetTypeHeaderActions extends StatelessWidget {
  final bool isDesktop;

  const BudgetTypeHeaderActions({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BudgetTypeViewToggleButtons(isDesktop: isDesktop),
            if (isDesktop) const SizedBox(width: 16),
            if (controller.budgetTypes.isNotEmpty) ...[
              if (!isDesktop) const SizedBox(width: 12),
              BudgetTypeExportButton(
                hasData: controller.budgetTypes.isNotEmpty,
              ),
            ],
            if (isDesktop) ...[
              const SizedBox(width: 16),
              BudgetTypeRefreshButton(),
            ],
          ],
        );
      },
    );
  }
}

class BudgetTypeViewToggleButtons extends StatelessWidget {
  final bool isDesktop;

  const BudgetTypeViewToggleButtons({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
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
              BudgetTypeViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: controller.isGridView,
                onTap: () => controller.setViewMode(true),
                tooltip: 'Visualização em Grade',
              ),
              BudgetTypeViewToggleButton(
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

class BudgetTypeViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tooltip;

  const BudgetTypeViewToggleButton({
    super.key,
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

class BudgetTypeExportButton extends StatelessWidget {
  final bool hasData;

  const BudgetTypeExportButton({super.key, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar Tipos de Orçamento',
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
      builder: (context) => BudgetTypeExportOptionsSheet(),
    );
  }
}

class BudgetTypeRefreshButton extends StatelessWidget {
  const BudgetTypeRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Atualizar',
          child: IconButton(
            onPressed:
                controller.isLoading
                    ? null
                    : () => controller.loadBudgetTypes(forceRefresh: true),
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

class BudgetTypeExportOptionsSheet extends StatelessWidget {
  const BudgetTypeExportOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exportar Tipos de Orçamento',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          BudgetTypeExportOption(
            icon: Icons.table_chart,
            title: 'Exportar como CSV',
            subtitle: 'Planilha com todos os dados',
            onTap: () => _handleExport(context, 'CSV'),
          ),
          BudgetTypeExportOption(
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

class BudgetTypeExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const BudgetTypeExportOption({
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
