import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';

// Imports dos componentes que você já possui
import 'package:project_granith/widgets/financial/FinancialFilterBar.dart';
import 'package:project_granith/widgets/financial/FinancialStatCard.dart';
import 'package:project_granith/widgets/financial/TransactionListItem.dart';
import 'package:project_granith/widgets/financial/transactionformdialog.dart';

// Imports de controle e modelos
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

enum _FinancialStatusFilter { all, open, paid, overdue, cancelled }

extension _FinancialStatusFilterLabel on _FinancialStatusFilter {
  String get label => switch (this) {
    _FinancialStatusFilter.all => 'Todos',
    _FinancialStatusFilter.open => 'Em aberto',
    _FinancialStatusFilter.paid => 'Pagos',
    _FinancialStatusFilter.overdue => 'Vencidos',
    _FinancialStatusFilter.cancelled => 'Cancelados',
  };
}

enum _FinancialSort { dueAsc, dueDesc, amountDesc, createdDesc }

extension _FinancialSortLabel on _FinancialSort {
  String get label => switch (this) {
    _FinancialSort.dueAsc => 'Vencimento proximo',
    _FinancialSort.dueDesc => 'Vencimento recente',
    _FinancialSort.amountDesc => 'Maior valor',
    _FinancialSort.createdDesc => 'Criacao recente',
  };

  IconData get icon => switch (this) {
    _FinancialSort.dueAsc => Icons.event_available_outlined,
    _FinancialSort.dueDesc => Icons.history_outlined,
    _FinancialSort.amountDesc => Icons.payments_outlined,
    _FinancialSort.createdDesc => Icons.schedule_outlined,
  };
}

class FinancialPageView extends StatefulWidget {
  const FinancialPageView({super.key});

  @override
  State<FinancialPageView> createState() => _FinancialPageViewState();
}

class _FinancialPageViewState extends State<FinancialPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  _FinancialStatusFilter _statusFilter = _FinancialStatusFilter.all;
  _FinancialSort _sort = _FinancialSort.dueAsc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;

    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
      );
    }

    final canViewFinancial = PermissionCodes.canViewFinancial(
      isAdmin: auth.isAdminUser || (user?.isAdmin ?? false),
      permissions: user?.permissions ?? const <String>[],
    );

    if (!canViewFinancial) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            'Voce nao tem permissao para acessar o financeiro geral.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final ctrl = context.watch<FinancialController>();
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isDesktop = width > 900;
    final compactHeight = size.height < 720;
    final padding = ResponsiveLayout.pagePadding(width);
    final baseTransactions = ctrl.transactions;
    final visibleTransactions = _applyLocalFilters(baseTransactions);
    final incomeTransactions =
        visibleTransactions
            .where((t) => t.type == TransactionType.income)
            .toList();
    final expenseTransactions =
        visibleTransactions
            .where((t) => t.type == TransactionType.expense)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child:
            ctrl.isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                )
                : SafeArea(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FinancialHeader(isDesktop: isDesktop),
                        SizedBox(height: isDesktop ? 14 : 10),
                        _FinancialCommandCenter(
                          showStats: !compactHeight,
                          controller: ctrl,
                          visibleCount: visibleTransactions.length,
                          totalCount: baseTransactions.length,
                          queryController: _searchCtrl,
                          query: _searchCtrl.text,
                          statusFilter: _statusFilter,
                          sort: _sort,
                          onQueryChanged: (_) => setState(() {}),
                          onClearQuery: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          onStatusChanged:
                              (value) => setState(() => _statusFilter = value),
                          onSortChanged: (value) {
                            if (value == null) return;
                            setState(() => _sort = value);
                          },
                          onSelectIncome: () => _tabController.animateTo(1),
                          onSelectExpense: () => _tabController.animateTo(2),
                        ),
                        const SizedBox(height: 10),
                        _FinancialTabs(
                          tabController: _tabController,
                          isDesktop: isDesktop,
                          allCount: visibleTransactions.length,
                          incomeCount: incomeTransactions.length,
                          expenseCount: expenseTransactions.length,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _TransactionList(
                                transactions: visibleTransactions,
                                emptyLabel:
                                    _searchCtrl.text.trim().isEmpty
                                        ? 'Nenhuma movimentacao encontrada'
                                        : 'Nenhuma movimentacao para a busca',
                              ),
                              _TransactionList(
                                transactions: incomeTransactions,
                                emptyLabel:
                                    _searchCtrl.text.trim().isEmpty
                                        ? 'Nenhuma entrada encontrada'
                                        : 'Nenhuma entrada para a busca',
                              ),
                              _TransactionList(
                                transactions: expenseTransactions,
                                emptyLabel:
                                    _searchCtrl.text.trim().isEmpty
                                        ? 'Nenhuma saida encontrada'
                                        : 'Nenhuma saida para a busca',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
      floatingActionButton:
          !isDesktop
              ? FloatingActionButton.extended(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                icon: const Icon(Icons.add),
                label: const Text('Lancamento'),
                onPressed: () => TransactionFormDialog.show(context),
              )
              : null,
    );
  }

  List<FinancialTransactionModel> _applyLocalFilters(
    List<FinancialTransactionModel> transactions,
  ) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered =
        transactions.where((transaction) {
          final matchesStatus = switch (_statusFilter) {
            _FinancialStatusFilter.all => true,
            _FinancialStatusFilter.open =>
              transaction.status == TransactionStatus.pending ||
                  transaction.status == TransactionStatus.overdue ||
                  transaction.isOverdue,
            _FinancialStatusFilter.paid =>
              transaction.status == TransactionStatus.paid,
            _FinancialStatusFilter.overdue =>
              transaction.status == TransactionStatus.overdue ||
                  transaction.isOverdue,
            _FinancialStatusFilter.cancelled =>
              transaction.status == TransactionStatus.cancelled,
          };

          if (!matchesStatus) return false;
          if (query.isEmpty) return true;

          final haystack =
              [
                transaction.description,
                transaction.projectId,
                transaction.supplierId,
                transaction.referenceId,
                transaction.notes,
                transaction.type.name,
                transaction.status.name,
                transaction.origin.name,
                transaction.category.name,
              ].whereType<String>().join(' ').toLowerCase();

          return haystack.contains(query);
        }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _FinancialSort.dueAsc => a.dueDate.compareTo(b.dueDate),
        _FinancialSort.dueDesc => b.dueDate.compareTo(a.dueDate),
        _FinancialSort.amountDesc => b.amount.compareTo(a.amount),
        _FinancialSort.createdDesc => b.createdAt.compareTo(a.createdAt),
      };
    });

    return filtered;
  }
}

