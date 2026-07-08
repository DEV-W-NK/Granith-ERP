import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

enum _PurchaseFinanceFilter { open, paid, cancelled, all }

enum _PurchaseFinanceSort { dueDateAsc, amountDesc, recentCreated, supplier }

class PurchaseFinancePageView extends StatefulWidget {
  const PurchaseFinancePageView({super.key});

  @override
  State<PurchaseFinancePageView> createState() =>
      _PurchaseFinancePageViewState();
}

class _PurchaseFinancePageViewState extends State<PurchaseFinancePageView> {
  final _searchCtrl = TextEditingController();
  _PurchaseFinanceFilter _filter = _PurchaseFinanceFilter.open;
  _PurchaseFinanceSort _sort = _PurchaseFinanceSort.dueDateAsc;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;
    final permissions = user?.permissions ?? const <String>[];
    final isAdmin = auth.isAdminUser || (user?.isAdmin ?? false);
    final canView = PermissionCodes.canViewPurchaseFinance(
      isAdmin: isAdmin,
      permissions: permissions,
    );
    final canManage = PermissionCodes.canManagePurchaseFinance(
      isAdmin: isAdmin,
      permissions: permissions,
    );

    if (!canView) {
      return const _AccessDeniedState();
    }

    final ctrl = context.watch<FinancialController>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 900;
    final purchaseTransactions = ctrl.purchaseTransactions;
    final transactions = _applyFilters(purchaseTransactions);
    final summary = _PurchaseFinanceSummary.from(purchaseTransactions);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body:
          ctrl.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              )
              : SafeArea(
                child: Padding(
                  padding: ResponsiveLayout.pagePadding(width),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useFullPageScroll =
                          constraints.maxHeight < 760 ||
                          constraints.maxWidth < 720;
                      final headerAndTools = <Widget>[
                        _Header(
                          isDesktop: isDesktop,
                          summary: summary,
                          visibleCount: transactions.length,
                          canManage: canManage,
                        ),
                        SizedBox(height: isDesktop ? 10 : 8),
                        _Toolbar(
                          searchController: _searchCtrl,
                          filter: _filter,
                          sort: _sort,
                          visibleCount: transactions.length,
                          totalCount: purchaseTransactions.length,
                          onSearchChanged:
                              (value) => setState(() => _query = value),
                          onClearSearch:
                              _query.isEmpty
                                  ? null
                                  : () {
                                    setState(() {
                                      _searchCtrl.clear();
                                      _query = '';
                                    });
                                  },
                          onFilterChanged:
                              (value) => setState(() => _filter = value),
                          onSortChanged:
                              (value) => setState(() => _sort = value),
                        ),
                        SizedBox(height: isDesktop ? 10 : 8),
                        _StatsRow(summary: summary),
                        const SizedBox(height: 10),
                      ];

                      if (useFullPageScroll) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...headerAndTools,
                              _PayablesList(
                                transactions: transactions,
                                canManage: canManage,
                                shrinkWrap: true,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...headerAndTools,
                          Expanded(
                            child: _PayablesList(
                              transactions: transactions,
                              canManage: canManage,
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

  List<FinancialTransactionModel> _applyFilters(
    List<FinancialTransactionModel> transactions,
  ) {
    final query = _query.trim().toLowerCase();

    final filtered =
        transactions.where((transaction) {
          final statusMatches = switch (_filter) {
            _PurchaseFinanceFilter.open =>
              transaction.status == TransactionStatus.pending ||
                  transaction.status == TransactionStatus.overdue ||
                  transaction.isOverdue,
            _PurchaseFinanceFilter.paid =>
              transaction.status == TransactionStatus.paid,
            _PurchaseFinanceFilter.cancelled =>
              transaction.status == TransactionStatus.cancelled,
            _PurchaseFinanceFilter.all => true,
          };
          if (!statusMatches) return false;

          if (query.isEmpty) return true;
          final searchable =
              [
                transaction.description,
                transaction.projectId,
                transaction.supplierId,
                transaction.referenceId,
                transaction.notes,
              ].whereType<String>().join(' ').toLowerCase();
          return searchable.contains(query);
        }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _PurchaseFinanceSort.dueDateAsc => _compareDueDate(a, b),
        _PurchaseFinanceSort.amountDesc => b.amount.compareTo(a.amount),
        _PurchaseFinanceSort.recentCreated => b.createdAt.compareTo(
          a.createdAt,
        ),
        _PurchaseFinanceSort.supplier => (a.supplierId ?? '').compareTo(
          b.supplierId ?? '',
        ),
      };
    });

    return filtered;
  }
}

class _Header extends StatelessWidget {
  final bool isDesktop;
  final _PurchaseFinanceSummary summary;
  final int visibleCount;
  final bool canManage;

  const _Header({
    required this.isDesktop,
    required this.summary,
    required this.visibleCount,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final title = Row(
      children: [
        Container(
          width: isDesktop ? 50 : 42,
          height: isDesktop ? 50 : 42,
          decoration: AppDecorations.iconTile(AppColors.accentGold),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compras no Financeiro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                visibleCount == summary.totalCount
                    ? '${summary.totalCount} conta${summary.totalCount == 1 ? '' : 's'} vinculada${summary.totalCount == 1 ? '' : 's'} a compras'
                    : '$visibleCount de ${summary.totalCount} contas exibidas',
                maxLines: 1,
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

    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isDesktop ? WrapAlignment.end : WrapAlignment.start,
      children: [
        _HeaderBadge(
          icon: Icons.account_balance_wallet_outlined,
          label: currency.format(summary.pendingAmount),
          color:
              summary.overdueCount > 0
                  ? AppColors.accentRed
                  : AppColors.accentGold,
        ),
        _HeaderBadge(
          icon: Icons.warning_amber_rounded,
          label:
              summary.overdueCount == 0
                  ? 'Sem vencidas'
                  : '${summary.overdueCount} vencida${summary.overdueCount == 1 ? '' : 's'}',
          color:
              summary.overdueCount == 0
                  ? AppColors.accentGreen
                  : AppColors.accentRed,
        ),
        _HeaderBadge(
          icon: canManage ? Icons.lock_open_rounded : Icons.lock_outline,
          label: canManage ? 'Financeiro ativo' : 'Consulta',
          color: canManage ? AppColors.accentGreen : AppColors.textMuted,
        ),
      ],
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), badges],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 18),
        Flexible(child: badges),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _PurchaseFinanceSummary summary;

  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        title: 'Em aberto',
        value: summary.pendingAmount,
        icon: Icons.pending_actions_rounded,
        color: AppColors.accentGold,
        count: summary.pendingCount,
        detail: 'Aguardando pagamento',
      ),
      _StatTile(
        title: 'Vencidas',
        value: summary.overdueAmount,
        icon: Icons.warning_amber_rounded,
        color:
            summary.overdueCount == 0
                ? AppColors.accentGreen
                : AppColors.accentRed,
        count: summary.overdueCount,
        detail: summary.overdueCount == 0 ? 'Sem atraso' : 'Exigem acao hoje',
      ),
      _StatTile(
        title: 'Pagas',
        value: summary.paidAmount,
        icon: Icons.check_circle_outline,
        color: AppColors.accentGreen,
        count: summary.paidCount,
        detail: '${_formatPercent(summary.paidRatio)} do total',
      ),
      _StatTile(
        title: 'Total vinculado',
        value: summary.totalAmount,
        icon: Icons.link_rounded,
        color: AppColors.accentBlue,
        count: summary.totalCount,
        detail: 'Originado em compras',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useFullWidthCards = constraints.maxWidth >= 880;

        if (useFullWidthCards) {
          return SizedBox(
            height: 94,
            child: Row(
              children: [
                for (var index = 0; index < tiles.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(child: tiles[index]),
                ],
              ],
            ),
          );
        }

        return SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder:
                (context, index) => SizedBox(width: 210, child: tiles[index]),
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final int? count;
  final String detail;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.detail,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      height: 94,
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.statCardSurface(color, radius: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: AppDecorations.iconTile(color),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (count != null)
                      _TinyCountBadge(count: count!, color: color),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  currency.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
    );
  }
}

class _TinyCountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _TinyCountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PayablesList extends StatelessWidget {
  final List<FinancialTransactionModel> transactions;
  final bool canManage;
  final bool shrinkWrap;

  const _PayablesList({
    required this.transactions,
    required this.canManage,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics:
          shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder:
          (context, index) => _PurchasePayableCard(
            transaction: transactions[index],
            canManage: canManage,
          ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final _PurchaseFinanceFilter filter;
  final _PurchaseFinanceSort sort;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClearSearch;
  final ValueChanged<_PurchaseFinanceFilter> onFilterChanged;
  final ValueChanged<_PurchaseFinanceSort> onSortChanged;

  const _Toolbar({
    required this.searchController,
    required this.filter,
    required this.sort,
    required this.visibleCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentBlue,
        radius: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          final search = TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar por compra, projeto, fornecedor ou ID',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              suffixIcon:
                  onClearSearch == null
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
            ),
          );
          final sortField = DropdownButtonFormField<_PurchaseFinanceSort>(
            initialValue: sort,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Ordenar',
            ),
            items:
                _PurchaseFinanceSort.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_sortLabel(option)),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          );
          final filterField = DropdownButtonFormField<_PurchaseFinanceFilter>(
            initialValue: filter,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Status',
            ),
            items:
                _PurchaseFinanceFilter.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_filterLabel(option)),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) onFilterChanged(value);
            },
          );
          final counter = Text(
            '$visibleCount de $totalCount conta${totalCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: sortField),
                    const SizedBox(width: 8),
                    Expanded(child: filterField),
                  ],
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: counter),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: search),
              const SizedBox(width: 10),
              SizedBox(width: 190, child: sortField),
              const SizedBox(width: 10),
              SizedBox(width: 190, child: filterField),
              const SizedBox(width: 10),
              counter,
            ],
          );
        },
      ),
    );
  }
}

