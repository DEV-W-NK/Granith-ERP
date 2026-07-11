import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/financial/transactionformdialog.dart';
import 'package:provider/provider.dart';

class TransactionListItem extends StatelessWidget {
  final FinancialTransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isFinal =
        transaction.status == TransactionStatus.paid ||
        transaction.status == TransactionStatus.cancelled;

    if (isFinal) {
      return _buildBody(context, transaction);
    }

    return Dismissible(
      key: ValueKey(transaction.id),
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.accentGreen,
        icon: Icons.check_circle_outline_rounded,
        label: 'Marcar pago',
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.accentRed,
        icon: Icons.cancel_outlined,
        label: 'Cancelar',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await context.read<FinancialController>().markAsPaid(transaction.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marcado como pago'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return false;
        }

        final controller = context.read<FinancialController>();
        final confirmed = await _confirmCancel(context);
        if (confirmed == true) {
          await controller.cancelTransaction(transaction.id);
        }
        return false;
      },
      child: _buildBody(context, transaction),
    );
  }

  Widget _buildBody(BuildContext context, FinancialTransactionModel t) {
    final isIncome = t.type == TransactionType.income;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final statusColor = _statusColor(t.status);
    final accent =
        t.isOverdue
            ? AppColors.accentRed
            : isIncome
            ? AppColors.accentGreen
            : AppColors.accentGold;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final content =
            compact
                ? _CompactTransactionRow(
                  transaction: t,
                  isIncome: isIncome,
                  accent: accent,
                  statusColor: statusColor,
                  statusLabel: _statusLabel(t.status),
                  date: dateFormat.format(t.dueDate),
                  amount: _signedAmount(currency, t),
                )
                : _DesktopTransactionRow(
                  transaction: t,
                  isIncome: isIncome,
                  accent: accent,
                  statusColor: statusColor,
                  statusLabel: _statusLabel(t.status),
                  date: dateFormat.format(t.dueDate),
                  amount: _signedAmount(currency, t),
                  category: _categoryLabel(t.category),
                  origin: _originLabel(t.origin),
                );

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => TransactionFormDialog.show(context, initial: t),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 14,
                  vertical: compact ? 10 : 11,
                ),
                decoration: BoxDecoration(
                  color:
                      t.isOverdue
                          ? AppColors.accentRed.withValues(alpha: 0.055)
                          : AppColors.primaryDark.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        t.isOverdue
                            ? AppColors.accentRed.withValues(alpha: 0.32)
                            : AppColors.borderColor.withValues(alpha: 0.30),
                  ),
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }

  String _signedAmount(NumberFormat currency, FinancialTransactionModel t) {
    final sign = t.type == TransactionType.income ? '+' : '-';
    return '$sign ${currency.format(t.amount)}';
  }

  Widget _swipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    final isRight = alignment == Alignment.centerRight;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRight) Text(label, style: _swipeText(color)),
          if (isRight) const SizedBox(width: 8),
          Icon(icon, color: color, size: 19),
          if (!isRight) const SizedBox(width: 8),
          if (!isRight) Text(label, style: _swipeText(color)),
        ],
      ),
    );
  }

  TextStyle _swipeText(Color color) {
    return TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800);
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Cancelar transacao?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'O lancamento sera marcado como cancelado e mantido no historico.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Voltar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Cancelar transacao',
                  style: TextStyle(color: AppColors.accentRed),
                ),
              ),
            ],
          ),
    );
  }

  Color _statusColor(TransactionStatus status) => switch (status) {
    TransactionStatus.paid => AppColors.accentGreen,
    TransactionStatus.overdue => AppColors.accentRed,
    TransactionStatus.cancelled => AppColors.textMuted,
    TransactionStatus.pending => AppColors.accentGold,
  };

  String _statusLabel(TransactionStatus status) => switch (status) {
    TransactionStatus.paid => 'PAGO',
    TransactionStatus.overdue => 'ATRASADO',
    TransactionStatus.cancelled => 'CANCELADO',
    TransactionStatus.pending => 'PENDENTE',
  };

  String _categoryLabel(TransactionCategory category) => switch (category) {
    TransactionCategory.material => 'Material',
    TransactionCategory.labor => 'Mao de obra',
    TransactionCategory.equipment => 'Equipamento',
    TransactionCategory.administrative => 'Administrativo',
    TransactionCategory.measurement => 'Medicao',
    TransactionCategory.tax => 'Imposto',
    TransactionCategory.other => 'Outro',
  };

  String _originLabel(TransactionOrigin origin) => switch (origin) {
    TransactionOrigin.manual => 'Manual',
    TransactionOrigin.purchase => 'Compra',
    TransactionOrigin.laborCost => 'Mao de obra',
    TransactionOrigin.materialUsage => 'Uso material',
    TransactionOrigin.budget => 'Orcamento',
  };
}

class _DesktopTransactionRow extends StatelessWidget {
  final FinancialTransactionModel transaction;
  final bool isIncome;
  final Color accent;
  final Color statusColor;
  final String statusLabel;
  final String date;
  final String amount;
  final String category;
  final String origin;

  const _DesktopTransactionRow({
    required this.transaction,
    required this.isIncome,
    required this.accent,
    required this.statusColor,
    required this.statusLabel,
    required this.date,
    required this.amount,
    required this.category,
    required this.origin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DirectionMarker(isIncome: isIncome, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          flex: 9,
          child: _TransactionIdentity(transaction: transaction),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 118,
          child: _LedgerMeta(label: 'Origem', value: origin),
        ),
        SizedBox(
          width: 132,
          child: _LedgerMeta(label: 'Categoria', value: category),
        ),
        SizedBox(
          width: 104,
          child: _LedgerMeta(
            label: 'Vencimento',
            value: date,
            valueColor:
                transaction.isOverdue
                    ? AppColors.accentRed
                    : AppColors.textSecondary,
          ),
        ),
        SizedBox(
          width: 104,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatusBadge(label: statusLabel, color: statusColor),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isIncome ? AppColors.accentGreen : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
      ],
    );
  }
}

class _CompactTransactionRow extends StatelessWidget {
  final FinancialTransactionModel transaction;
  final bool isIncome;
  final Color accent;
  final Color statusColor;
  final String statusLabel;
  final String date;
  final String amount;

  const _CompactTransactionRow({
    required this.transaction,
    required this.isIncome,
    required this.accent,
    required this.statusColor,
    required this.statusLabel,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DirectionMarker(isIncome: isIncome, accent: accent),
        const SizedBox(width: 11),
        Expanded(child: _TransactionIdentity(transaction: transaction)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isIncome ? AppColors.accentGreen : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color:
                        transaction.isOverdue
                            ? AppColors.accentRed
                            : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                _StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DirectionMarker extends StatelessWidget {
  final bool isIncome;
  final Color accent;

  const _DirectionMarker({required this.isIncome, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Icon(
        isIncome ? Icons.north_east_rounded : Icons.south_west_rounded,
        color: accent,
        size: 18,
      ),
    );
  }
}

class _TransactionIdentity extends StatelessWidget {
  final FinancialTransactionModel transaction;

  const _TransactionIdentity({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final scope = transaction.hasProject ? 'Projeto' : 'Administrativo';
    final note = transaction.notes?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _TinyPill(label: scope, color: AppColors.accentBlue),
            if (transaction.referenceId?.trim().isNotEmpty == true) ...[
              const SizedBox(width: 6),
              _TinyPill(label: 'Origem vinculada', color: AppColors.accentGold),
            ],
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _LedgerMeta extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _LedgerMeta({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
