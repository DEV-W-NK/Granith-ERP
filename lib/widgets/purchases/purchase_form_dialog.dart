import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/item_service.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class PurchaseFormDialog extends StatefulWidget {
  final Purchase? purchase;

  const PurchaseFormDialog({super.key, this.purchase});

  @override
  State<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<PurchaseFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final ItemService _itemService = ItemService();
  final SupplierService _supplierService = SupplierService();
  final ServiceProjetos _projectService = ServiceProjetos();

  bool _isLoading = true;
  List<Item> _items = [];
  List<Supplier> _suppliers = [];
  List<Project> _projects = [];

  Item? _selectedItem;
  Supplier? _selectedSupplier;
  Project? _selectedProject;

  final _addressCtrl = TextEditingController();
  final _pickupAddressCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  PurchaseFulfillmentType _fulfillmentType = PurchaseFulfillmentType.delivery;

  // Status disponíveis para seleção manual —
  // delivered e cancelled são controlados por ações dedicadas,
  // não pelo form.
  static const _editableStatuses = [
    PurchaseStatus.pending,
    PurchaseStatus.ordered,
  ];
  PurchaseStatus _status = PurchaseStatus.pending;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.purchase != null) {
      final p = widget.purchase!;
      _addressCtrl.text = p.deliveryAddress;
      _pickupAddressCtrl.text = p.pickupAddress;
      _fulfillmentType = p.fulfillmentType;
      _valueCtrl.text = p.totalValue.toStringAsFixed(2);
      _quantityCtrl.text = p.quantity.toStringAsFixed(
        p.quantity % 1 == 0 ? 0 : 2,
      );
      // Se status não é editável (delivered/cancelled), mostra pending
      _status =
          _editableStatuses.contains(p.status)
              ? p.status
              : PurchaseStatus.pending;
    }

    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _itemService.searchItems(''),
        _supplierService.getSuppliers(),
        _projectService.getProjects(),
      ]);

      if (!mounted) return;
      setState(() {
        _items = results[0] as List<Item>;
        _suppliers = results[1] as List<Supplier>;
        _projects = results[2] as List<Project>;

        if (widget.purchase != null) {
          final p = widget.purchase!;
          try {
            _selectedItem = _items.firstWhere((i) => i.id == p.itemId);
          } catch (_) {}
          try {
            _selectedSupplier = _suppliers.firstWhere(
              (s) => s.id == p.supplierId,
            );
          } catch (_) {}
          try {
            _selectedProject = _projects.firstWhere(
              (pr) => pr.id == p.projectId,
            );
          } catch (_) {}
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _addressCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _valueCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.purchase != null;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < ResponsiveLayout.compact;
    final inset = size.width < 420 ? 8.0 : 16.0;
    final padding = ResponsiveLayout.pagePadding(size.width);
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 600.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(inset),
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            width: dialogWidth.toDouble(),
            constraints: BoxConstraints(maxHeight: size.height * 0.92),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.66),
              ),
              boxShadow: AppColors.glowShadows(AppColors.accentGold),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(isEditing),
                            Padding(
                              padding: padding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Projeto
                                  _label('Para qual projeto?'),
                                  _projectDropdown(),
                                  const SizedBox(height: 20),

                                  // Item
                                  _label('O que será comprado?'),
                                  _itemDropdown(),
                                  const SizedBox(height: 20),

                                  // Fornecedor
                                  _label('Quem irá fornecer?'),
                                  _supplierDropdown(),
                                  const SizedBox(height: 20),

                                  _label('Como esta compra sera atendida?'),
                                  _fulfillmentSelector(),
                                  const SizedBox(height: 20),

                                  // Quantidade + Valor
                                  _buildQuantityValueFields(isCompact),
                                  const SizedBox(height: 20),

                                  // Endereco
                                  _label(
                                    _fulfillmentType ==
                                            PurchaseFulfillmentType.pickup
                                        ? 'Coleta e destino da compra'
                                        : 'Endereco de entrega',
                                  ),
                                  if (_fulfillmentType ==
                                      PurchaseFulfillmentType.pickup) ...[
                                    _label('Onde o motorista deve coletar?'),
                                    _pickupAddressField(),
                                    const SizedBox(height: 20),
                                  ],
                                  _addressField(),
                                  const SizedBox(height: 20),

                                  // Status
                                  _label('Status inicial'),
                                  _statusDropdown(),
                                  const SizedBox(height: 32),

                                  _buildActions(isCompact),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isEditing) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 420;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentGold, Color(0xFFB8941F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isEditing ? 'Editar compra' : 'Registrar compra',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityValueFields(bool isCompact) {
    final quantity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_label('Quantidade'), _quantityField()],
    );
    final value = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_label('Valor total (R\$)'), _valueField()],
    );

    if (isCompact) {
      return Column(children: [quantity, const SizedBox(height: 16), value]);
    }

    return Row(
      children: [
        Expanded(child: quantity),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: value),
      ],
    );
  }

  // ─── Campos ───────────────────────────────────────────────────────────────

  Widget _projectDropdown() {
    return DropdownButtonFormField<Project>(
      initialValue: _selectedProject,
      dropdownColor: AppColors.secondaryDark,
      decoration: _dec('Selecione o projeto', Icons.business_rounded),
      style: const TextStyle(color: AppColors.textPrimary),
      items:
          _projects
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _selectedProject = v),
      validator: (v) => v == null ? 'Selecione um projeto' : null,
    );
  }

  Widget _itemDropdown() {
    return DropdownButtonFormField<Item>(
      initialValue: _selectedItem,
      dropdownColor: AppColors.secondaryDark,
      decoration: _dec('Selecione o item', Icons.inventory_2_outlined),
      style: const TextStyle(color: AppColors.textPrimary),
      items:
          _items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(i.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _selectedItem = v),
      validator: (v) => v == null ? 'Selecione um item' : null,
    );
  }

  Widget _supplierDropdown() {
    return DropdownButtonFormField<Supplier>(
      initialValue: _selectedSupplier,
      dropdownColor: AppColors.secondaryDark,
      decoration: _dec('Selecione o fornecedor', Icons.storefront_outlined),
      style: const TextStyle(color: AppColors.textPrimary),
      items:
          _suppliers
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _selectedSupplier = v),
      validator: (v) => v == null ? 'Selecione um fornecedor' : null,
    );
  }

  Widget _fulfillmentSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          PurchaseFulfillmentType.values.map((type) {
            final selected = _fulfillmentType == type;
            return ChoiceChip(
              selected: selected,
              avatar: Icon(
                type.icon,
                size: 17,
                color:
                    selected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
              label: Text(type.label),
              labelStyle: TextStyle(
                color:
                    selected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppColors.accentGold,
              backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.82),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color:
                      selected
                          ? AppColors.accentGold
                          : AppColors.borderColor.withValues(alpha: 0.72),
                ),
              ),
              onSelected: (_) => setState(() => _fulfillmentType = type),
            );
          }).toList(),
    );
  }

  Widget _quantityField() {
    return TextFormField(
      controller: _quantityCtrl,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
      ],
      decoration: _dec('Ex: 10', Icons.numbers_outlined),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Obrigatório';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'Inválido';
        return null;
      },
    );
  }

  Widget _valueField() {
    return TextFormField(
      controller: _valueCtrl,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
      ],
      decoration: _dec('0,00', Icons.attach_money).copyWith(
        prefixText: 'R\$ ',
        prefixStyle: const TextStyle(color: AppColors.accentGold),
      ),
      validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
    );
  }

  Widget _addressField() {
    return TextFormField(
      controller: _addressCtrl,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _dec(
        _fulfillmentType == PurchaseFulfillmentType.pickup
            ? 'Destino final da compra'
            : 'Endereco de entrega',
        Icons.location_on_outlined,
      ),
      validator: (v) => v?.isEmpty == true ? 'Informe o endereco' : null,
    );
  }

  Widget _pickupAddressField() {
    return TextFormField(
      controller: _pickupAddressCtrl,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _dec(
        'Fornecedor, loja, CD ou endereco da coleta',
        Icons.store_mall_directory_outlined,
      ),
      validator: (v) {
        if (_fulfillmentType == PurchaseFulfillmentType.pickup &&
            (v == null || v.trim().isEmpty)) {
          return 'Informe onde sera feita a coleta';
        }
        return null;
      },
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<PurchaseStatus>(
      initialValue: _status,
      dropdownColor: AppColors.secondaryDark,
      decoration: _dec('', Icons.flag_outlined),
      style: const TextStyle(color: AppColors.textPrimary),
      // Só mostra pending e ordered — delivered/cancelled são por ação
      items:
          _editableStatuses
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.label,
                    style: TextStyle(
                      color: s.color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _status = v!),
    );
  }

  // ─── Botões ───────────────────────────────────────────────────────────────

  Widget _buildActions(bool isCompact) {
    final cancel = TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Cancelar',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
    final save = ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Salvar compra',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [save, const SizedBox(height: 8), cancel],
      );
    }

    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: save),
      ],
    );
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null ||
        _selectedSupplier == null ||
        _selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione projeto, item e fornecedor'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final qty = double.tryParse(_quantityCtrl.text) ?? 1.0;
    final value = double.tryParse(_valueCtrl.text.replaceAll(',', '.')) ?? 0.0;

    final purchase = Purchase(
      id: widget.purchase?.id ?? '',
      itemId: _selectedItem!.id,
      itemName: _selectedItem!.name,
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      projectId: _selectedProject!.id,
      projectName: _selectedProject!.name,
      deliveryAddress: _addressCtrl.text.trim(),
      fulfillmentType: _fulfillmentType,
      pickupAddress:
          _fulfillmentType == PurchaseFulfillmentType.pickup
              ? _pickupAddressCtrl.text.trim()
              : '',
      routeId: widget.purchase?.routeId,
      totalValue: value,
      quantity: qty,
      status: _status,
      purchaseDate: widget.purchase?.purchaseDate ?? DateTime.now(),
      deliveryDate: widget.purchase?.deliveryDate,
      expectedDeliveryDate: widget.purchase?.expectedDeliveryDate,
      requisitionId: widget.purchase?.requisitionId,
      financialTransactionId: widget.purchase?.financialTransactionId,
      receivedBy: widget.purchase?.receivedBy,
      invoiceNumber: widget.purchase?.invoiceNumber,
      invoiceAccessKey: widget.purchase?.invoiceAccessKey,
      notes: widget.purchase?.notes,
      approvalSector: widget.purchase?.approvalSector,
      quotedBy: widget.purchase?.quotedBy,
      quotedByName: widget.purchase?.quotedByName,
      quotedAt: widget.purchase?.quotedAt,
      approvedBy: widget.purchase?.approvedBy,
      approvedByName: widget.purchase?.approvedByName,
      approvedAt: widget.purchase?.approvedAt,
      rejectionReason: widget.purchase?.rejectionReason,
      consolidatedBy: widget.purchase?.consolidatedBy,
      consolidatedByName: widget.purchase?.consolidatedByName,
      consolidatedAt: widget.purchase?.consolidatedAt,
    );

    Navigator.pop(context, purchase);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
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
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.68)),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceDark.withValues(alpha: 0.76),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderColor.withValues(alpha: 0.72),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderColor.withValues(alpha: 0.72),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.4),
      ),
    );
  }
}
