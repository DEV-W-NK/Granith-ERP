import 'package:flutter/material.dart';
import 'package:project_granith/contants/supplier_constants.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/widgets/Supplier/supplier_card.dart';
import 'package:project_granith/widgets/Supplier/supplier_filters.dart';
import 'package:project_granith/widgets/Supplier/supplier_form_dialog.dart';
import 'package:project_granith/widgets/Supplier/cnpj_lookup_dialog.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/services/supplier_service.dart' as services;
import 'package:project_granith/themes/app_theme.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) =>
              SupplierController(services.SupplierService())..loadSuppliers(),
      child: const _SuppliersPageView(),
    );
  }
}

class _SuppliersPageView extends StatelessWidget {
  const _SuppliersPageView();

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        final isDesktop =
            MediaQuery.of(context).size.width >
            SupplierConstants.desktopBreakpoint;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: RefreshIndicator(
            onRefresh: () => controller.loadSuppliers(forceRefresh: true),
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.accentGold,
            child: Column(
              children: [
                _SuppliersHeader(isDesktop: isDesktop),
                if (!controller.isLoading) const _SuppliersFilters(),
                Expanded(child: _SuppliersContent(isDesktop: isDesktop)),
              ],
            ),
          ),
          floatingActionButton: _SuppliersFABGroup(),
        );
      },
    );
  }
}

class _SuppliersHeader extends StatelessWidget {
  final bool isDesktop;