class _PurchasePayableCard extends StatelessWidget {
  final FinancialTransactionModel transaction;
  final bool canManage;

  const _PurchasePayableCard({
    required this.transaction,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _statusColor(transaction);
    final dueLabel = _relativeDueLabel(transaction.dueDate);
    final closed =
        transaction.status == TransactionStatus.paid ||
        transaction.status == TransactionStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: statusColor,
        emphasized: transaction.isOverdue,
        radius: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusBadge(
                    label: _statusLabel(transaction),
                    color: statusColor,
                  ),
                  _DueBadge(
                    label:
                        transaction.status == TransactionStatus.paid &&
                                transaction.paymentDate != null
                            ? 'Pago em ${dateFormat.format(transaction.paymentDate!)}'
                            : dueLabel,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                transaction.description,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: AppDecorations.cardInnerSurface(
                  accent: statusColor,
                  radius: 8,
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Venc. ${dateFormat.format(transaction.dueDate)}',
                      color:
                          transaction.isOverdue
                              ? AppColors.accentRed
                              : AppColors.textMuted,
                    ),
                    if (transaction.projectId?.trim().isNotEmpty == true)
                      _MetaChip(
                        icon: Icons.folder_outlined,
                        label: 'Projeto ${transaction.projectId}',
                      ),
                    if (transaction.supplierId?.trim().isNotEmpty == true)
                      _MetaChip(
                        icon: Icons.store_outlined,
                        label: 'Fornecedor ${transaction.supplierId}',
                      ),
                    if (transaction.referenceId?.trim().isNotEmpty == true)
                      _MetaChip(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Compra ${transaction.referenceId}',
                      ),
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: _categoryLabel(transaction.category),
                    ),
                  ],
                ),
              ),
              if (transaction.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMid.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.borderColor.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Text(
                    transaction.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.28,
                    ),
                  ),
                ),
              ],
            ],
          );

          final amountAndActions = _AmountAndActions(
            amount: currency.format(transaction.amount),
            statusColor: statusColor,
            closed: closed,
            canManage: canManage,
            onPayment: () => _confirmPayment(context),
            onCancel: () => _confirmCancel(context),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 12), amountAndActions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: info),
              const SizedBox(width: 18),
              amountAndActions,
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Marcar conta como paga?',
      message: transaction.description,
      confirmLabel: 'Marcar pago',
      color: AppColors.accentGreen,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<FinancialController>().markAsPaid(transaction.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conta de compra marcada como paga'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Cancelar conta de compra?',
      message: transaction.description,
      confirmLabel: 'Cancelar conta',
      color: AppColors.accentRed,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<FinancialController>().cancelTransaction(transaction.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conta de compra cancelada'),
        backgroundColor: AppColors.accentRed,
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
  }

  Color _statusColor(FinancialTransactionModel transaction) {
    if (transaction.isOverdue ||
        transaction.status == TransactionStatus.overdue) {
      return AppColors.accentRed;
    }
    return switch (transaction.status) {
      TransactionStatus.paid => AppColors.accentGreen,
      TransactionStatus.cancelled => AppColors.textMuted,
      TransactionStatus.pending => Colors.orangeAccent,
      TransactionStatus.overdue => AppColors.accentRed,
    };
  }

  String _statusLabel(FinancialTransactionModel transaction) {
    if (transaction.isOverdue ||
        transaction.status == TransactionStatus.overdue) {
      return 'Vencida';
    }
    return switch (transaction.status) {
      TransactionStatus.paid => 'Paga',
      TransactionStatus.cancelled => 'Cancelada',
      TransactionStatus.pending => 'Pendente',
      TransactionStatus.overdue => 'Vencida',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DueBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: resolvedColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: resolvedColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _AmountAndActions extends StatelessWidget {
  final String amount;
  final Color statusColor;
  final bool closed;
  final bool canManage;
  final VoidCallback onPayment;
  final VoidCallback onCancel;

  const _AmountAndActions({
    required this.amount,
    required this.statusColor,
    required this.closed,
    required this.canManage,
    required this.onPayment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardInnerSurface(
        accent: statusColor,
        radius: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valor da conta',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (!closed && canManage)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Marcar pago',
                  color: AppColors.accentGreen,
                  onTap: onPayment,
                ),
                _ActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelar',
                  color: AppColors.accentRed,
                  onTap: onCancel,
                ),
              ],
            )
          else if (!closed)
            const _ReadOnlyBadge()
          else
            _ClosedBadge(color: statusColor),
        ],
      ),
    );
  }
}

