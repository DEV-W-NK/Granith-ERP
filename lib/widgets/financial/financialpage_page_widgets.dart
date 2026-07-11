import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';

// Imports dos componentes que você já possui
import 'package:project_granith/widgets/financial/FinancialFilterBar.dart';
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
                        Expanded(
                          child: _FinancialWorkspace(
                            isDesktop: isDesktop,
                            tabController: _tabController,
                            controller: ctrl,
                            visibleTransactions: visibleTransactions,
                            incomeTransactions: incomeTransactions,
                            expenseTransactions: expenseTransactions,
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
                                (value) =>
                                    setState(() => _statusFilter = value),
                            onSortChanged: (value) {
                              if (value == null) return;
                              setState(() => _sort = value);
                            },
                            onSelectIncome: () => _tabController.animateTo(1),
                            onSelectExpense: () => _tabController.animateTo(2),
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

class _FinancialWorkspace extends StatelessWidget {
  final bool isDesktop;
  final TabController tabController;
  final FinancialController controller;
  final List<FinancialTransactionModel> visibleTransactions;
  final List<FinancialTransactionModel> incomeTransactions;
  final List<FinancialTransactionModel> expenseTransactions;
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

  const _FinancialWorkspace({
    required this.isDesktop,
    required this.tabController,
    required this.controller,
    required this.visibleTransactions,
    required this.incomeTransactions,
    required this.expenseTransactions,
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
    final overview = _FinancialOverviewPanel(
      controller: controller,
      onSelectIncome: onSelectIncome,
      onSelectExpense: onSelectExpense,
    );
    final filters = _FinancialFiltersPanel(
      queryController: queryController,
      query: query,
      statusFilter: statusFilter,
      sort: sort,
      visibleCount: visibleTransactions.length,
      totalCount: totalCount,
      onQueryChanged: onQueryChanged,
      onClearQuery: onClearQuery,
      onStatusChanged: onStatusChanged,
      onSortChanged: onSortChanged,
    );
    final ledger = _FinancialLedgerPanel(
      tabController: tabController,
      isDesktop: isDesktop,
      visibleTransactions: visibleTransactions,
      incomeTransactions: incomeTransactions,
      expenseTransactions: expenseTransactions,
      query: query,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    children: [overview, const SizedBox(height: 12), filters],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: ledger),
            ],
          );
        }

        final topPanelMaxHeight =
            constraints.maxHeight < 840
                ? constraints.maxHeight * 0.38
                : constraints.maxHeight * 0.45;

        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: topPanelMaxHeight),
              child: SingleChildScrollView(
                child: Column(
                  children: [overview, const SizedBox(height: 10), filters],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: ledger),
          ],
        );
      },
    );
  }
}

class _FinancialOverviewPanel extends StatelessWidget {
  final FinancialController controller;
  final VoidCallback onSelectIncome;
  final VoidCallback onSelectExpense;

