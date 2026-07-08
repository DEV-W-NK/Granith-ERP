import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/financial/transactionformdialog.dart';

/// Item de transação financeira com suporte a:
/// - tap para editar (abre TransactionFormDialog)
/// - swipe direita para marcar como pago
/// - swipe esquerda para cancelar
class TransactionListItem extends StatelessWidget {
  final FinancialTransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isPaid = t.status == TransactionStatus.paid;
    final isCancelled = t.status == TransactionStatus.cancelled;

    // Swipe desabilitado para transações já finalizadas
    if (isPaid || isCancelled) {
      return _buildCard(context, t);
    }

    return Dismissible(
      key: ValueKey(t.id),
      // Swipe direita → marcar como pago
      background: _swipeBg(
        alignment: Alignment.centerLeft,
        color: Colors.green.withOpacity(0.15),
        icon: Icons.check_circle_outline,
        label: 'Marcar pago',
        iconColor: Colors.greenAccent,
      ),
      // Swipe esquerda → cancelar
      secondaryBackground: _swipeBg(
        alignment: Alignment.centerRight,
        color: Colors.red.withOpacity(0.1),
        icon: Icons.cancel_outlined,
        label: 'Cancelar',
        iconColor: Colors.redAccent,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await context.read<FinancialController>().markAsPaid(t.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marcado como pago'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          final confirm = await _confirmCancel(context);
          if (confirm == true) {
            await context.read<FinancialController>().cancelTransaction(t.id);
          }
        }
        return false; // nunca remove da lista — o stream atualiza
      },
      child: _buildCard(context, t),
    );
  }

  Widget _buildCard(BuildContext context, FinancialTransactionModel t) {
    final isIncome = t.type == TransactionType.income;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final statusColor = _statusColor(t.status);
    final statusLabel = _statusLabel(t.status);
    final accent =
        t.isOverdue
            ? AppColors.accentRed
            : isIncome
            ? AppColors.accentGreen
            : AppColors.accentGold;

    return GestureDetector(
      onTap: () => TransactionFormDialog.show(context, initial: t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.cardSurface(
          accent: accent,
          emphasized: t.isOverdue,
          radius: 14,
        ),
        child: Row(
          children: [
            // Ícone tipo
            Container(
              width: 40,
              height: 40,
              decoration: AppDecorations.iconTile(accent),
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? Colors.greenAccent : Colors.redAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Descrição + metadados
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _chip(_categoryLabel(t.category)),
                      if (t.projectId != null) ...[
                        _chip(
                          'Projeto',
                          color: Colors.blueAccent.withOpacity(0.15),
                          textColor: Colors.blueAccent,
                        ),
                      ],
                      Text(
                        dateFormat.format(t.dueDate),
                        style: TextStyle(
                          color:
                              t.isOverdue
                                  ? Colors.redAccent
                                  : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Valor + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? "+" : "−"} ${currency.format(t.amount)}',
                  style: TextStyle(
                    color: isIncome ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _chip(String label, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor ?? AppColors.textMuted, fontSize: 10),
      ),
    );
  }

  Widget _swipeBg({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Cancelar transação?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'A transação será marcada como cancelada. O histórico será mantido.',
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
                  'Cancelar transação',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  Color _statusColor(TransactionStatus s) => switch (s) {
    TransactionStatus.paid => Colors.green,
    TransactionStatus.overdue => Colors.redAccent,
    TransactionStatus.cancelled => Colors.grey,
    TransactionStatus.pending => Colors.orange,
  };

  String _statusLabel(TransactionStatus s) => switch (s) {
    TransactionStatus.paid => 'PAGO',
    TransactionStatus.overdue => 'ATRASADO',
    TransactionStatus.cancelled => 'CANCELADO',
    TransactionStatus.pending => 'PENDENTE',
  };

  String _categoryLabel(TransactionCategory c) => switch (c) {
    TransactionCategory.material => 'Material',
    TransactionCategory.labor => 'M. de obra',
    TransactionCategory.equipment => 'Equipamento',
    TransactionCategory.administrative => 'Adm.',
    TransactionCategory.measurement => 'Medição',
    TransactionCategory.tax => 'Imposto',
    TransactionCategory.other => 'Outro',
  };
}
