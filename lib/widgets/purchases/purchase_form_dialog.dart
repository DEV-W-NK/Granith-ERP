import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/models/project_model.dart'; // Import Project Model
import 'package:project_granith/services/item_service.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/services/service_projetos.dart'; // Import Project Service
import 'package:project_granith/themes/app_theme.dart';

class PurchaseFormDialog extends StatefulWidget {
  final Purchase? purchase;

  const PurchaseFormDialog({super.key, this.purchase});

  @override
  State<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<PurchaseFormDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Services
  final ItemService _itemService = ItemService();
  final SupplierService _supplierService = SupplierService();
  final ServiceProjetos _projectService = ServiceProjetos(); // Service Projetos

  // Data Loading
  bool _isLoading = true;
  List<Item> _items = [];
  List<Supplier> _suppliers = [];
  List<Project> _projects = [];

  // Form Fields
  Item? _selectedItem;
  Supplier? _selectedSupplier;
  Project? _selectedProject; // Selected Project
  
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  PurchaseStatus _status = PurchaseStatus.pending;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Init form if editing
    if (widget.purchase != null) {
      _addressController.text = widget.purchase!.deliveryAddress;
      _valueController.text = widget.purchase!.totalValue.toStringAsFixed(2);
      _status = widget.purchase!.status;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  Future<void> _loadData() async {
    try {
      // Carregar Itens, Fornecedores e Projetos em paralelo
      final results = await Future.wait([
        _itemService.searchItems(''),
        _supplierService.getSuppliers(),
        _projectService.getProjects(),
      ]);

      if (mounted) {
        setState(() {
          _items = results[0] as List<Item>;
          _suppliers = results[1] as List<Supplier>;
          _projects = results[2] as List<Project>;
          
          // Set initial selection if editing
          if (widget.purchase != null) {
            try {
              _selectedItem = _items.firstWhere((i) => i.id == widget.purchase!.itemId);
            } catch (_) {} 
            
            try {
              _selectedSupplier = _suppliers.firstWhere((s) => s.id == widget.purchase!.supplierId);
            } catch (_) {} 

            try {
              _selectedProject = _projects.firstWhere((p) => p.id == widget.purchase!.projectId);
            } catch (_) {} 
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.purchase != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: AppColors.primaryDark.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: _isLoading 
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)))
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // === Header ===
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentGold, Color(0xFFB8941F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_cart_rounded, color: AppColors.primaryDark, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              isEditing ? 'Editar Compra' : 'Registrar Compra',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // === Seleção de Projeto (NOVO) ===
                            _buildSectionLabel('Para qual Projeto?'),
                            DropdownButtonFormField<Project>(
                              initialValue: _selectedProject,
                              dropdownColor: AppColors.secondaryDark,
                              decoration: _inputDecoration('Selecione o Projeto', Icons.business_rounded),
                              style: const TextStyle(color: AppColors.textPrimary),
                              items: _projects.map((project) {
                                return DropdownMenuItem(
                                  value: project,
                                  child: Text(
                                    project.name, 
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedProject = val),
                              validator: (val) => val == null ? 'Selecione um projeto' : null,
                            ),
                            const SizedBox(height: 20),

                            // === Seleção de Item ===
                            _buildSectionLabel('O que será comprado?'),
                            DropdownButtonFormField<Item>(
                              initialValue: _selectedItem,
                              dropdownColor: AppColors.secondaryDark,
                              decoration: _inputDecoration('Selecione o Item', Icons.inventory_2_outlined),
                              style: const TextStyle(color: AppColors.textPrimary),
                              items: _items.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedItem = val),
                              validator: (val) => val == null ? 'Selecione um item' : null,
                            ),
                            const SizedBox(height: 20),

                            // === Seleção de Fornecedor ===
                            _buildSectionLabel('Quem irá fornecer?'),
                            DropdownButtonFormField<Supplier>(
                              initialValue: _selectedSupplier,
                              dropdownColor: AppColors.secondaryDark,
                              decoration: _inputDecoration('Selecione o Fornecedor', Icons.storefront_outlined),
                              style: const TextStyle(color: AppColors.textPrimary),
                              items: _suppliers.map((supplier) {
                                return DropdownMenuItem(
                                  value: supplier,
                                  child: Text(supplier.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedSupplier = val),
                              validator: (val) => val == null ? 'Selecione um fornecedor' : null,
                            ),
                            const SizedBox(height: 20),

                            // === Endereço ===
                            _buildSectionLabel('Onde entregar?'),
                            TextFormField(
                              controller: _addressController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDecoration('Endereço de Entrega', Icons.location_on_outlined),
                              validator: (val) => val?.isEmpty == true ? 'Informe o endereço' : null,
                            ),
                            const SizedBox(height: 20),

                            // === Valor e Status ===
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionLabel('Custo Total'),
                                      TextFormField(
                                        controller: _valueController,
                                        style: const TextStyle(color: AppColors.textPrimary),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                                        ],
                                        decoration: _inputDecoration('Valor (R\$)', Icons.attach_money).copyWith(
                                          prefixText: 'R\$ ',
                                          prefixStyle: const TextStyle(color: AppColors.accentGold),
                                        ),
                                        validator: (val) => val?.isEmpty == true ? 'Obrigatório' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionLabel('Status'),
                                      DropdownButtonFormField<PurchaseStatus>(
                                        initialValue: _status,
                                        dropdownColor: AppColors.secondaryDark,
                                        decoration: _inputDecoration('', Icons.flag_outlined),
                                        style: const TextStyle(color: AppColors.textPrimary),
                                        items: PurchaseStatus.values.map((s) {
                                          return DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              s.label, 
                                              style: TextStyle(color: s.color, fontSize: 13, fontWeight: FontWeight.bold)
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(() => _status = val!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // === Botões ===
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGold,
                                      foregroundColor: AppColors.primaryDark,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Salvar Compra', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Validação adicional para Projeto
      if (_selectedItem == null || _selectedSupplier == null || _selectedProject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione Projeto, Item e Fornecedor'),
            backgroundColor: AppColors.accentRed,
          ),
        );
        return;
      }

      final purchase = Purchase(
        id: widget.purchase?.id ?? '', // Vazio cria novo
        itemId: _selectedItem!.id,
        itemName: _selectedItem!.name,
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        projectId: _selectedProject!.id, // ID do Projeto
        projectName: _selectedProject!.name, // Nome do Projeto
        deliveryAddress: _addressController.text.trim(),
        totalValue: double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0,
        status: _status,
        purchaseDate: widget.purchase?.purchaseDate ?? DateTime.now(),
      );

      Navigator.pop(context, purchase);
    }
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: AppColors.accentGold, size: 20),
      filled: true,
      fillColor: AppColors.secondaryDark,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentGold)),
    );
  }
}