  const _SuppliersHeader({required this.isDesktop});

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
          child: Row(
            children: [
              Expanded(
                child: _HeaderTitle(
                  isDesktop: isDesktop,
                  supplierCount: controller.suppliers.length,
                  activeCount:
                      controller.suppliers.where((s) => s.isActive).length,
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
  final int supplierCount;
  final int activeCount;
  final bool isLoading;

  const _HeaderTitle({
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
          Row(
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
                const SizedBox(width: 8),
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

class _HeaderActions extends StatelessWidget {
  final bool isDesktop;

  const _HeaderActions({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ViewToggleButtons(isDesktop: isDesktop),
            if (isDesktop) const SizedBox(width: 16),
            if (controller.suppliers.isNotEmpty) ...[
              if (!isDesktop) const SizedBox(width: 12),
              _ExportButton(hasData: controller.suppliers.isNotEmpty),
            ],
            if (isDesktop) ...[const SizedBox(width: 16), _RefreshButton()],
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

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

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

class _ExportButton extends StatelessWidget {
  final bool hasData;

  const _ExportButton({required this.hasData});

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
      builder: (context) => _ExportOptionsSheet(),
    );
  }
}

class _RefreshButton extends StatelessWidget {
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
            'Exportar Fornecedores',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
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

    // Show a simple message for now since export functionality is not fully implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Exportação em $type será implementada em breve'),
          ],
        ),
        backgroundColor: AppColors.accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}

class _SuppliersFilters extends StatelessWidget {
  const _SuppliersFilters();

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
        children: [_SearchField(), const SizedBox(height: 16), _FiltersRow()],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Semantics(
          label: 'Campo de busca de fornecedores',
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
                hintText: 'Buscar fornecedores por nome ou CNPJ...',
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
                suffixIcon:
                    controller.searchQuery.isNotEmpty
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
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return SupplierFilters(
          selectedFilter: controller.selectedFilter,
          onFilterChanged: controller.updateFilter,
        );
      },
    );
  }
}

class _SuppliersContent extends StatelessWidget {
  final bool isDesktop;

  const _SuppliersContent({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const _LoadingState();
        }

        if (controller.hasError) {
          return _ErrorState(
            message: controller.errorMessage ?? 'Erro desconhecido',
            onRetry: () => controller.loadSuppliers(forceRefresh: true),
          );
        }

        if (controller.filteredSuppliers.isEmpty) {
          return _EmptyState(
            hasFilters: controller.hasActiveFilters,
            onClearFilters: controller.clearFilters,
            onCreateSupplier: () => _showCreateSupplierOptions(context),
          );
        }

        return _SuppliersList(
          suppliers: controller.filteredSuppliers,
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
                Icons.business_rounded,
                color: AppColors.accentGold,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Carregando fornecedores...',
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

  const _ErrorState({required this.message, required this.onRetry});

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
  final VoidCallback onCreateSupplier;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onCreateSupplier,
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
                          : Icons.business_rounded,
                      size: 64,
                      color:
                          hasFilters
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
                  ? 'Nenhum fornecedor encontrado'
                  : 'Seus fornecedores aparecerão aqui',
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
                    ? 'Tente ajustar os filtros de busca ou cadastrar um novo fornecedor'
                    : 'Cadastre fornecedores para organizar seus contatos comerciais e facilitar o controle de orçamentos',
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
                  side: BorderSide(
                    color: AppColors.accentBlue.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: onCreateSupplier,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                hasFilters
                    ? 'Cadastrar fornecedor'
                    : 'Cadastrar primeiro fornecedor',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

class _SuppliersList extends StatelessWidget {
  final List<Supplier> suppliers;
  final bool isGridView;
  final bool isDesktop;

  const _SuppliersList({
    required this.suppliers,
    required this.isGridView,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _GridView(suppliers: suppliers, isDesktop: isDesktop);
    } else {
      return _ListView(suppliers: suppliers);
    }
  }
}

class _GridView extends StatelessWidget {
  final List<Supplier> suppliers;
  final bool isDesktop;

  const _GridView({required this.suppliers, required this.isDesktop});

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
        itemCount: suppliers.length,
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          return SupplierCard(
            supplier: supplier,
            isListView: false,
            onEdit: () => _showSupplierDialog(context, supplier),
            onDelete: () => _showDeleteConfirmation(context, supplier),
            onTap: () => _handleSupplierTap(context, supplier),
            onToggleStatus: () => _toggleSupplierStatus(context, supplier),
          );
        },
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Supplier> suppliers;

  const _ListView({required this.suppliers});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return SupplierCard(
          supplier: supplier,
          isListView: true,
          onEdit: () => _showSupplierDialog(context, supplier),
          onDelete: () => _showDeleteConfirmation(context, supplier),
          onTap: () => _handleSupplierTap(context, supplier),
          onToggleStatus: () => _toggleSupplierStatus(context, supplier),
        );
      },
    );
  }
}

// ==================== FLOATING ACTION BUTTONS ====================

class _SuppliersFABGroup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        final isDesktop =
            MediaQuery.of(context).size.width >
            SupplierConstants.desktopBreakpoint;

        if (isDesktop) {
          return _DesktopFABGroup();
        } else {
          return _MobileFABGroup();
        }
      },
    );
  }
}

class _DesktopFABGroup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: () => _showCNPJLookupDialog(context),
          heroTag: "cnpj_lookup",
          icon: const Icon(Icons.search_rounded),
          label: const Text('Buscar por CNPJ'),
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: () => _showSupplierDialog(context, null),
          heroTag: "add_supplier",
          icon: const Icon(Icons.add_rounded),
          label: const Text('Novo Fornecedor'),
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _MobileFABGroup extends StatefulWidget {
  @override
  _MobileFABGroupState createState() => _MobileFABGroupState();
}

class _MobileFABGroupState extends State<_MobileFABGroup>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: Visibility(
                  visible: _expandAnimation.value > 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniFAB(
                        icon: Icons.search_rounded,
                        label: 'Buscar CNPJ',
                        backgroundColor: AppColors.accentBlue,
                        onPressed: () {
                          _toggleExpansion();
                          _showCNPJLookupDialog(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _MiniFAB(
                        icon: Icons.add_rounded,
                        label: 'Novo Fornecedor',
                        backgroundColor: AppColors.accentGreen,
                        onPressed: () {
                          _toggleExpansion();
                          _showSupplierDialog(context, null);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        FloatingActionButton(
          onPressed: _toggleExpansion,
          heroTag: "main_fab",
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          elevation: 6,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(_isExpanded ? Icons.close_rounded : Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _MiniFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _MiniFAB({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 4,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}

// ==================== HELPER FUNCTIONS ====================

void _showCreateSupplierOptions(BuildContext context) {
  final isDesktop =
      MediaQuery.of(context).size.width > SupplierConstants.desktopBreakpoint;

  if (isDesktop) {
    // No desktop, mostrar menu de opções
    _showCreateSupplierMenu(context);
  } else {
    // No mobile, abrir diretamente o formulário manual
    _showSupplierDialog(context, null);
  }
}

void _showCreateSupplierMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Como deseja cadastrar?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _CreateSupplierOption(
                icon: Icons.search_rounded,
                title: 'Buscar por CNPJ',
                subtitle:
                    'Preenche automaticamente com dados da Receita Federal',
                color: AppColors.accentBlue,
                onTap: () {
                  Navigator.pop(context);
                  _showCNPJLookupDialog(context);
                },
              ),
              const SizedBox(height: 12),
              _CreateSupplierOption(
                icon: Icons.edit_rounded,
                title: 'Cadastro Manual',
                subtitle: 'Preencha os dados manualmente',
                color: AppColors.accentGreen,
                onTap: () {
                  Navigator.pop(context);
                  _showSupplierDialog(context, null);
                },
              ),
            ],
          ),
        ),
  );
}

class _CreateSupplierOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CreateSupplierOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

void _showSupplierDialog(BuildContext context, Supplier? supplier) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (dialogContext) => SupplierFormDialog(
          supplier: supplier,
          onSave: (Supplier supplierToSave) async {
            final controller = Provider.of<SupplierController>(
              context,
              listen: false,
            );

            if (supplier == null) {
              // Creating new supplier
              await controller.createSupplier(supplierToSave);
            } else {
              // Updating existing supplier
              await controller.updateSupplier(supplierToSave);
            }

            // Close the dialog
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }

            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        supplier == null
                            ? 'Fornecedor "${supplierToSave.name}" criado com sucesso!'
                            : 'Fornecedor "${supplierToSave.name}" atualizado com sucesso!',
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
  );
}

void _showCNPJLookupDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CNPJLookupDialog(),
  );
}

void _showDeleteConfirmation(BuildContext context, Supplier supplier) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: AppColors.accentRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Excluir Fornecedor',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tem certeza que deseja excluir o fornecedor?',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentRed.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (supplier.cnpj.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'CNPJ: ${supplier.formattedCnpj}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ Esta ação não pode ser desfeita.',
                style: TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final controller = Provider.of<SupplierController>(
                  context,
                  listen: false,
                );
                await controller.deleteSupplier(supplier.id);
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

void _handleSupplierTap(BuildContext context, Supplier supplier) {
  // Implementar navegação para detalhes do fornecedor
  // Por enquanto, abre o diálogo de edição
  _showSupplierDialog(context, supplier);
}

void _toggleSupplierStatus(BuildContext context, Supplier supplier) async {
  final controller = Provider.of<SupplierController>(context, listen: false);

  // Mostrar confirmação para alteração de status
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    supplier.isActive
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color:
                        supplier.isActive
                            ? AppColors.accentRed
                            : AppColors.accentGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    supplier.isActive
                        ? 'Desativar Fornecedor'
                        : 'Ativar Fornecedor',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.isActive
                        ? 'Deseja desativar este fornecedor? Ele não aparecerá nas listagens ativas.'
                        : 'Deseja ativar este fornecedor? Ele voltará a aparecer nas listagens.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (supplier.isActive
                              ? AppColors.accentRed
                              : AppColors.accentGreen)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (supplier.isActive
                                ? AppColors.accentRed
                                : AppColors.accentGreen)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (supplier.cnpj.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'CNPJ: ${supplier.formattedCnpj}',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        supplier.isActive
                            ? AppColors.accentRed
                            : AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(supplier.isActive ? 'Desativar' : 'Ativar'),
                ),
              ],
            ),
      ) ??
      false;

  if (confirmed) {
    await controller.toggleSupplierStatus(supplier.id, !supplier.isActive);
  }
}
