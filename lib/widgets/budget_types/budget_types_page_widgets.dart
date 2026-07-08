import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/ViewModels/BudgetsViewModel.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/budgets/budget_card.dart';
import 'package:project_granith/widgets/budgets/budget_form_dialog.dart';

enum _BudgetSortOption { urgency, valueDesc, valueAsc, client, createdDesc }

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

class _BudgetsPageContent extends StatefulWidget {
  const _BudgetsPageContent();

  @override
  State<_BudgetsPageContent> createState() => _BudgetsPageContentState();
}

class _BudgetsPageContentState extends State<_BudgetsPageContent> {
  static const int _initialVisibleItems = 18;
  static const int _visibleItemsStep = 18;

  final TextEditingController _searchController = TextEditingController();
  _BudgetSortOption _sortOption = _BudgetSortOption.urgency;
  int _visibleCount = _initialVisibleItems;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(width),
          child: Consumer<BudgetsViewModel>(
            builder: (context, viewModel, _) {
              final sortedBudgets = _sortedBudgets(viewModel.filteredBudgets);
              final visibleBudgets = sortedBudgets.take(_visibleCount).toList();
              final hasMore = visibleBudgets.length < sortedBudgets.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BudgetsHeader(
                    budgets: viewModel.allBudgets,
                    isUpdating: viewModel.isUpdatingExpired,
                    onRefresh: () => _refreshExpiredBudgets(context),
                    onCreate: () => _openBudgetForm(context),
                  ),
                  const SizedBox(height: 14),
                  _BudgetsToolbar(
                    controller: _searchController,
                    sortOption: _sortOption,
                    onSearchChanged: (value) {
                      viewModel.setSearchQuery(value);
                      _resetVisibleCount();
                    },
                    onClearSearch: () {
                      _searchController.clear();
                      viewModel.setSearchQuery('');
                      _resetVisibleCount();
                    },
                    onStatusChanged: (status) {
                      if (status == null) {
                        viewModel.clearFilters();
                      } else {
                        viewModel.setFilterStatus(status);
                      }
                      _resetVisibleCount();
                    },
                    onSortChanged: (option) {
                      setState(() {
                        _sortOption = option;
                        _visibleCount = _initialVisibleItems;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _BudgetsBody(
                      viewModel: viewModel,
                      budgets: visibleBudgets,
                      totalFilteredCount: sortedBudgets.length,
                      hasMore: hasMore,
                      onLoadMore: () {
                        setState(() {
                          _visibleCount += _visibleItemsStep;
                        });
                      },
                      onEdit: (budget) => _openBudgetForm(context, budget),
                      onDelete: (budget) => _deleteBudget(context, budget),
                      onApprove: (budget) => _approveBudget(context, budget),
                      onReject: (budget) => _rejectBudget(context, budget),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetVisibleCount() {
    setState(() => _visibleCount = _initialVisibleItems);
  }

  List<Budget> _sortedBudgets(List<Budget> budgets) {
    final sorted = [...budgets];
    sorted.sort((left, right) {
      switch (_sortOption) {
        case _BudgetSortOption.urgency:
          final statusCompare = _statusRank(left).compareTo(_statusRank(right));
          if (statusCompare != 0) return statusCompare;
          return _compareNullableDate(
            left.expirationDate,
            right.expirationDate,
          );
        case _BudgetSortOption.valueDesc:
          return right.totalValue.compareTo(left.totalValue);
        case _BudgetSortOption.valueAsc:
          return left.totalValue.compareTo(right.totalValue);
        case _BudgetSortOption.client:
          return left.clientName.toLowerCase().compareTo(
            right.clientName.toLowerCase(),
          );
        case _BudgetSortOption.createdDesc:
          return right.creationDate.compareTo(left.creationDate);
      }
    });
    return sorted;
  }

  int _statusRank(Budget budget) {
    switch (_effectiveStatus(budget)) {
      case BudgetStatus.pending:
        return 0;
      case BudgetStatus.expired:
        return 1;
      case BudgetStatus.approved:
        return 2;
      case BudgetStatus.rejected:
        return 3;
    }
  }

  int _compareNullableDate(DateTime? left, DateTime? right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  Future<void> _openBudgetForm(BuildContext context, [Budget? budget]) {
    final viewModel = context.read<BudgetsViewModel>();
    return showDialog<void>(
      context: context,
      builder:
          (_) => BudgetFormDialog(
            budget: budget,
            onSave:
                (value) async =>
                    budget == null
                        ? viewModel.addBudget(value)
                        : viewModel.updateBudget(value),
          ),
    );
  }

  Future<void> _refreshExpiredBudgets(BuildContext context) async {
    final viewModel = context.read<BudgetsViewModel>();
    await viewModel.forceCheckExpiredBudgets(
      onSuccess:
          (message) => _showSnack(context, message, AppColors.accentBlue),
      onError: (message) => _showSnack(context, message, AppColors.accentRed),
    );
  }

  Future<void> _approveBudget(BuildContext context, Budget budget) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Aprovar orcamento',
      message:
          'Aprovar a proposta de ${budget.clientName} e criar o projeto em planejamento?',
      confirmLabel: 'Aprovar',
      color: AppColors.accentGreen,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<BudgetsViewModel>().approveBudget(
      budget,
      onSuccess:
          (message) => _showSnack(context, message, AppColors.accentGreen),
      onError: (message) => _showSnack(context, message, AppColors.accentRed),
    );
  }

  Future<void> _rejectBudget(BuildContext context, Budget budget) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Rejeitar orcamento',
      message: 'Rejeitar a proposta de ${budget.clientName}?',
      confirmLabel: 'Rejeitar',
      color: AppColors.accentRed,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<BudgetsViewModel>().rejectBudget(
      budget,
      onSuccess:
          (message) => _showSnack(context, message, AppColors.accentGreen),
      onError: (message) => _showSnack(context, message, AppColors.accentRed),
    );
  }

  Future<void> _deleteBudget(BuildContext context, Budget budget) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Excluir orcamento',
      message: 'Excluir o orcamento de ${budget.clientName}?',
      confirmLabel: 'Excluir',
      color: AppColors.accentRed,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<BudgetsViewModel>().deleteBudget(
      budget,
      onSuccess:
          (message) => _showSnack(context, message, AppColors.accentGreen),
      onError: (message) => _showSnack(context, message, AppColors.accentRed),
    );
  }

  Future<bool?> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
  }

  void _showSnack(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BudgetsHeader extends StatelessWidget {
  final List<Budget> budgets;
  final bool isUpdating;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const _BudgetsHeader({
    required this.budgets,
    required this.isUpdating,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        budgets
            .where((budget) => _effectiveStatus(budget) == BudgetStatus.pending)
            .length;
    final approvedCount =
        budgets
            .where(
              (budget) => _effectiveStatus(budget) == BudgetStatus.approved,
            )
            .length;
    final rejectedCount =
        budgets
            .where(
              (budget) => _effectiveStatus(budget) == BudgetStatus.rejected,
            )
            .length;
    final expiredCount =
        budgets
            .where((budget) => _effectiveStatus(budget) == BudgetStatus.expired)
            .length;
    final totalValue = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.totalValue,
    );
    final approvedValue = budgets
        .where((budget) => _effectiveStatus(budget) == BudgetStatus.approved)
        .fold<double>(0, (sum, budget) => sum + budget.totalValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < ResponsiveLayout.compact;
          final titleBlock = Row(
            children: [
              if (!compact) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: AppDecorations.iconTile(AppColors.accentGold),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orcamentos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Propostas, aprovacoes e validade comercial',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isUpdating ? null : onRefresh,
                icon:
                    isUpdating
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh_rounded),
                label: const Text('Verificar expirados'),
              ),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo orcamento'),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BudgetMetricChip(
                icon: Icons.pending_actions_rounded,
                label: _plural(pendingCount, 'pendente', 'pendentes'),
                color: BudgetStatus.pending.color,
              ),
              _BudgetMetricChip(
                icon: Icons.check_circle_outline_rounded,
                label: _plural(approvedCount, 'aprovado', 'aprovados'),
                color: AppColors.accentGreen,
              ),
              _BudgetMetricChip(
                icon: Icons.cancel_outlined,
                label: _plural(rejectedCount, 'rejeitado', 'rejeitados'),
                color: AppColors.accentRed,
              ),
              _BudgetMetricChip(
                icon: Icons.timelapse_rounded,
                label: _plural(expiredCount, 'expirado', 'expirados'),
                color: AppColors.textMuted,
              ),
              _BudgetMetricChip(
                icon: Icons.price_check_rounded,
                label: '${_formatCurrency(totalValue)} propostos',
                color: AppColors.accentGold,
              ),
              _BudgetMetricChip(
                icon: Icons.verified_rounded,
                label: '${_formatCurrency(approvedValue)} aprovados',
                color: AppColors.accentBlue,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                actions,
                const SizedBox(height: 12),
                metrics,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
              const SizedBox(height: 12),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class _BudgetsToolbar extends StatelessWidget {
  final TextEditingController controller;
  final _BudgetSortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<BudgetStatus?> onStatusChanged;
  final ValueChanged<_BudgetSortOption> onSortChanged;

  const _BudgetsToolbar({
    required this.controller,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BudgetsViewModel>();
    final hasText = viewModel.searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final searchField = SizedBox(
            width: compact ? double.infinity : 360,
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Buscar orcamento',
                hintText: 'Cliente, obra, status ou item',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    hasText
                        ? IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close_rounded),
                        )
                        : null,
              ),
              onChanged: onSearchChanged,
            ),
          );
          final sortField = SizedBox(
            width: compact ? double.infinity : 230,
            child: DropdownButtonFormField<_BudgetSortOption>(
              initialValue: sortOption,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items:
                  _BudgetSortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(_sortLabel(option)),
                        ),
                      )
                      .toList(),
              onChanged: (option) {
                if (option != null) onSortChanged(option);
              },
            ),
          );
          final filters = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BudgetFilterChip(
                label: 'Todos',
                selected: !viewModel.isFiltering,
                onSelected: () => onStatusChanged(null),
              ),
              for (final status in BudgetStatus.values)
                _BudgetFilterChip(
                  label: _statusPluralLabel(status),
                  selected:
                      viewModel.isFiltering && viewModel.filterStatus == status,
                  color: status.color,
                  icon: status.icon,
                  onSelected: () => onStatusChanged(status),
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(height: 12),
                sortField,
                const SizedBox(height: 12),
                filters,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchField,
              const SizedBox(width: 12),
              sortField,
              const SizedBox(width: 12),
              Expanded(child: filters),
            ],
          );
        },
      ),
    );
  }

