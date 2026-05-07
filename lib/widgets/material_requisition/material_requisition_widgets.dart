import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════

class MaterialRequisitionHeader extends StatelessWidget {
  const MaterialRequisitionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MaterialRequisitionController>();
    final isDesktop =
        MediaQuery.of(context).size.width > ResponsiveLayout.compact;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.playlist_add_check_rounded,
            color: AppColors.accentGold,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Requisições de Materiais',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Pedidos do canteiro de obras',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        // Badge de pendentes
        if (ctrl.pendingCount > 0 && isDesktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 14,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  '${ctrl.pendingCount} pendente${ctrl.pendingCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class MaterialRequisitionEmptyState extends StatelessWidget {
  const MaterialRequisitionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma requisição encontrada',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARD DA REQUISIÇÃO
// ═══════════════════════════════════════════════════════════════════════════

class MaterialRequisitionCard extends StatelessWidget {
  final MaterialRequisitionModel requisition;

  const MaterialRequisitionCard({super.key, required this.requisition});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final r = requisition;
    final statusColor = r.status.color;

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              r.priority == 'Alta' && r.status == RequisitionStatus.pending
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.12),
            child: Icon(r.status.icon, color: statusColor, size: 20),
          ),
          title: Text(
            r.projectName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Solicitante: ${r.requesterName}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              Text(
                dateFormat.format(r.requestDate),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  r.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (r.priority == 'Alta')
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 12,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Alta prioridade',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),

          // ── Conteúdo expandido ──
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Itens
                  const Text(
                    'Itens solicitados:',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...r.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (item.observation != null) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: item.observation!,
                              child: const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Quem aprovou / rejeitou
                  if (r.approvedByName != null) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(r.status.icon, size: 13, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          '${r.status == RequisitionStatus.rejected ? "Rejeitado" : "Aprovado"} por ${r.approvedByName}',
                          style: TextStyle(color: statusColor, fontSize: 11),
                        ),
                      ],
                    ),
                    if (r.rejectionReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Motivo: ${r.rejectionReason}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],

                  // ── Ações por status ──
                  const SizedBox(height: 20),
                  _buildActions(context, r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, MaterialRequisitionModel r) {
    final ctrl = context.read<MaterialRequisitionController>();
    final auth = context.read<AuthController>();

    // Etapa 1 → 2: Aprovar ou Rejeitar
    if (r.status == RequisitionStatus.pending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showRejectDialog(context, r, ctrl, auth),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Rejeitar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showApproveDialog(context, r, ctrl, auth),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aprovar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    // Etapa 2 → 3: Converter em compra
    if (r.status == RequisitionStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showConvertDialog(context, r, ctrl, auth),
          icon: const Icon(Icons.shopping_cart_outlined, size: 16),
          label: const Text('Gerar pedido de compra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
          ),
        ),
      );
    }

    // Compra já gerada
    if (r.status == RequisitionStatus.purchased) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blueAccent, size: 14),
          const SizedBox(width: 6),
          const Text(
            'Compra gerada — veja em Compras & Pedidos',
            style: TextStyle(color: Colors.blueAccent, fontSize: 12),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Dialog: Confirmar aprovação ─────────────────────────────────────────

  Future<void> _showApproveDialog(
    BuildContext context,
    MaterialRequisitionModel r,
    MaterialRequisitionController ctrl,
    AuthController auth,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Aprovar requisição?',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.projectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${r.itemCount} item(ns) • solicitado por ${r.requesterName}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ao aprovar, o responsável poderá gerar o pedido de compra.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                child: const Text('Confirmar aprovação'),
              ),
            ],
          ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ctrl.approve(
        requisition: r,
        approvedBy: auth.user?.uid ?? 'unknown',
        approvedByName: auth.user?.displayName ?? 'Gestor',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requisição aprovada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Dialog: Motivo da rejeição ───────────────────────────────────────────

  Future<void> _showRejectDialog(
    BuildContext context,
    MaterialRequisitionModel r,
    MaterialRequisitionController ctrl,
    AuthController auth,
  ) async {
    final reasonCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Rejeitar requisição?',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.projectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Motivo da rejeição (obrigatório)',
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
                child: const Text('Confirmar rejeição'),
              ),
            ],
          ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ctrl.reject(
        requisition: r,
        rejectedBy: auth.user?.uid ?? 'unknown',
        rejectedByName: auth.user?.displayName ?? 'Gestor',
        reason: reasonCtrl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requisição rejeitada'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }

    reasonCtrl.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOG: Converter em compra (Etapa 3)
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _showConvertDialog(
  BuildContext context,
  MaterialRequisitionModel r,
  MaterialRequisitionController ctrl,
  AuthController auth,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => _ConvertToPurchaseDialog(
          requisition: r,
          controller: ctrl,
          auth: auth,
        ),
  );
}

class _ConvertToPurchaseDialog extends StatefulWidget {
  final MaterialRequisitionModel requisition;
  final MaterialRequisitionController controller;
  final AuthController auth;

  const _ConvertToPurchaseDialog({
    required this.requisition,
    required this.controller,
    required this.auth,
  });

  @override
  State<_ConvertToPurchaseDialog> createState() =>
      _ConvertToPurchaseDialogState();
}

class _ConvertToPurchaseDialogState extends State<_ConvertToPurchaseDialog> {
  final _supplierService = SupplierService();

  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _loadingSuppliers = true;
  bool _saving = false;

  // Controladores de preço por item
  final Map<String, TextEditingController> _priceCtrl = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.requisition.items) {
      _priceCtrl[item.itemName] = TextEditingController();
    }
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final list = await _supplierService.getSuppliers();
      if (mounted)
        setState(() {
          _suppliers = list;
          _loadingSuppliers = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  @override
  void dispose() {
    for (final c in _priceCtrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.requisition;
    final size = MediaQuery.sizeOf(context);
    final inset = size.width < 420 ? 8.0 : 24.0;
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 560.0);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: EdgeInsets.all(inset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth.toDouble(),
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gerar pedido de compra',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          r.projectName,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fornecedor
                    _sectionLabel('Fornecedor'),
                    _loadingSuppliers
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                            strokeWidth: 2,
                          ),
                        )
                        : DropdownButtonFormField<Supplier>(
                          value: _selectedSupplier,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: _dec(
                            'Selecione o fornecedor',
                            Icons.storefront_outlined,
                          ),
                          items:
                              _suppliers
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedSupplier = v),
                        ),
                    const SizedBox(height: 20),

                    // Preços por item
                    _sectionLabel('Valor por item (R\$)'),
                    const Text(
                      'Informe o valor total de cada item para esta compra.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...r.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _priceCtrl[item.itemName],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d*'),
                                  ),
                                ],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: _dec(
                                  'R\$ 0,00',
                                  Icons.attach_money,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão salvar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _saving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryDark,
                                  ),
                                )
                                : const Text(
                                  'Criar pedido de compra',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um fornecedor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Monta mapa de preços
    final prices = <String, double>{};
    for (final item in widget.requisition.items) {
      final raw = _priceCtrl[item.itemName]?.text ?? '';
      prices[item.itemName] = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
    }

    setState(() => _saving = true);
    try {
      await widget.controller.convertToPurchase(
        requisition: widget.requisition,
        supplier: _selectedSupplier!,
        createdBy: widget.auth.user?.uid ?? 'unknown',
        itemPrices: prices,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pedido de compra criado — veja em Compras & Pedidos',
            ),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: AppColors.accentGold, size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.accentGold),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