class _FinancialHeader extends StatelessWidget {
  final bool isDesktop;

  const _FinancialHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isDesktop ? 52 : 46,
          height: isDesktop ? 52 : 46,
          decoration: AppDecorations.iconTile(AppColors.accentGold),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.accentGold,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entradas e Saidas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 3),
              Text(
                'Fluxo de caixa, contas a pagar e contas a receber.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed:
                () => TransactionFormDialog.show(
                  context,
                  forceType: TransactionType.income,
                ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_upward, size: 17),
            label: const Text('Nova entrada'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed:
                () => TransactionFormDialog.show(
                  context,
                  forceType: TransactionType.expense,
                ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_downward, size: 17),
            label: const Text('Nova saida'),
          ),
        ],
      ],
    );
  }
}

class _FinancialCommandCenter extends StatelessWidget {
  final bool showStats;
  final FinancialController controller;
  final int visibleCount;
  final int totalCount;
  final TextEditingController queryController;
  final String query;
  final _FinancialStatusFilter statusFilter;
  final _FinancialSort sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FinancialStatusFilter> onStatusChanged;
  final ValueChanged<_FinancialSort?> onSortChanged;
  final VoidCallback onSelectIncome;
  final VoidCallback onSelectExpense;

  const _FinancialCommandCenter({
    required this.showStats,
    required this.controller,
    required this.visibleCount,
    required this.totalCount,
    required this.queryController,
    required this.query,
    required this.statusFilter,
    required this.sort,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onSelectIncome,
    required this.onSelectExpense,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _FinancialStatsStrip(
      controller: controller,
      onSelectIncome: onSelectIncome,
      onSelectExpense: onSelectExpense,
    );
    final filters = _FinancialFiltersPanel(
      queryController: queryController,
      query: query,
      statusFilter: statusFilter,
      sort: sort,
      visibleCount: visibleCount,
      totalCount: totalCount,
      onQueryChanged: onQueryChanged,
      onClearQuery: onClearQuery,
      onStatusChanged: onStatusChanged,
      onSortChanged: onSortChanged,
    );

    if (!showStats) return filters;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: stats),
              const SizedBox(width: 12),
              SizedBox(width: 520, child: filters),
            ],
          );
        }

        return Column(children: [stats, const SizedBox(height: 10), filters]);
      },
    );
  }
}