  String _sortLabel(_BudgetSortOption option) {
    switch (option) {
      case _BudgetSortOption.urgency:
        return 'Urgencia';
      case _BudgetSortOption.valueDesc:
        return 'Maior valor';
      case _BudgetSortOption.valueAsc:
        return 'Menor valor';
      case _BudgetSortOption.client:
        return 'Cliente';
      case _BudgetSortOption.createdDesc:
        return 'Criacao recente';
    }
  }
}

class _BudgetsBody extends StatelessWidget {
  final BudgetsViewModel viewModel;
  final List<Budget> budgets;
  final int totalFilteredCount;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<Budget> onEdit;
  final ValueChanged<Budget> onDelete;
  final ValueChanged<Budget> onApprove;
  final ValueChanged<Budget> onReject;

  const _BudgetsBody({
    required this.viewModel,
    required this.budgets,
    required this.totalFilteredCount,
    required this.hasMore,
    required this.onLoadMore,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.errorMessage != null) {
      return _BudgetStateView(
        icon: Icons.error_outline_rounded,
        title: 'Erro ao carregar',
        message: viewModel.errorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: viewModel.listenToBudgets,
        color: AppColors.accentRed,
      );
    }

    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    if (budgets.isEmpty) {
      return const _BudgetStateView(
        icon: Icons.request_quote_outlined,
        title: 'Nenhum orcamento encontrado',
        message: 'Ajuste a busca ou cadastre uma nova proposta.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: budgets.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= budgets.length) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                'Mostrar mais (${budgets.length} de $totalFilteredCount)',
              ),
            ),
          );
        }

        final budget = budgets[index];
        final isApproving = viewModel.approvingIds.contains(budget.id);
        final pending = _effectiveStatus(budget) == BudgetStatus.pending;

        return BudgetCard(
          budget: budget,
          isApproving: isApproving,
          onTap: () => onEdit(budget),
          onEdit: () => onEdit(budget),
          onDelete: () => onDelete(budget),
          onApprove: pending && !isApproving ? () => onApprove(budget) : null,
          onReject: pending && !isApproving ? () => onReject(budget) : null,
        );
      },
    );
  }
}

