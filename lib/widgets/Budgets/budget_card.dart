import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  // ── Novos: fluxo de aprovação (regra #21) ─────────────────────────────────
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

  String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";

  bool _isExpired() =>
      budget.expirationDate != null &&
      DateTime.now().isAfter(budget.expirationDate!) &&
      budget.status == BudgetStatus.pending;

  BudgetStatus _getActualStatus() =>
      _isExpired() ? BudgetStatus.expired : budget.status;

  // ── Status badge ──────────────────────────────────────────────────────────
  Widget _buildStatusBadge() {
    final s = _getActualStatus();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: s.color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 12, color: s.color),
        const SizedBox(width: 4),
        Text(s.displayName,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: s.color)),
      ]),
    );
  }

  // ── Expiration indicator ──────────────────────────────────────────────────
  Widget _buildExpirationIndicator() {
    if (budget.expirationDate == null) return const SizedBox.shrink();

    final daysLeft = budget.expirationDate!.difference(DateTime.now()).inDays;
    final Color color;
    final IconData icon;
    final String text;

    if (_isExpired()) {
      color = AppColors.accentRed;
      icon  = Icons.warning_rounded;
      text  = 'Expirado';
    } else if (daysLeft <= 3) {
      color = AppColors.accentRed;
      icon  = Icons.warning_amber_rounded;
      text  = '${daysLeft}d';
    } else if (daysLeft <= 7) {
      color = Colors.orange;
      icon  = Icons.schedule_rounded;
      text  = '${daysLeft}d';
    } else {
      color = AppColors.textMuted;
      icon  = Icons.schedule_rounded;
      text  = '${daysLeft}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ── Botões Aprovar / Rejeitar — só para orçamentos pendentes ─────────────
  Widget _buildApprovalActions() {
    if (onApprove == null && onReject == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        // Rejeitar
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isApproving ? null : onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentRed,
              side: BorderSide(color: AppColors.accentRed.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.close_rounded, size: 15),
            label: const Text('Rejeitar',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        // Aprovar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isApproving ? null : onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: isApproving
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDark),
                  )
                : const Icon(Icons.check_rounded, size: 15),
            label: Text(
              isApproving ? 'Aprovando...' : 'Aprovar',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final actualStatus = _getActualStatus();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: actualStatus.color.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: actualStatus.color.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: Row(children: [
                      _buildStatusBadge(),
                      const SizedBox(width: 8),
                      _buildExpirationIndicator(),
                    ]),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textMuted, size: 18),
                    color: AppColors.secondaryDark,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.accentGold),
                          const SizedBox(width: 8),
                          const Text('Editar',
                              style:
                                  TextStyle(color: AppColors.textPrimary)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete_rounded,
                              size: 16, color: AppColors.accentRed),
                          const SizedBox(width: 8),
                          const Text('Excluir',
                              style: TextStyle(color: AppColors.accentRed)),
                        ]),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Cliente / Projeto / Valor ─────────────────────────────
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.person_rounded,
                                size: 12, color: AppColors.accentGold),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(budget.clientName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.work_rounded,
                                size: 12, color: AppColors.accentBlue),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(budget.projectName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatCurrency(budget.totalValue),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentGold),
                            textAlign: TextAlign.end),
                        const SizedBox(height: 4),
                        Text(_formatDate(budget.creationDate),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ]),

                // ── Itens ────────────────────────────────────────────────
                if (budget.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppColors.borderColor.withOpacity(0.5),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Icon(Icons.list_rounded,
                          size: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${budget.items.length} '
                      '${budget.items.length == 1 ? 'item' : 'itens'}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    if (budget.description.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.description_rounded,
                            size: 10, color: AppColors.textMuted),
                      ),
                  ]),
                ],

                // ── Validade ─────────────────────────────────────────────
                if (budget.expirationDate != null && !_isExpired()) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.schedule_rounded,
                          size: 10, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Válido até ${_formatDate(budget.expirationDate!)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted),
                      ),
                    ]),
                  ),
                ],

                // ── Botões Aprovar / Rejeitar ─────────────────────────────
                _buildApprovalActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BudgetTile — versão compacta (inalterada, sem aprovação inline)
// ─────────────────────────────────────────────────────────────────────────────
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

  String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}";

  bool _isExpired() =>
      budget.expirationDate != null &&
      DateTime.now().isAfter(budget.expirationDate!) &&
      budget.status == BudgetStatus.pending;

  BudgetStatus _getActualStatus() =>
      _isExpired() ? BudgetStatus.expired : budget.status;

  @override
  Widget build(BuildContext context) {
    final actualStatus = _getActualStatus();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: actualStatus.color.withOpacity(0.3), width: 1),
            ),
            child: Row(children: [
              Container(
                width: 3, height: 40,
                decoration: BoxDecoration(
                  color: actualStatus.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(budget.clientName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(_formatCurrency(budget.totalValue),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGold)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Expanded(
                        child: Text(budget.projectName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDate(budget.creationDate),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (budget.expirationDate != null)
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: (_isExpired()
                                  ? AppColors.accentRed
                                  : AppColors.textMuted)
                              .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _isExpired()
                          ? Icons.warning_rounded
                          : Icons.schedule_rounded,
                      size: 12,
                      color: _isExpired()
                          ? AppColors.accentRed
                          : AppColors.textMuted,
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.more_horiz_rounded,
                        color: AppColors.textMuted, size: 14),
                  ),
                  color: AppColors.secondaryDark,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_rounded,
                            size: 16, color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        const Text('Editar',
                            style:
                                TextStyle(color: AppColors.textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_rounded,
                            size: 16, color: AppColors.accentRed),
                        const SizedBox(width: 8),
                        const Text('Excluir',
                            style: TextStyle(color: AppColors.accentRed)),
                      ]),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}