class _FinancialStatsStrip extends StatelessWidget {
  final FinancialController controller;
  final VoidCallback onSelectIncome;
  final VoidCallback onSelectExpense;

  const _FinancialStatsStrip({
    required this.controller,
    required this.onSelectIncome,
    required this.onSelectExpense,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      FinancialStatCard(
        title: 'Saldo em caixa',
        value: controller.balance,
        icon: Icons.account_balance_wallet_outlined,
        color:
            controller.balance >= 0
                ? AppColors.accentBlue
                : AppColors.accentRed,
        width: 190,
        compact: true,
      ),
      FinancialStatCard(
        title: 'Entradas recebidas',
        value: controller.totalIncome,
        icon: Icons.arrow_upward,
        color: AppColors.accentGreen,
        width: 190,
        compact: true,
        onTap: onSelectIncome,
      ),
      FinancialStatCard(
        title: 'Saidas pagas',
        value: controller.totalExpense,
        icon: Icons.arrow_downward,
        color: AppColors.accentRed,
        width: 190,
        compact: true,
        onTap: onSelectExpense,
      ),
      FinancialStatCard(
        title: 'A pagar',
        value: controller.totalPendingExpense,
        icon: Icons.schedule_outlined,
        color: Colors.orangeAccent,
        width: 190,
        compact: true,
        onTap: onSelectExpense,
      ),
      FinancialStatCard(
        title: 'Vencidos',
        value: controller.totalOverdueExpense,
        icon: Icons.warning_amber_rounded,
        color: AppColors.accentRed,
        badgeCount: controller.overdueTransactions.length,
        width: 190,
        compact: true,
        onTap: onSelectExpense,
      ),
      FinancialStatCard(
        title: 'A receber',
        value: controller.totalPendingIncome,
        icon: Icons.hourglass_bottom_outlined,
        color: Colors.lightGreenAccent,
        width: 190,
        compact: true,
        onTap: onSelectIncome,
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _FinancialFiltersPanel extends StatelessWidget {
  final TextEditingController queryController;
  final String query;
  final _FinancialStatusFilter statusFilter;
  final _FinancialSort sort;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_FinancialStatusFilter> onStatusChanged;
  final ValueChanged<_FinancialSort?> onSortChanged;

  const _FinancialFiltersPanel({
    required this.queryController,
    required this.query,
    required this.statusFilter,
    required this.sort,
    required this.visibleCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.cardInnerSurface(radius: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final search = TextField(
            controller: queryController,
            onChanged: onQueryChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.primaryDark.withValues(alpha: 0.36),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textMuted,
                size: 19,
              ),
              suffixIcon:
                  query.trim().isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: onClearQuery,
                        icon: const Icon(Icons.close, size: 18),
                      ),
              hintText: 'Buscar descricao, projeto, origem ou nota',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentGold),
              ),
            ),
          );
          final statusBar = _StatusSegmentedFilter(
            value: statusFilter,
            onChanged: onStatusChanged,
          );
          final sortAndCount = _SortAndCountRow(
            sort: sort,
            visibleCount: visibleCount,
            totalCount: totalCount,
            onSortChanged: onSortChanged,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                search,
                const SizedBox(height: 9),
                const FinancialFilterBar(),
                const SizedBox(height: 9),
                statusBar,
                const SizedBox(height: 9),
                sortAndCount,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 10),
                    SizedBox(width: 210, child: sortAndCount),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [const FinancialFilterBar(), statusBar],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusSegmentedFilter extends StatelessWidget {
  final _FinancialStatusFilter value;
  final ValueChanged<_FinancialStatusFilter> onChanged;

  const _StatusSegmentedFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          _FinancialStatusFilter.values.map((filter) {
            final selected = filter == value;
            final color =
                filter == _FinancialStatusFilter.overdue
                    ? AppColors.accentRed
                    : filter == _FinancialStatusFilter.paid
                    ? AppColors.accentGreen
                    : AppColors.accentGold;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? color.withValues(alpha: 0.12)
                          : AppColors.primaryDark.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        selected
                            ? color.withValues(alpha: 0.36)
                            : AppColors.borderColor.withValues(alpha: 0.42),
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    color: selected ? color : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _SortAndCountRow extends StatelessWidget {
  final _FinancialSort sort;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<_FinancialSort?> onSortChanged;

  const _SortAndCountRow({
    required this.sort,
    required this.visibleCount,
    required this.totalCount,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SortDropdown(value: sort, onChanged: onSortChanged),
              const SizedBox(height: 8),
              _ResultCounter(
                visibleCount: visibleCount,
                totalCount: totalCount,
                expand: true,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _SortDropdown(value: sort, onChanged: onSortChanged),
            ),
            const SizedBox(width: 8),
            _ResultCounter(visibleCount: visibleCount, totalCount: totalCount),
          ],
        );
      },
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _FinancialSort value;
  final ValueChanged<_FinancialSort?> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_FinancialSort>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.secondaryDark,
          iconEnabledColor: AppColors.accentGold,
          selectedItemBuilder:
              (context) =>
                  _FinancialSort.values
                      .map(
                        (sort) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            sort.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
          items:
              _FinancialSort.values
                  .map(
                    (sort) => DropdownMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(sort.icon, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sort.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ResultCounter extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final bool expand;

  const _ResultCounter({
    required this.visibleCount,
    required this.totalCount,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: expand ? double.infinity : null,
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exibindo',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$visibleCount de $totalCount',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialTabs extends StatelessWidget {
  final TabController tabController;
  final bool isDesktop;
  final int allCount;
  final int incomeCount;
  final int expenseCount;

  const _FinancialTabs({
    required this.tabController,
    required this.isDesktop,
    required this.allCount,
    required this.incomeCount,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.35),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        isScrollable: !isDesktop,
        tabs: [
          Tab(text: 'Todas ($allCount)'),
          Tab(text: 'Entradas ($incomeCount)'),
          Tab(text: 'Saidas ($expenseCount)'),
        ],
      ),
    );
  }
}

/*
class _LegacyFinancialPageViewMethods {
  const _LegacyFinancialPageViewMethods();

  Widget buildHeader(BuildContext context, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestão Financeira',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Fluxo de caixa, contas a pagar e receber',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => TransactionFormDialog.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            icon: const Icon(Icons.add, color: AppColors.primaryDark, size: 18),
            label: const Text(
              'Nova Transação',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCards(FinancialController ctrl) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FinancialStatCard(
            title: 'Saldo em caixa',
            value: ctrl.balance,
            icon: Icons.account_balance_wallet_outlined,
            color:
                ctrl.balance >= 0 ? AppColors.accentBlue : AppColors.accentRed,
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'Receitas recebidas',
            value: ctrl.totalIncome,
            icon: Icons.arrow_upward,
            color: AppColors.accentGreen,
            onTap: () => _tabController.animateTo(1),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'Despesas pagas',
            value: ctrl.totalExpense,
            icon: Icons.arrow_downward,
            color: AppColors.accentRed,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'A pagar (pendente)',
            value: ctrl.totalPendingExpense,
            icon: Icons.schedule_outlined,
            color: Colors.orangeAccent,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'Vencidos',
            value: ctrl.totalOverdueExpense,
            icon: Icons.warning_amber_rounded,
            color: AppColors.accentRed,
            badgeCount: ctrl.overdueTransactions.length,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 12),
          FinancialStatCard(
            title: 'A receber',
            value: ctrl.totalPendingIncome,
            icon: Icons.hourglass_bottom_outlined,
            color: Colors.lightGreenAccent,
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDesktop) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accentGold,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        isScrollable: !isDesktop,
        tabs: const [
          Tab(text: 'Todas'),
          Tab(text: 'Entradas'),
          Tab(text: 'Saídas'),
        ],
      ),
    );
  }
}

*/
class _TransactionList extends StatelessWidget {
  final List<FinancialTransactionModel> transactions;
  final String emptyLabel;

  const _TransactionList({
    required this.transactions,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),
            Text(emptyLabel, style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (_, i) => TransactionListItem(transaction: transactions[i]),
    );
  }
}
