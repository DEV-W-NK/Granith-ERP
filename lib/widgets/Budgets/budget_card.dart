import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isApproving;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onApprove,
    this.onReject,
    this.isApproving = false,
  });

  bool get _isExpired =>
      budget.expirationDate != null &&
      DateTime.now().isAfter(budget.expirationDate!) &&
      budget.status == BudgetStatus.pending;

  BudgetStatus get _status => _isExpired ? BudgetStatus.expired : budget.status;

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.cardSurface(
              accent: status.color,
              emphasized: status == BudgetStatus.pending,
              radius: 16,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final identity = _BudgetIdentity(budget: budget);
                final metrics = _BudgetMetrics(budget: budget, status: status);
                final hasActions = onApprove != null || onReject != null;
                final actions =
                    hasActions
                        ? _BudgetActionArea(
                          isApproving: isApproving,
                          onApprove: onApprove,
                          onReject: onReject,
                        )
                        : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _BudgetStatusChip(status: status),
                              if (budget.expirationDate != null)
                                _BudgetValidityChip(
                                  expirationDate: budget.expirationDate!,
                                  expired: _isExpired,
                                ),
                              if (budget.items.isNotEmpty)
                                _BudgetInfoChip(
                                  icon: Icons.list_rounded,
                                  label: _plural(
                                    budget.items.length,
                                    'item',
                                    'itens',
                                  ),
                                  color: AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          _BudgetMenu(onEdit: onEdit, onDelete: onDelete),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (compact) ...[
                      identity,
                      const SizedBox(height: 12),
                      metrics,
                      if (actions != null) ...[
                        const SizedBox(height: 12),
                        actions,
                      ],
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: identity),
                          const SizedBox(width: 18),
                          Expanded(flex: 4, child: metrics),
                          if (actions != null) ...[
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetIdentity extends StatelessWidget {
  final Budget budget;

  const _BudgetIdentity({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: AppDecorations.iconTile(AppColors.accentGold),
          child: const Icon(
            Icons.request_quote_rounded,
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                budget.projectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (budget.description.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  budget.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetMetrics extends StatelessWidget {
  final Budget budget;
  final BudgetStatus status;

  const _BudgetMetrics({required this.budget, required this.status});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricTile(
          label: 'Valor',
          value: _formatCurrency(budget.totalValue),
          color: AppColors.accentGold,
        ),
        _MetricTile(
          label: 'Criacao',
          value: _formatDate(budget.creationDate),
          color: AppColors.accentBlue,
        ),
        _MetricTile(
          label: 'Validade',
          value:
              budget.expirationDate == null
                  ? 'Sem data'
                  : _formatDate(budget.expirationDate!),
          color:
              status == BudgetStatus.expired
                  ? AppColors.accentRed
                  : AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _BudgetActionArea extends StatelessWidget {
  final bool isApproving;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _BudgetActionArea({
    required this.isApproving,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: isApproving ? null : onReject,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Rejeitar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentRed,
            side: BorderSide(
              color: AppColors.accentRed.withValues(alpha: 0.42),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isApproving ? null : onApprove,
          icon:
              isApproving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.check_rounded),
          label: Text(isApproving ? 'Aprovando...' : 'Aprovar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 122),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.cardInnerSurface(accent: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatusChip extends StatelessWidget {
  final BudgetStatus status;

  const _BudgetStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return _BudgetInfoChip(
      icon: status.icon,
      label: status.displayName,
      color: status.color,
    );
  }
}

class _BudgetValidityChip extends StatelessWidget {
  final DateTime expirationDate;
  final bool expired;

  const _BudgetValidityChip({
    required this.expirationDate,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = expirationDate.difference(DateTime.now()).inDays;
    final color =
        expired || daysLeft <= 3
            ? AppColors.accentRed
            : daysLeft <= 7
            ? AppColors.accentGold
            : AppColors.textSecondary;
    final label = expired ? 'Expirado' : '$daysLeft dias';

    return _BudgetInfoChip(
      icon: expired ? Icons.warning_rounded : Icons.schedule_rounded,
      label: label,
      color: color,
    );
  }
}

class _BudgetInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BudgetInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _BudgetMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
      color: AppColors.secondaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder:
          (_) => [
            if (onEdit != null)
              const PopupMenuItem(
                value: 'edit',
                child: _BudgetMenuItem(
                  icon: Icons.edit_rounded,
                  label: 'Editar',
                  color: AppColors.accentGold,
                ),
              ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: _BudgetMenuItem(
                  icon: Icons.delete_rounded,
                  label: 'Excluir',
                  color: AppColors.accentRed,
                ),
              ),
          ],
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
    );
  }
}

class _BudgetMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BudgetMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class BudgetTile extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const BudgetTile({
    super.key,
    required this.budget,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return BudgetCard(
      budget: budget,
      onTap: onTap,
      onDelete: onDelete,
      onEdit: onEdit,
    );
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

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