  const _FinancialOverviewPanel({
    required this.controller,
    required this.onSelectIncome,
    required this.onSelectExpense,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final balance = controller.balance;
    final income = controller.totalIncome;
    final expense = controller.totalExpense;
    final pendingIncome = controller.totalPendingIncome;
    final pendingExpense = controller.totalPendingExpense;
    final overdue = controller.totalOverdueExpense;
    final margin = income <= 0 ? 0.0 : balance / income;
    final expensePressure =
        income <= 0 ? (expense > 0 ? 1.0 : 0.0) : expense / income;
    final resultColor =
        balance >= 0 ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: resultColor,
        emphasized: true,
        radius: 22,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final hero = _FinancialBalanceHero(
            balance: balance,
            margin: margin,
            resultColor: resultColor,
            currency: currency,
          );
          final metrics = _FinancialMetricCluster(
            income: income,
            expense: expense,
            pendingIncome: pendingIncome,
            pendingExpense: pendingExpense,
            overdue: overdue,
            overdueCount: controller.overdueTransactions.length,
            expensePressure: expensePressure,
            currency: currency,
            onSelectIncome: onSelectIncome,
            onSelectExpense: onSelectExpense,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [hero, const SizedBox(height: 14), metrics],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: hero),
              const SizedBox(width: 14),
              Expanded(flex: 7, child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _FinancialBalanceHero extends StatelessWidget {
  final double balance;
  final double margin;
  final Color resultColor;
  final NumberFormat currency;

  const _FinancialBalanceHero({
    required this.balance,
    required this.margin,
    required this.resultColor,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final positive = balance >= 0;

    return Container(
      constraints: const BoxConstraints(minHeight: 198),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            resultColor.withValues(alpha: 0.16),
            AppColors.surfaceElevated.withValues(alpha: 0.76),
            AppColors.primaryDark.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: resultColor.withValues(alpha: 0.28)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -40,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resultColor.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: AppDecorations.iconTile(resultColor),
                    child: Icon(
                      positive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: resultColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo operacional',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          positive ? 'Fluxo positivo' : 'Fluxo em atencao',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: resultColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currency.format(value),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _FinancialPulseBar(value: margin, color: resultColor),
              const SizedBox(height: 9),
              Text(
                'Margem sobre entradas recebidas: ${(margin * 100).toStringAsFixed(1)}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialMetricCluster extends StatelessWidget {
  final double income;
  final double expense;
  final double pendingIncome;
  final double pendingExpense;
  final double overdue;
  final int overdueCount;
  final double expensePressure;
  final NumberFormat currency;
  final VoidCallback onSelectIncome;
  final VoidCallback onSelectExpense;

  const _FinancialMetricCluster({
    required this.income,
    required this.expense,
    required this.pendingIncome,
    required this.pendingExpense,
    required this.overdue,
    required this.overdueCount,
    required this.expensePressure,
    required this.currency,
    required this.onSelectIncome,
    required this.onSelectExpense,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _FinancialMiniMetric(
        label: 'Entradas recebidas',
        value: currency.format(income),
        icon: Icons.south_west_rounded,
        color: AppColors.accentGreen,
        onTap: onSelectIncome,
      ),
      _FinancialMiniMetric(
        label: 'Saidas pagas',
        value: currency.format(expense),
        icon: Icons.north_east_rounded,
        color: AppColors.accentRed,
        onTap: onSelectExpense,
      ),
      _FinancialMiniMetric(
        label: 'A receber',
        value: currency.format(pendingIncome),
        icon: Icons.hourglass_bottom_outlined,
        color: AppColors.accentBlue,
        onTap: onSelectIncome,
      ),
      _FinancialMiniMetric(
        label: 'A pagar',
        value: currency.format(pendingExpense),
        icon: Icons.schedule_outlined,
        color: Colors.orangeAccent,
        onTap: onSelectExpense,
      ),
    ];

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 2 : 1;
            const gap = 10.0;
            final itemWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: metrics
                  .map(
                    (metric) => SizedBox(
                      width: itemWidth,
                      child: _FinancialMiniMetricCard(metric: metric),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 10),
        _FinancialRiskBand(
          overdue: overdue,
          overdueCount: overdueCount,
          expensePressure: expensePressure,
          currency: currency,
        ),
      ],
    );
  }
}

class _FinancialMiniMetricCard extends StatelessWidget {
  final _FinancialMiniMetric metric;

  const _FinancialMiniMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: metric.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: metric.color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.iconTile(metric.color),
                child: Icon(metric.icon, color: metric.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        metric.value,
                        maxLines: 1,
                        style: TextStyle(
                          color: metric.color,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialRiskBand extends StatelessWidget {
  final double overdue;
  final int overdueCount;
  final double expensePressure;
  final NumberFormat currency;

  const _FinancialRiskBand({
    required this.overdue,
    required this.overdueCount,
    required this.expensePressure,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor =
        overdue > 0 || expensePressure >= 0.9
            ? AppColors.accentRed
            : expensePressure >= 0.65
            ? Colors.orangeAccent
            : AppColors.accentGreen;
    final pressure = expensePressure.clamp(0.0, 1.35);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            overdue > 0
                ? Icons.warning_amber_rounded
                : Icons.health_and_safety_outlined,
            color: riskColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overdue > 0
                      ? '$overdueCount titulo(s) vencido(s)'
                      : 'Pressao das saidas controlada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pressure.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.primaryDark.withValues(
                      alpha: 0.58,
                    ),
                    color: riskColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  overdue > 0
                      ? 'Vencidos: ${currency.format(overdue)}'
                      : 'Saidas equivalem a ${(expensePressure * 100).toStringAsFixed(1)}% das entradas.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _FinancialPulseBar extends StatelessWidget {
  final double value;
  final Color color;

  const _FinancialPulseBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final normalized = ((value + 1) / 2).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.62),
            ),
          ),
          FractionallySizedBox(
            widthFactor: normalized,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.45), color],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialMiniMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FinancialMiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
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
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        elevated: false,
        radius: 18,
      ),
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
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: AppDecorations.iconTile(AppColors.accentBlue),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.accentBlue,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtros da movimentacao',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Periodo, obra, status e ordenacao.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

class _FinancialLedgerPanel extends StatelessWidget {
  final TabController tabController;
  final bool isDesktop;
  final List<FinancialTransactionModel> visibleTransactions;
  final List<FinancialTransactionModel> incomeTransactions;
  final List<FinancialTransactionModel> expenseTransactions;
  final String query;

  const _FinancialLedgerPanel({
    required this.tabController,
    required this.isDesktop,
    required this.visibleTransactions,
    required this.incomeTransactions,
    required this.expenseTransactions,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final title = Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: AppDecorations.iconTile(AppColors.accentGold),
                      child: const Icon(
                        Icons.format_list_bulleted_rounded,
                        color: AppColors.accentGold,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Extrato financeiro',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _ledgerSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final tabs = _FinancialTabs(
                  tabController: tabController,
                  isDesktop: isDesktop,
                  allCount: visibleTransactions.length,
                  incomeCount: incomeTransactions.length,
                  expenseCount: expenseTransactions.length,
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: tabs),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 14),
                    SizedBox(width: 430, child: tabs),
                  ],
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.white10),
          ),
          const SizedBox(height: 8),
          if (isDesktop) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _LedgerTableHeader(),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _TransactionList(
                  transactions: visibleTransactions,
                  emptyLabel:
                      query.trim().isEmpty
                          ? 'Nenhuma movimentacao encontrada'
                          : 'Nenhuma movimentacao para a busca',
                ),
                _TransactionList(
                  transactions: incomeTransactions,
                  emptyLabel:
                      query.trim().isEmpty
                          ? 'Nenhuma entrada encontrada'
                          : 'Nenhuma entrada para a busca',
                ),
                _TransactionList(
                  transactions: expenseTransactions,
                  emptyLabel:
                      query.trim().isEmpty
                          ? 'Nenhuma saida encontrada'
                          : 'Nenhuma saida para a busca',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _ledgerSubtitle {
    if (visibleTransactions.isEmpty) {
      return 'Sem lancamentos no filtro atual';
    }
    return '${visibleTransactions.length} registro(s) filtrado(s), com leitura por data e status';
  }
}

class _LedgerTableHeader extends StatelessWidget {
  const _LedgerTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.30),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 46),
          Expanded(flex: 9, child: _LedgerHeaderText('Descricao')),
          SizedBox(width: 14),
          SizedBox(width: 118, child: _LedgerHeaderText('Origem')),
          SizedBox(width: 132, child: _LedgerHeaderText('Categoria')),
          SizedBox(width: 104, child: _LedgerHeaderText('Vencimento')),
          SizedBox(width: 104, child: _LedgerHeaderText('Status')),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _LedgerHeaderText('Valor'),
            ),
          ),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _LedgerHeaderText extends StatelessWidget {
  final String label;

  const _LedgerHeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
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
      return _EmptyLedgerState(emptyLabel: emptyLabel);
    }

    final groups = _buildGroups(transactions);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TransactionDateHeader(group: group),
            const SizedBox(height: 8),
            ...group.transactions.map(
              (transaction) => TransactionListItem(transaction: transaction),
            ),
          ],
        );
      },
    );
  }

  List<_TransactionGroup> _buildGroups(
    List<FinancialTransactionModel> transactions,
  ) {
    final map = <DateTime, List<FinancialTransactionModel>>{};
    for (final transaction in transactions) {
      final key = DateTime(
        transaction.dueDate.year,
        transaction.dueDate.month,
        transaction.dueDate.day,
      );
      map.putIfAbsent(key, () => []).add(transaction);
    }

    final groups =
        map.entries.map((entry) {
          final rows = entry.value;
          final income = rows
              .where((row) => row.type == TransactionType.income)
              .fold<double>(0, (sum, row) => sum + row.amount);
          final expense = rows
              .where((row) => row.type == TransactionType.expense)
              .fold<double>(0, (sum, row) => sum + row.amount);
          return _TransactionGroup(
            date: entry.key,
            transactions: rows,
            income: income,
            expense: expense,
          );
        }).toList();

    groups.sort((a, b) => a.date.compareTo(b.date));
    return groups;
  }
}

