import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/budgets/budget_card.dart';
import 'package:project_granith/widgets/budgets/budget_form_dialog.dart';
import 'package:project_granith/ViewModels/BudgetsViewModel.dart';

// Ponto de entrada que injeta o ViewModel
class BudgetsPageView extends StatelessWidget {
  final BudgetsViewModel? viewModel;

  const BudgetsPageView({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BudgetsViewModel>(
      create: (_) => viewModel ?? BudgetsViewModel(ServiceOrcamentos()),
      child: const _BudgetsPageContent(),
    );
  }
}

// O layout principal
class _BudgetsPageContent extends StatelessWidget {
  const _BudgetsPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: const Column(
        children: [
          _BudgetsHeader(),
          _BudgetsFilterChips(),
          _BudgetsSearchBar(),
          Expanded(child: _BudgetsList()),
        ],
      ),
      floatingActionButton: const _BudgetsFAB(),
    );
  }
}

// ─── COMPONENTES ────────────────────────────────────────────────────────────

class _BudgetsHeader extends StatelessWidget {
  const _BudgetsHeader();

  @override
  Widget build(BuildContext context) {
    final isUpdating = context.select(
      (BudgetsViewModel vm) => vm.isUpdatingExpired,
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryDark.withBlue(20)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.attach_money_outlined,
              color: AppColors.accentGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orçamentos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gerencie seus orçamentos e propostas',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isUpdating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Verificando...',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetsFilterChips extends StatelessWidget {
  const _BudgetsFilterChips();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BudgetsViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children:
                  BudgetStatus.values.map((status) {
                    final isSelected =
                        viewModel.filterStatus == status &&
                        viewModel.isFiltering;
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (_) => viewModel.setFilterStatus(status),
                      label: Text(status.displayName),
                      avatar: Icon(status.icon, size: 16),
                      backgroundColor: AppColors.secondaryDark,
                      selectedColor: status.color.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color:
                            isSelected ? status.color : AppColors.textSecondary,
                      ),
                      checkmarkColor: status.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          if (viewModel.isFiltering)
            TextButton.icon(
              onPressed: () => viewModel.clearFilters(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Limpar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetsSearchBar extends StatefulWidget {
  const _BudgetsSearchBar();
  @override
  State<_BudgetsSearchBar> createState() => _BudgetsSearchBarState();
}

class _BudgetsSearchBarState extends State<_BudgetsSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<BudgetsViewModel>();
    final hasText = context.select(
      (BudgetsViewModel vm) => vm.searchQuery.isNotEmpty,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar orçamentos...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon:
              hasText
                  ? IconButton(
                    onPressed: () {
                      _controller.clear();
                      viewModel.setSearchQuery('');
                    },
                    icon: const Icon(Icons.clear, color: AppColors.textMuted),
                  )
                  : null,
          filled: true,
          fillColor: AppColors.secondaryDark.withOpacity(0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
        onChanged: (val) => viewModel.setSearchQuery(val),
      ),
    );
  }
}

class _BudgetsList extends StatelessWidget {
  const _BudgetsList();

  void _showSnack(BuildContext context, String msg, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BudgetsViewModel>();

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.accentRed.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
            Text(
              viewModel.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => viewModel.listenToBudgets(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
        ),
      );
    }

    final filtered = viewModel.filteredBudgets;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum orçamento encontrado',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final budget = filtered[index];
        final isApproving = viewModel.approvingIds.contains(budget.id);

        return BudgetCard(
          budget: budget,
          isApproving: isApproving,
          onTap:
              () => showDialog(
                context: context,
                builder:
                    (_) => BudgetFormDialog(
                      budget: budget,
                      onSave:
                          (updated) async => viewModel.updateBudget(updated),
                    ),
              ),
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (_) => AlertDialog(
                    backgroundColor: AppColors.surfaceDark,
                    title: const Text(
                      'Confirmar exclusão',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    content: Text(
                      'Excluir orçamento de "${budget.clientName}"?',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Excluir',
                          style: TextStyle(color: AppColors.accentRed),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirmed == true && context.mounted) {
              viewModel.deleteBudget(
                budget,
                onSuccess:
                    (msg) => _showSnack(context, msg, AppColors.accentGreen),
                onError: (msg) => _showSnack(context, msg, AppColors.accentRed),
              );
            }
          },
          onApprove:
              budget.status == BudgetStatus.pending && !isApproving
                  ? () async {
                    final confirmed = await showDialog<bool>(
                      /* Diálogo original de aprovação omitido por brevidade, assuma que existe */ context:
                          context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text(
                              "Aprovar?",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Aprovar",
                                  style: TextStyle(
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirmed == true && context.mounted) {
                      viewModel.approveBudget(
                        budget,
                        onSuccess:
                            (msg) =>
                                _showSnack(context, msg, AppColors.accentGreen),
                        onError:
                            (msg) =>
                                _showSnack(context, msg, AppColors.accentRed),
                      );
                    }
                  }
                  : null,
          onReject:
              budget.status == BudgetStatus.pending && !isApproving
                  ? () async {
                    final confirmed = await showDialog<bool>(
                      /* Diálogo de rejeição */ context: context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text(
                              "Rejeitar?",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Rejeitar",
                                  style: TextStyle(color: AppColors.accentRed),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirmed == true && context.mounted) {
                      viewModel.rejectBudget(
                        budget,
                        onSuccess:
                            (msg) =>
                                _showSnack(context, msg, AppColors.accentGreen),
                        onError:
                            (msg) =>
                                _showSnack(context, msg, AppColors.accentRed),
                      );
                    }
                  }
                  : null,
        );
      },
    );
  }
}

class _BudgetsFAB extends StatelessWidget {
  const _BudgetsFAB();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BudgetsViewModel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed:
              viewModel.isUpdatingExpired
                  ? null
                  : () => viewModel.forceCheckExpiredBudgets(
                    onSuccess:
                        (msg) => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: AppColors.accentGreen,
                          ),
                        ),
                    onError:
                        (msg) => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: AppColors.accentRed,
                          ),
                        ),
                  ),
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.textPrimary,
          heroTag: 'refresh',
          child:
              viewModel.isUpdatingExpired
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textPrimary,
                      ),
                    ),
                  )
                  : const Icon(Icons.refresh, size: 18),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (_) => BudgetFormDialog(
                    onSave: (budget) async => viewModel.addBudget(budget),
                  ),
            );
          },
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          heroTag: 'add',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
