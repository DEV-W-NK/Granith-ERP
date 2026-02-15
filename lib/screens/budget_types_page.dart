import 'package:flutter/material.dart';
import 'package:project_granith/constants/budget_type_constants.dart';
import 'package:project_granith/controllers/budget_type_controller.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/widgets/budget_type/budget_type_card.dart';
import 'package:project_granith/widgets/budget_type/budget_type_filters.dart';
import 'package:project_granith/widgets/budget_type/budget_type_form_dialog.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/services/budget_type_service.dart';
import 'package:project_granith/themes/app_theme.dart';


class BudgetTypesPage extends StatelessWidget {
  const BudgetTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BudgetTypeController(BudgetTypeService())..loadBudgetTypes(),
      child: const _BudgetTypesPageView(),
    );
  }
}

class _BudgetTypesPageView extends StatelessWidget {
  const _BudgetTypesPageView();

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        final isDesktop = MediaQuery.of(context).size.width > BudgetTypeConstants.desktopBreakpoint;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: RefreshIndicator(
            onRefresh: () => controller.loadBudgetTypes(forceRefresh: true),
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.accentGold,
            child: Column(
              children: [
                _BudgetTypesHeader(isDesktop: isDesktop),
                if (!controller.isLoading) const _BudgetTypesFilters(),
                Expanded(child: _BudgetTypesContent(isDesktop: isDesktop)),
              ],
            ),
          ),
          floatingActionButton: _BudgetTypesFAB(),
        );
      },
    );
  }
}

class _BudgetTypesHeader extends StatelessWidget {
  final bool isDesktop;

  const _BudgetTypesHeader({required this.isDesktop});

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
                child: _HeaderTitle(
                  isDesktop: isDesktop,
                  budgetTypeCount: controller.budgetTypes.length,
                  isLoading: controller.isLoading,
                ),
              ),
              _HeaderActions(isDesktop: isDesktop),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final bool isDesktop;
  final int budgetTypeCount;
  final bool isLoading;

  const _HeaderTitle({
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

class _HeaderActions extends StatelessWidget {
  final bool isDesktop;

  const _HeaderActions({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ViewToggleButtons(isDesktop: isDesktop),
            if (isDesktop) const SizedBox(width: 16),
            if (controller.budgetTypes.isNotEmpty) ...[
              if (!isDesktop) const SizedBox(width: 12),
              _ExportButton(hasData: controller.budgetTypes.isNotEmpty),
            ],
            if (isDesktop) ...[
              const SizedBox(width: 16),
              _RefreshButton(),
            ],
          ],
        );
      },
    );
  }
}

class _ViewToggleButtons extends StatelessWidget {
  final bool isDesktop;

