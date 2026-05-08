import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
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
    final hasFinancialLink = p.financialTransactionId != null;
    final canApprove = _canApproveSectorBudget(context, p);

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
                    ? Colors.purpleAccent.withValues(alpha: 0.3)
                    : isDelivered
                    ? Colors.green.withValues(alpha: 0.2)
                    : isCancelled
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
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
                  icon: Icons.domain_outlined,
                  label: 'Setor: ${_sectorLabel(p)}',
                ),
                _Meta(
                  icon: Icons.numbers_outlined,
                  label:
                      'Qtd: ${p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 1)}',
                ),
                _Meta(
                  icon: Icons.calendar_today_outlined,
                  label: dateFormat.format(p.purchaseDate),
                ),
                if (p.expectedDeliveryDate != null)
                  _Meta(
                    icon: Icons.event_available_outlined,
                    label:
                        'Prev. ${dateFormat.format(p.expectedDeliveryDate!)}',
                    color: Colors.lightBlueAccent,
                  ),
                if (p.invoiceNumber?.trim().isNotEmpty == true)
                  _Meta(
                    icon: Icons.receipt_long_outlined,
                    label: 'NF ${p.invoiceNumber}',
                    color: AppColors.accentGold,
                  ),
                if (p.deliveryDate != null)
                  _Meta(
                    icon: Icons.local_shipping_outlined,
                    label: 'Entregue ${dateFormat.format(p.deliveryDate!)}',
                    color: Colors.greenAccent,
                  ),
              ],
            ),
            if (p.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _MessageBox(
                icon: Icons.sticky_note_2_outlined,
                text: p.notes!.trim(),
                color: AppColors.textMuted,
              ),
            ],
            if (isAwaiting && !canApprove) ...[
              const SizedBox(height: 10),
              _MessageBox(
                icon: Icons.lock_clock_outlined,
                text: 'Aguardando coordenacao de ${_sectorLabel(p)}',
                color: Colors.purpleAccent,
              ),
            ],
            if (isCancelled && p.rejectionReason != null) ...[
              const SizedBox(height: 8),
              _MessageBox(
                icon: Icons.cancel_outlined,
                text: 'Recusado: ${p.rejectionReason}',
                color: Colors.redAccent,
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
                if (isAwaiting && canApprove)
                  _SectorApprovalButton(
                    purchase: p,
                    purchaseService: purchaseService,
                  )
                else if (!isAwaiting && !isDelivered && !isCancelled)
                  _PurchaseActionButton(
                    purchase: p,
                    purchaseService: purchaseService,
                  ),
                if (hasFinancialLink && !isCancelled)
                  _FinancialLinkBadge(isDelivered: isDelivered),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

AuthViewModel? _maybeReadAuth(BuildContext context) {
  try {
    return context.read<AuthViewModel>();
  } on ProviderNotFoundException {
    return null;
  }
}

TeamController? _maybeReadTeam(BuildContext context) {
  try {
    return context.read<TeamController>();
  } on ProviderNotFoundException {
    return null;
  }
}

String _sectorLabel(Purchase purchase) {
  final sector = purchase.approvalSector?.trim();
  return sector == null || sector.isEmpty ? 'Geral' : sector;
}

bool _canApproveSectorBudget(BuildContext context, Purchase purchase) {
  final auth = _maybeReadAuth(context);
  final user = auth?.user;
  final sector = _sectorLabel(purchase);
  final permissions = user?.permissions ?? const <String>[];

  if (PermissionCodes.canApprovePurchases(
    isAdmin: (auth?.isAdminUser ?? false) || (user?.isAdmin ?? false),
    permissions: permissions,
    sector: sector,
  )) {
    return true;
  }

  final userEmail = user?.email.toLowerCase().trim();
  if (userEmail == null || userEmail.isEmpty) return false;

  final team = _maybeReadTeam(context);
  if (team == null) return false;

  final normalizedSector = PermissionCodes.normalizePermissionSegment(sector);
  for (final employee in team.employees) {
    if (employee.email.toLowerCase().trim() != userEmail) continue;
    final employeeSector = PermissionCodes.normalizePermissionSegment(
      employee.sector,
    );
    return employeeSector == normalizedSector &&
        employee.role.level >= EmployeeRole.coordenador.level;
  }

  return false;
}

bool _canConsolidatePurchase(BuildContext context) {
  final auth = _maybeReadAuth(context);
  final user = auth?.user;
  if (user == null) return true;
  return PermissionCodes.canConsolidatePurchases(
    isAdmin: (auth?.isAdminUser ?? false) || user.isAdmin,
    permissions: user.permissions,
  );
}

class _SectorApprovalButton extends StatefulWidget {
  final Purchase purchase;
  final PurchaseService? purchaseService;

  const _SectorApprovalButton({required this.purchase, this.purchaseService});

  @override
  State<_SectorApprovalButton> createState() => _SectorApprovalButtonState();
}

class _SectorApprovalButtonState extends State<_SectorApprovalButton> {
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
          'Aprovar orcamento',
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
    final auth = _maybeReadAuth(context);
    final confirm = await _confirmDialog(
      context: context,
      title: 'Aprovar orcamento?',
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
          _InfoRow('Setor', _sectorLabel(widget.purchase)),
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
        approvedBy: auth?.user?.uid ?? 'unknown',
        approvedByName:
            auth?.user?.displayName ?? auth?.user?.email ?? 'Coordenacao',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orcamento aprovado para consolidacao de compra'),
          backgroundColor: Colors.purpleAccent,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final auth = _maybeReadAuth(context);
    final reasonCtrl = TextEditingController();

    final confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceDark,
                title: const Text(
                  'Recusar orcamento?',
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
                        labelText: 'Motivo da recusa (obrigatorio)',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
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
        rejectedBy: auth?.user?.uid ?? 'unknown',
        rejectedByName:
            auth?.user?.displayName ?? auth?.user?.email ?? 'Coordenacao',
        reason: reasonCtrl.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orcamento recusado'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
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

class _PurchaseActionButton extends StatefulWidget {
  final Purchase purchase;
  final PurchaseService? purchaseService;

  const _PurchaseActionButton({required this.purchase, this.purchaseService});

  @override
  State<_PurchaseActionButton> createState() => _PurchaseActionButtonState();
}

class _PurchaseActionButtonState extends State<_PurchaseActionButton> {
  bool _loading = false;

  PurchaseService get _service => widget.purchaseService ?? PurchaseService();

  @override
  Widget build(BuildContext context) {
    final isPending = widget.purchase.status == PurchaseStatus.pending;
    final isOrdered = widget.purchase.status == PurchaseStatus.ordered;

    if (isPending) {
      if (!_canConsolidatePurchase(context)) {
        return const _MessageBox(
          icon: Icons.lock_outline,
          text: 'Aguardando setor de compras',
          color: AppColors.textMuted,
        );
      }
      return _btn(
        'Consolidar compra',
        Icons.receipt_long_outlined,
        Colors.blue,
        () => _showConsolidationDialog(context),
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Future<void> _showConsolidationDialog(BuildContext context) async {
    final result = await showDialog<_ConsolidationResult>(
      context: context,
      builder: (ctx) => _ConsolidationDialog(purchase: widget.purchase),
    );
    if (result == null || !mounted || !context.mounted) return;

    final auth = _maybeReadAuth(context);
    setState(() => _loading = true);
    try {
      await _service.consolidatePurchase(
        purchase: widget.purchase,
        consolidatedBy: auth?.user?.uid ?? 'unknown',
        consolidatedByName:
            auth?.user?.displayName ?? auth?.user?.email ?? 'Compras',
        invoiceNumber: result.invoiceNumber,
        invoiceAccessKey: result.invoiceAccessKey,
        expectedDeliveryDate: result.expectedDeliveryDate,
        notes: result.notes,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra consolidada e enviada ao financeiro'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final auth = _maybeReadAuth(context);
    final hasFinancialLink = widget.purchase.financialTransactionId != null;
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
                    Text(
                      hasFinancialLink
                          ? 'Ao confirmar, o estoque sera atualizado.'
                          : 'Ao confirmar, o estoque sera atualizado e uma conta a pagar sera criada.',
                      style: const TextStyle(
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
                        Text(
                          hasFinancialLink
                              ? ' em Financeiro'
                              : ' para Financeiro',
                          style: const TextStyle(
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
        receivedBy: auth?.user?.uid ?? 'unknown',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega confirmada - estoque atualizado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ConsolidationResult {
  final String invoiceNumber;
  final String invoiceAccessKey;
  final DateTime? expectedDeliveryDate;
  final String notes;

  const _ConsolidationResult({
    required this.invoiceNumber,
    required this.invoiceAccessKey,
    required this.expectedDeliveryDate,
    required this.notes,
  });
}

class _ConsolidationDialog extends StatefulWidget {
  final Purchase purchase;

  const _ConsolidationDialog({required this.purchase});

  @override
  State<_ConsolidationDialog> createState() => _ConsolidationDialogState();
}

class _ConsolidationDialogState extends State<_ConsolidationDialog> {
  final _invoiceCtrl = TextEditingController();
  final _invoiceKeyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _expectedDeliveryDate;

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _invoiceKeyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Consolidar compra',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
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
              _InfoRow('Fornecedor', widget.purchase.supplierName),
              _InfoRow('Valor', currency.format(widget.purchase.totalValue)),
              _InfoRow('Projeto', widget.purchase.projectName),
              const SizedBox(height: 14),
              TextField(
                controller: _invoiceCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Numero da nota fiscal',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _invoiceKeyCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Chave de acesso da NF',
                  icon: Icons.key_outlined,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickExpectedDeliveryDate,
                icon: const Icon(Icons.event_available_outlined, size: 16),
                label: Text(
                  _expectedDeliveryDate == null
                      ? 'Previsao de entrega'
                      : dateFormat.format(_expectedDeliveryDate!),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentGold,
                  side: BorderSide(
                    color: AppColors.accentGold.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Observacoes da compra',
                  icon: Icons.sticky_note_2_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_outlined, size: 16),
          label: const Text('Enviar ao financeiro'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.accentGold, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.accentGold),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> _pickExpectedDeliveryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() => _expectedDeliveryDate = selected);
    }
  }

  void _submit() {
    final invoiceNumber = _invoiceCtrl.text.trim();
    if (invoiceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o numero da nota fiscal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _ConsolidationResult(
        invoiceNumber: invoiceNumber,
        invoiceAccessKey: _invoiceKeyCtrl.text.trim(),
        expectedDeliveryDate: _expectedDeliveryDate,
        notes: _notesCtrl.text.trim(),
      ),
    );
  }
}

class _FinancialLinkBadge extends StatelessWidget {
  final bool isDelivered;

  const _FinancialLinkBadge({required this.isDelivered});

  @override
  Widget build(BuildContext context) {
    final color = isDelivered ? Colors.greenAccent : AppColors.accentGold;
    final label = isDelivered ? 'Financeiro vinculado' : 'Conta a pagar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDelivered
                ? Icons.check_circle_outline
                : Icons.receipt_long_outlined,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PurchaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
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

class _MessageBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MessageBox({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(text, style: TextStyle(color: color, fontSize: 11)),
          ),
        ],
      ),
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
            width: 95,
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