class _ClosedBadge extends StatelessWidget {
  final Color color;

  const _ClosedBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        'Fluxo encerrado',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'Somente financeiro quita',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PurchaseFinanceSummary {
  final int totalCount;
  final int pendingCount;
  final int overdueCount;
  final int paidCount;
  final int cancelledCount;
  final int dueSoonCount;
  final double totalAmount;
  final double pendingAmount;
  final double overdueAmount;
  final double paidAmount;
  final double largestOpenAmount;
  final double averageTicket;
  final DateTime? nextDueDate;

  const _PurchaseFinanceSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidCount,
    required this.cancelledCount,
    required this.dueSoonCount,
    required this.totalAmount,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.paidAmount,
    required this.largestOpenAmount,
    required this.averageTicket,
    required this.nextDueDate,
  });

  int get openCount => pendingCount + overdueCount;

  double get paidRatio {
    if (totalAmount <= 0) return 0;
    return paidAmount / totalAmount;
  }

  factory _PurchaseFinanceSummary.from(
    List<FinancialTransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final dueSoonLimit = now.add(const Duration(days: 7));
    final openTransactions =
        transactions.where(_isOpenPurchasePayable).toList()
          ..sort(_compareDueDate);
    final overdueTransactions =
        transactions.where(_isOverduePurchasePayable).toList();
    final paidTransactions =
        transactions
            .where((item) => item.status == TransactionStatus.paid)
            .toList();
    final cancelledCount =
        transactions
            .where((item) => item.status == TransactionStatus.cancelled)
            .length;
    final dueSoonCount =
        openTransactions
            .where(
              (item) =>
                  !item.dueDate.isBefore(_dateOnly(now)) &&
                  !item.dueDate.isAfter(dueSoonLimit),
            )
            .length;
    final totalAmount = transactions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final pendingAmount = openTransactions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final overdueAmount = overdueTransactions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final paidAmount = paidTransactions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final largestOpenAmount = openTransactions.fold<double>(
      0,
      (max, item) => item.amount > max ? item.amount : max,
    );

    return _PurchaseFinanceSummary(
      totalCount: transactions.length,
      pendingCount: openTransactions.length - overdueTransactions.length,
      overdueCount: overdueTransactions.length,
      paidCount: paidTransactions.length,
      cancelledCount: cancelledCount,
      dueSoonCount: dueSoonCount,
      totalAmount: totalAmount,
      pendingAmount: pendingAmount,
      overdueAmount: overdueAmount,
      paidAmount: paidAmount,
      largestOpenAmount: largestOpenAmount,
      averageTicket:
          transactions.isEmpty ? 0 : totalAmount / transactions.length,
      nextDueDate:
          openTransactions.isEmpty ? null : openTransactions.first.dueDate,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma conta de compra encontrada',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDeniedState extends StatelessWidget {
  const _AccessDeniedState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Text(
          'Voce nao tem permissao para ver contas de compras.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

int _compareDueDate(FinancialTransactionModel a, FinancialTransactionModel b) {
  final statusRank = _paymentPriority(a).compareTo(_paymentPriority(b));
  if (statusRank != 0) return statusRank;
  return a.dueDate.compareTo(b.dueDate);
}

int _paymentPriority(FinancialTransactionModel transaction) {
  if (_isOverduePurchasePayable(transaction)) return 0;
  if (_isOpenPurchasePayable(transaction)) return 1;
  if (transaction.status == TransactionStatus.paid) return 2;
  return 3;
}

bool _isOpenPurchasePayable(FinancialTransactionModel transaction) {
  return transaction.status == TransactionStatus.pending ||
      transaction.status == TransactionStatus.overdue ||
      transaction.isOverdue;
}

bool _isOverduePurchasePayable(FinancialTransactionModel transaction) {
  return transaction.status == TransactionStatus.overdue ||
      transaction.isOverdue;
}

String _sortLabel(_PurchaseFinanceSort sort) {
  return switch (sort) {
    _PurchaseFinanceSort.dueDateAsc => 'Prioridade',
    _PurchaseFinanceSort.amountDesc => 'Maior valor',
    _PurchaseFinanceSort.recentCreated => 'Mais recentes',
    _PurchaseFinanceSort.supplier => 'Fornecedor',
  };
}

String _filterLabel(_PurchaseFinanceFilter filter) {
  return switch (filter) {
    _PurchaseFinanceFilter.open => 'Em aberto',
    _PurchaseFinanceFilter.paid => 'Pagas',
    _PurchaseFinanceFilter.cancelled => 'Canceladas',
    _PurchaseFinanceFilter.all => 'Todas',
  };
}

String _categoryLabel(TransactionCategory category) {
  return switch (category) {
    TransactionCategory.material => 'Materiais',
    TransactionCategory.labor => 'Mao de obra',
    TransactionCategory.equipment => 'Equipamentos',
    TransactionCategory.administrative => 'Administrativo',
    TransactionCategory.measurement => 'Medicao',
    TransactionCategory.tax => 'Impostos',
    TransactionCategory.other => 'Outros',
  };
}

String _relativeDueLabel(DateTime dueDate) {
  final today = _dateOnly(DateTime.now());
  final due = _dateOnly(dueDate);
  final days = due.difference(today).inDays;

  if (days < 0) {
    final elapsed = days.abs();
    return 'Vencida ha $elapsed dia${elapsed == 1 ? '' : 's'}';
  }
  if (days == 0) return 'Vence hoje';
  if (days == 1) return 'Vence amanha';
  if (days <= 7) return 'Vence em $days dias';
  return 'Vence em ${DateFormat('dd/MM').format(dueDate)}';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _formatPercent(double value) => '${(value * 100).toStringAsFixed(0)}%';
