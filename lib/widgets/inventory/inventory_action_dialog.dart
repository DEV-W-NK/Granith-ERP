import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class InventoryActionDialog extends StatefulWidget {
  final InventoryItem item;
  final InventoryMovementType type;
  final InventoryService? service;

  const InventoryActionDialog({
    super.key,
    required this.item,
    required this.type,
    this.service,
  });

  @override
  State<InventoryActionDialog> createState() => _InventoryActionDialogState();
}

class _InventoryActionDialogState extends State<InventoryActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qtdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late final InventoryService _inventoryService;
  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _inventoryService = widget.service ?? InventoryService();
    if (_needsProjectPicker) {
      _loadProjects();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _qtdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final response = await AppSupabase.client
          .from('projects')
          .select()
          .order('name');

      final projects =
          (response as List).map((row) {
            final data = Map<String, dynamic>.from(row as Map);
            return Project.fromMap(data['id'] as String? ?? '', data);
          }).toList();

      if (!mounted) return;
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.type == InventoryMovementType.transfer;
    final isAdjustment = widget.type == InventoryMovementType.adjustment;
    final color = _dialogColor;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        _dialogTitle,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      content:
          _isLoading
              ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item: ${widget.item.name}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disponivel: ${widget.item.quantity.toStringAsFixed(2)} ${widget.item.unit}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (isAdjustment) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Informe o novo saldo total do material.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_needsProjectPicker) ...[
                        DropdownButtonFormField<Project>(
                          dropdownColor: AppColors.secondaryDark,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText:
                                isTransfer
                                    ? 'Para qual obra? (destino)'
                                    : 'Utilizado em qual obra?',
                            labelStyle: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items:
                              _projects
                                  .map(
                                    (project) => DropdownMenuItem(
                                      value: project,
                                      child: Text(project.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (project) =>
                                  setState(() => _selectedProject = project),
                          validator:
                              isTransfer
                                  ? (project) =>
                                      project == null
                                          ? 'Selecione a obra de destino'
                                          : null
                                  : null,
                        ),
                        if (!isTransfer)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Deixe vazio para baixar como uso geral/perda do deposito.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _qtdController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        decoration: InputDecoration(
                          labelText:
                              isAdjustment
                                  ? 'Novo saldo (${widget.item.unit})'
                                  : 'Quantidade (${widget.item.unit})',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isAdjustment
                                ? 'Informe o novo saldo'
                                : 'Informe a quantidade';
                          }
                          final quantity = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (quantity == null) return 'Valor invalido';
                          if (isAdjustment) {
                            return quantity < 0
                                ? 'Informe saldo igual ou maior que zero'
                                : null;
                          }
                          if (quantity <= 0) return 'Valor invalido';
                          if (quantity > widget.item.quantity) {
                            return 'Saldo insuficiente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText:
                              isAdjustment
                                  ? 'Justificativa (opcional)'
                                  : 'Observacoes (opcional)',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          onPressed: _isSaving ? null : _submit,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
                  ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final quantity = double.parse(_qtdController.text.replaceAll(',', '.'));
      final notes =
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim();

      if (widget.type == InventoryMovementType.adjustment) {
        await _inventoryService.addAdjustment(
          itemId: widget.item.id,
          itemName: widget.item.name,
          newQuantity: quantity,
          userId: 'current_user',
          notes: notes,
        );
      } else {
        final movement = InventoryMovement(
          id: '',
          itemId: widget.item.id,
          itemName: widget.item.name,
          quantity: quantity,
          type: widget.type,
          projectId: _selectedProject?.id,
          projectName: _selectedProject?.name,
          date: DateTime.now(),
          notes: notes,
          userId: 'current_user',
        );

        await _inventoryService.addMovement(movement);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimentacao registrada com sucesso!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $error'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _needsProjectPicker =>
      widget.type == InventoryMovementType.transfer ||
      widget.type == InventoryMovementType.outbound;

  String get _dialogTitle {
    switch (widget.type) {
      case InventoryMovementType.inbound:
        return 'Registrar entrada';
      case InventoryMovementType.outbound:
        return 'Registrar baixa / uso';
      case InventoryMovementType.transfer:
        return 'Transferir para obra';
      case InventoryMovementType.adjustment:
        return 'Ajustar saldo';
    }
  }

  Color get _dialogColor {
    switch (widget.type) {
      case InventoryMovementType.inbound:
        return AppColors.accentGreen;
      case InventoryMovementType.outbound:
        return AppColors.accentRed;
      case InventoryMovementType.transfer:
        return AppColors.accentBlue;
      case InventoryMovementType.adjustment:
        return AppColors.accentGold;
    }
  }
}