class _BudgetMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BudgetMetricChip({
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

class _BudgetFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color color;
  final IconData? icon;

  const _BudgetFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color = AppColors.accentBlue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 16, color: color),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.46),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color:
            selected
                ? color.withValues(alpha: 0.7)
                : AppColors.borderColor.withValues(alpha: 0.55),
      ),
    );
  }
}

class _BudgetStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const _BudgetStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color = AppColors.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: AppDecorations.iconTile(color),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

BudgetStatus _effectiveStatus(Budget budget) {
  final expired =
      budget.expirationDate != null &&
      DateTime.now().isAfter(budget.expirationDate!) &&
      budget.status == BudgetStatus.pending;
  return expired ? BudgetStatus.expired : budget.status;
}

String _statusPluralLabel(BudgetStatus status) {
  switch (status) {
    case BudgetStatus.pending:
      return 'Pendentes';
    case BudgetStatus.approved:
      return 'Aprovados';
    case BudgetStatus.rejected:
      return 'Rejeitados';
    case BudgetStatus.expired:
      return 'Expirados';
  }
}

String _formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = fixed.split(',');
  final chars = parts.first.split('').reversed.toList();
  final grouped = <String>[];
  for (var index = 0; index < chars.length; index++) {
    if (index > 0 && index % 3 == 0) grouped.add('.');
    grouped.add(chars[index]);
  }
  return 'R\$ ${grouped.reversed.join()},${parts.last}';
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
