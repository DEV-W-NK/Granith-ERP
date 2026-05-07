import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final VoidCallback? onTap;
  final PurchaseService? purchaseService;

  const PurchaseCard({
    super.key,
    required this.purchase,
    this.onTap,
    this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final p = purchase;
    final isDelivered = p.status == PurchaseStatus.delivered;
    final isCancelled = p.status == PurchaseStatus.cancelled;
    final isAwaiting = p.status == PurchaseStatus.awaitingApproval;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isAwaiting
                    ? Colors.purpleAccent.withOpacity(0.3)
                    : isDelivered
                    ? Colors.green.withOpacity(0.2)
                    : isCancelled
                    ? Colors.red.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final title = Text(
                  p.itemName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                );
                final status = _StatusBadge(status: p.status);

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 8), status],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 10),
                    status,
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _Meta(icon: Icons.store_outlined, label: p.supplierName),
                _Meta(icon: Icons.folder_outlined, label: p.projectName),
                _Meta(
                  icon: Icons.numbers_outlined,
                  label:
                      'Qtd: ${p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 1)}',
                ),
                _Meta(
                  icon: Icons.calendar_today_outlined,
                  label: dateFormat.format(p.purchaseDate),
                ),
                if (p.deliveryDate != null)
                  _Meta(
                    icon: Icons.local_shipping_outlined,
                    label: 'Entregue ${dateFormat.format(p.deliveryDate!)}',
                    color: Colors.greenAccent,
                  ),
              ],
            ),
            // Motivo de recusa
            if (isCancelled && p.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      size: 13,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Recusado: ${p.rejectionReason}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  currency.format(p.totalValue),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isAwaiting)
                  _CeoApprovalButton(
                    purchase: p,
                    purchaseService: purchaseService,
                  )
                else if (!isDelivered && !isCancelled)
                  _ActionButton(purchase: p, purchaseService: purchaseService),
                if (isDelivered && p.financialTransactionId != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Despesa lançada',
                        style: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CEO approval ─────────────────────────────────────────────────────────────

class _CeoApprovalButton extends StatefulWidget {
  final Purchase purchase;
  final PurchaseService? purchaseService;

  const _CeoApprovalButton({required this.purchase, this.purchaseService});

  @override
  State<_CeoApprovalButton> createState() => _CeoApprovalButtonState();
}

class _CeoApprovalButtonState extends State<_CeoApprovalButton> {
  bool _loading = false;

  PurchaseService get _service => widget.purchaseService ?? PurchaseService();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill(
          'Recusar',
          Colors.redAccent,
          onTap: () => _showRejectDialog(context),
        ),
        _pill(
          'Aprovar compra',
          Colors.purpleAccent,
          icon: Icons.verified_outlined,
          onTap: () => _approve(context),
        ),
      ],
    );
  }

  Widget _pill(
    String label,
    Color color, {
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child:
            _loading
                ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final auth = context.read<AuthController>();
    final confirm = await _confirmDialog(
      context: context,
      title: 'Aprovar compra?',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.purchase.itemName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow('Fornecedor', widget.purchase.supplierName),
          _InfoRow(
            'Quantidade',
            '${widget.purchase.quantity.toStringAsFixed(widget.purchase.quantity % 1 == 0 ? 0 : 1)} un',
          ),
          _InfoRow(
            'Valor total',
            NumberFormat.simpleCurrency(
              locale: 'pt_BR',
            ).format(widget.purchase.totalValue),
          ),
          _InfoRow('Projeto', widget.purchase.projectName),
        ],
      ),
      confirmLabel: 'Aprovar',
      confirmColor: Colors.purpleAccent,
    );

    if (!confirm || !mounted) return;

    setState(() => _loading = true);
    try {
      await _service.approvePurchase(
        purchaseId: widget.purchase.id,
        approvedBy: auth.user?.uid ?? 'unknown',
        approvedByName: auth.user?.displayName ?? auth.user?.email ?? 'CEO',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra aprovada'),
            backgroundColor: Colors.purpleAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final auth = context.read<AuthController>();
    final reasonCtrl = TextEditingController();

    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceDark,
                title: const Text(
                  'Recusar compra?',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.purchase.itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Motivo da recusa (obrigatório)',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (reasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Informe o motivo'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Recusar'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    setState(() => _loading = true);
    try {
      await _service.rejectPurchase(
        purchaseId: widget.purchase.id,
        rejectedBy: auth.user?.uid ?? 'unknown',
        rejectedByName: auth.user?.displayName ?? auth.user?.email ?? 'CEO',
        reason: reasonCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra recusada'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirmDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceDark,
                title: Text(title, style: const TextStyle(color: Colors.white)),
                content: content,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
        ) ??
        false;
  }
}

// ─── Action button (setor de compras) ────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final Purchase purchase;
  final PurchaseService? purchaseService;

  const _ActionButton({required this.purchase, this.purchaseService});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;

  PurchaseService get _service => widget.purchaseService ?? PurchaseService();

  @override
  Widget build(BuildContext context) {
    final isPending = widget.purchase.status == PurchaseStatus.pending;
    final isOrdered = widget.purchase.status == PurchaseStatus.ordered;

    if (isPending) {
      return _btn(
        'Confirmar pedido',
        Icons.send_outlined,
        Colors.blue,
        () => _updateStatus(PurchaseStatus.ordered),
      );
    }
    if (isOrdered) {
      return _btn(
        'Confirmar entrega',
        Icons.local_shipping_outlined,
        Colors.green,
        () => _confirmDelivery(context),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child:
            _loading
                ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _updateStatus(PurchaseStatus status) async {
    setState(() => _loading = true);
    try {
      await _service.updateStatus(widget.purchase.id, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final auth = context.read<AuthController>();
    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceDark,
                title: const Text(
                  'Confirmar entrega?',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.purchase.itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ao confirmar, uma despesa será lançada no financeiro e o estoque será atualizado.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 14,
                          color: AppColors.accentGold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          NumberFormat.simpleCurrency(
                            locale: 'pt_BR',
                          ).format(widget.purchase.totalValue),
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          ' → Financeiro',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirmar entrega'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    setState(() => _loading = true);
    try {
      await _service.confirmDelivery(
        purchase: widget.purchase,
        receivedBy: auth.user?.uid ?? 'unknown',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega confirmada — despesa lançada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final PurchaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Meta({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