  const _ViewToggleButtons({required this.isDesktop});

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
              _ViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: controller.isGridView,
                onTap: () => controller.setViewMode(true),
                tooltip: 'Visualização em Grade',
              ),
              _ViewToggleButton(
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

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tooltip;

  const _ViewToggleButton({
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
          color: isSelected 
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

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return Semantics(
      button: true,
      label: isSelected 
          ? 'Modo de visualização ativo'
          : 'Alternar modo de visualização',
      child: button,
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool hasData;

  const _ExportButton({required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar Tipos de Orçamento',
      child: IconButton(
        onPressed: hasData ? () => _showExportOptions(context) : null,
        icon: const Icon(Icons.download_rounded),
        style: IconButton.styleFrom(
          foregroundColor: hasData ? AppColors.textSecondary : AppColors.textMuted,
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
      builder: (context) => _ExportOptionsSheet(),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Atualizar',
          child: IconButton(
            onPressed: controller.isLoading 
                ? null
                : () => controller.loadBudgetTypes(forceRefresh: true),
            icon: Icon(
              Icons.refresh_rounded,
              color: controller.isLoading 
                  ? AppColors.textMuted.withOpacity(0.5)
                  : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _ExportOptionsSheet extends StatelessWidget {
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _ExportOption(
            icon: Icons.table_chart,
            title: 'Exportar como CSV',
            subtitle: 'Planilha com todos os dados',
            onTap: () => _handleExport(context, 'CSV'),
          ),
          _ExportOption(
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

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
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
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
      onTap: onTap,
    );
  }
}

class _BudgetTypesFilters extends StatelessWidget {
  const _BudgetTypesFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _SearchField(),
          const SizedBox(height: 16),
          _FiltersRow(),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return Semantics(
          label: 'Campo de busca de tipos de orçamento',
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Buscar tipos por nome, descrição ou categoria...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontSize: 15,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                ),
                suffixIcon: controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                        onPressed: () => controller.updateSearchQuery(''),
                        tooltip: 'Limpar busca',
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.accentGold,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FiltersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return BudgetTypeFilters(
          selectedFilter: controller.selectedFilter,
          onFilterChanged: controller.updateFilter,
        );
      },
    );
  }
}

class _BudgetTypesContent extends StatelessWidget {
  final bool isDesktop;

  const _BudgetTypesContent({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const _LoadingState();
        }

        if (controller.hasError) {
          return _ErrorState(
            message: controller.errorMessage ?? 'Erro desconhecido',
            onRetry: () => controller.loadBudgetTypes(forceRefresh: true),
          );
        }

        if (controller.filteredBudgetTypes.isEmpty) {
          return _EmptyState(
            hasFilters: controller.hasActiveFilters,
            onClearFilters: controller.clearFilters,
            onCreateBudgetType: () => _showBudgetTypeDialog(context),
          );
        }

        return _BudgetTypesList(
          budgetTypes: controller.filteredBudgetTypes,
          isGridView: controller.isGridView,
          isDesktop: isDesktop,
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold.withOpacity(0.3),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold,
                  ),
                ),
              ),
              const Icon(
                Icons.category_outlined,
                color: AppColors.accentGold,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Carregando tipos de orçamento...',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aguarde um momento',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentRed.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.accentRed.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Algo deu errado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateBudgetType;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onCreateBudgetType,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          hasFilters
                              ? AppColors.accentBlue.withOpacity(0.2)
                              : AppColors.accentGold.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      hasFilters
                          ? Icons.search_off_rounded
                          : Icons.category_outlined,
                      size: 64,
                      color: hasFilters
                          ? AppColors.accentBlue.withOpacity(0.7)
                          : AppColors.accentGold.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              hasFilters
                  ? 'Nenhum tipo encontrado'
                  : 'Seus tipos de orçamento aparecerão aqui',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                hasFilters
                    ? 'Tente ajustar os filtros de busca ou criar um novo tipo de orçamento'
                    : 'Organize seus orçamentos criando diferentes tipos como Material, Mão de Obra, Equipamentos e Serviços',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            if (hasFilters) ...[
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Limpar filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: BorderSide(color: AppColors.accentBlue.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: onCreateBudgetType,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeiro tipo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetTypesList extends StatelessWidget {
  final List<BudgetType> budgetTypes;
  final bool isGridView;
  final bool isDesktop;

  const _BudgetTypesList({
    required this.budgetTypes,
    required this.isGridView,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _GridView(budgetTypes: budgetTypes, isDesktop: isDesktop);
    } else {
      return _ListView(budgetTypes: budgetTypes);
    }
  }
}

class _GridView extends StatelessWidget {
  final List<BudgetType> budgetTypes;
  final bool isDesktop;

  const _GridView({
    required this.budgetTypes,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 4 : 2;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isDesktop ? 1.2 : 0.9,
        ),
        itemCount: budgetTypes.length,
        itemBuilder: (context, index) {
          final budgetType = budgetTypes[index];
          return BudgetTypeCard(
            budgetType: budgetType,
            isListView: false,
            onEdit: () => _showBudgetTypeDialog(context, budgetType),
            onDelete: () => _showDeleteConfirmation(context, budgetType),
            onTap: () => _handleBudgetTypeTap(context, budgetType),
            onToggleStatus: () => _toggleBudgetTypeStatus(context, budgetType),
          );
        },
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<BudgetType> budgetTypes;

  const _ListView({required this.budgetTypes});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: budgetTypes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final budgetType = budgetTypes[index];
        return BudgetTypeCard(
          budgetType: budgetType,
          isListView: true,
          onEdit: () => _showBudgetTypeDialog(context, budgetType),
          onDelete: () => _showDeleteConfirmation(context, budgetType),
          onTap: () => _handleBudgetTypeTap(context, budgetType),
          onToggleStatus: () => _toggleBudgetTypeStatus(context, budgetType),
        );
      },
    );
  }
}

class _BudgetTypesFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetTypeController>(
      builder: (context, controller, child) {
        return FloatingActionButton.extended(
          onPressed: () => _showBudgetTypeDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Novo Tipo'),
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          elevation: 4,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        );
      },
    );
  }
}

// Helper functions
void _showBudgetTypeDialog(BuildContext context, [BudgetType? budgetType]) {
  final controller = Provider.of<BudgetTypeController>(context, listen: false);
  
  // Implementation will depend on your dialog structure
  // This would typically open the BudgetTypeFormDialog
  showDialog(
    context: context,
    builder: (context) => BudgetTypeFormDialog(
      budgetType: budgetType,
      onSave: (newBudgetType) async {
        if (budgetType == null) {
          await controller.createBudgetType(newBudgetType);
        } else {
          await controller.updateBudgetType(newBudgetType);
        }
      },
    ),
  );
}

void _showDeleteConfirmation(BuildContext context, BudgetType budgetType) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentRed,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Confirmar Exclusão',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        'Tem certeza que deseja excluir o tipo "${budgetType.name}"?\n\nEsta ação não pode ser desfeita.',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 16,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final controller = Provider.of<BudgetTypeController>(context, listen: false);
            await controller.deleteBudgetType(budgetType.id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

void _handleBudgetTypeTap(BuildContext context, BudgetType budgetType) {
  // Navigate to budget type details or perform any action on tap
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Visualizando: ${budgetType.name}'),
      backgroundColor: AppColors.accentBlue,
      duration: const Duration(seconds: 2),
    ),
  );
}

void _toggleBudgetTypeStatus(BuildContext context, BudgetType budgetType) async {
  final controller = Provider.of<BudgetTypeController>(context, listen: false);
  
  try {
    await controller.toggleBudgetTypeStatus(budgetType.id, !budgetType.isActive);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            budgetType.isActive 
                ? 'Tipo "${budgetType.name}" foi desativado'
                : 'Tipo "${budgetType.name}" foi ativado',
          ),
          backgroundColor: AppColors.accentGreen,
          action: SnackBarAction(
            label: 'Desfazer',
            textColor: Colors.white,
            onPressed: () async {
              await controller.toggleBudgetTypeStatus(budgetType.id, budgetType.isActive);
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar status: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }
}