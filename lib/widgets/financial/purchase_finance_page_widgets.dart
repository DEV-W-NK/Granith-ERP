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

class PurchaseFinancePageView extends StatefulWidget {
  const PurchaseFinancePageView({super.key});

  @override
  State<PurchaseFinancePageView> createState() =>
      _PurchaseFinancePageViewState();
}

class _PurchaseFinancePageViewState extends State<PurchaseFinancePageView> {
  final _searchCtrl = TextEditingController();
  _PurchaseFinanceFilter _filter = _PurchaseFinanceFilter.open;
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
    final transactions = _applyFilters(ctrl.purchaseTransactions);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body:
          ctrl.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              )
              : Padding(
                padding: ResponsiveLayout.pagePadding(width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(isDesktop: isDesktop),
                    SizedBox(height: isDesktop ? 20 : 14),
                    _StatsRow(controller: ctrl),
                    SizedBox(height: isDesktop ? 18 : 12),
                    _Toolbar(
                      searchController: _searchCtrl,
                      filter: _filter,
                      onSearchChanged:
                          (value) => setState(() => _query = value),
                      onFilterChanged:
                          (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child:
                          transactions.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                                itemCount: transactions.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder:
                                    (context, index) => _PurchasePayableCard(
                                      transaction: transactions[index],
                                      canManage: canManage,
                                    ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  List<FinancialTransactionModel> _applyFilters(
    List<FinancialTransactionModel> transactions,
  ) {
    final query = _query.trim().toLowerCase();

    return transactions.where((transaction) {
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
  }
}

class _Header extends StatelessWidget {
  final bool isDesktop;

  const _Header({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isDesktop ? 46 : 40,
          height: isDesktop ? 46 : 40,
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.24),
            ),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compras no Financeiro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Contas a pagar originadas por compras',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final FinancialController controller;

  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final purchases = controller.purchaseTransactions;
    final open = controller.pendingPurchaseTransactions;
    final overdue =
        open
            .where(
              (transaction) =>
                  transaction.status == TransactionStatus.overdue ||
                  transaction.isOverdue,
            )
            .toList();
    final paid = purchases
        .where((transaction) => transaction.status == TransactionStatus.paid)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatTile(
            title: 'Em aberto',
            value: controller.totalPendingPurchaseTransactions,
            icon: Icons.pending_actions_rounded,
            color: Colors.orangeAccent,
            count: open.length,
          ),
          const SizedBox(width: 10),
          _StatTile(
            title: 'Vencidas',
            value: overdue.fold(0.0, (sum, item) => sum + item.amount),
            icon: Icons.warning_amber_rounded,
            color: AppColors.accentRed,
            count: overdue.length,
          ),
          const SizedBox(width: 10),
          _StatTile(
            title: 'Pagas',
            value: paid,
            icon: Icons.check_circle_outline,
            color: AppColors.accentGreen,
          ),
          const SizedBox(width: 10),
          _StatTile(
            title: 'Total vinculado',
            value: controller.totalPurchaseTransactions,
            icon: Icons.link_rounded,
            color: AppColors.accentBlue,
            count: purchases.length,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final int? count;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (count != null)
                  Text(
                    '$count registro${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
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

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final _PurchaseFinanceFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_PurchaseFinanceFilter> onFilterChanged;

  const _Toolbar({
    required this.searchController,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Buscar por compra, projeto, fornecedor ou ID',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
          ),
        );
        final filters = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterPill(
              label: 'Em aberto',
              selected: filter == _PurchaseFinanceFilter.open,
              onTap: () => onFilterChanged(_PurchaseFinanceFilter.open),
            ),
            _FilterPill(
              label: 'Pagas',
              selected: filter == _PurchaseFinanceFilter.paid,
              onTap: () => onFilterChanged(_PurchaseFinanceFilter.paid),
            ),
            _FilterPill(
              label: 'Canceladas',
              selected: filter == _PurchaseFinanceFilter.cancelled,
              onTap: () => onFilterChanged(_PurchaseFinanceFilter.cancelled),
            ),
            _FilterPill(
              label: 'Todas',
              selected: filter == _PurchaseFinanceFilter.all,
              onTap: () => onFilterChanged(_PurchaseFinanceFilter.all),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [search, const SizedBox(height: 10), filters],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 14),
            filters,
          ],
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentGold : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.accentGold.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? AppColors.accentGold.withValues(alpha: 0.42)
                    : AppColors.borderColor.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
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
    final closed =
        transaction.status == TransactionStatus.paid ||
        transaction.status == TransactionStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              transaction.isOverdue
                  ? AppColors.accentRed.withValues(alpha: 0.36)
                  : AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: _statusLabel(transaction),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
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
                ],
              ),
              if (transaction.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  transaction.notes!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );

          final amountAndActions = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(transaction.amount),
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              if (!closed && canManage)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Marcar pago',
                      color: AppColors.accentGreen,
                      onTap: () => _confirmPayment(context),
                    ),
                    _ActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancelar',
                      color: AppColors.accentRed,
                      onTap: () => _confirmCancel(context),
                    ),
                  ],
                )
              else if (!closed)
                const _ReadOnlyBadge(),
            ],
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