class _TransactionGroup {
  final DateTime date;
  final List<FinancialTransactionModel> transactions;
  final double income;
  final double expense;

  const _TransactionGroup({
    required this.date,
    required this.transactions,
    required this.income,
    required this.expense,
  });

  double get result => income - expense;
}

class _TransactionDateHeader extends StatelessWidget {
  final _TransactionGroup group;

  const _TransactionDateHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final result = group.result;
    final color = result >= 0 ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel(group.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.transactions.length} lancamento(s)',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(result),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'E ${currency.format(group.income)} | S ${currency.format(group.expense)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(date.year, date.month, date.day);
    final difference = normalized.difference(today).inDays;
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanha';
    if (difference == -1) return 'Ontem';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _EmptyLedgerState extends StatelessWidget {
  final String emptyLabel;

  const _EmptyLedgerState({required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 320 || constraints.maxWidth < 520;
        final iconSize = compact ? 38.0 : 58.0;

        return Center(
          child: Container(
            margin: EdgeInsets.all(compact ? 8 : 22),
            constraints: const BoxConstraints(maxWidth: 420),
            padding: EdgeInsets.all(compact ? 12 : 26),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.22),
              ),
            ),
            child:
                compact
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: AppDecorations.iconTile(
                            AppColors.accentBlue,
                          ),
                          child: const Icon(
                            Icons.manage_search_rounded,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emptyLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Ajuste os filtros ou crie um lancamento.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: AppDecorations.iconTile(
                            AppColors.accentBlue,
                          ),
                          child: const Icon(
                            Icons.manage_search_rounded,
                            color: AppColors.accentBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Ajuste os filtros ou crie um novo lancamento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }
}
