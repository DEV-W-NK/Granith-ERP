import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

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
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(560.0, size.width * 0.94);
    final dialogHeight = math.min(620.0, size.height * 0.86);

    return GranithDialogSurface(
      width: dialogWidth,
      maxHeight: dialogHeight,
      accentColor: color,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: SizedBox(
        height: dialogHeight,
        child: Column(
          children: [
            GranithDialogHeader(
              icon: _dialogIcon,
              title: _dialogTitle,
              subtitle:
                  '${widget.item.name} • Disponível: ${widget.item.quantity.toStringAsFixed(2)} ${widget.item.unit}',
              accentColor: color,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: color))
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: GranithFormSection(
                            title: 'Dados da movimentação',
                            icon: _dialogIcon,
                            accentColor: color,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAdjustment) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(11),
                                    decoration: AppDecorations.formHintPanel(
                                      color: color,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 17,
                                          color: AppColors.accentGold,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Informe o novo saldo total do material.',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                if (_needsProjectPicker) ...[
                                  DropdownButtonFormField<Project>(
                                    isExpanded: true,
                                    dropdownColor: AppColors.secondaryDark,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: granithInputDecoration(
                                      label:
                                          isTransfer
                                              ? 'Obra de destino'
                                              : 'Obra de utilização',
                                      hint:
                                          isTransfer
                                              ? 'Selecione a obra de destino'
                                              : 'Selecione uma obra, se aplicável',
                                      icon: Icons.business_outlined,
                                      accentColor: color,
                                    ),
                                    items:
                                        _projects
                                            .map(
                                              (project) => DropdownMenuItem(
                                                value: project,
                                                child: Text(
                                                  project.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (project) => setState(
                                          () => _selectedProject = project,
                                        ),
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
                                      padding: EdgeInsets.only(top: 6, left: 4),
                                      child: Text(
                                        'Sem obra, a baixa será registrada como uso geral ou perda do depósito.',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  controller: _qtdController,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9,.]'),
                                    ),
                                  ],
                                  decoration: granithInputDecoration(
                                    label:
                                        isAdjustment
                                            ? 'Novo saldo (${widget.item.unit})'
                                            : 'Quantidade (${widget.item.unit})',
                                    hint:
                                        isAdjustment
                                            ? 'Informe o saldo atualizado'
                                            : 'Informe a quantidade movimentada',
                                    icon: Icons.straighten_outlined,
                                    accentColor: color,
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
                                    if (quantity == null) {
                                      return 'Valor inválido';
                                    }
                                    if (isAdjustment) {
                                      return quantity < 0
                                          ? 'Informe saldo igual ou maior que zero'
                                          : null;
                                    }
                                    if (quantity <= 0) return 'Valor inválido';
                                    if (quantity > widget.item.quantity) {
                                      return 'Saldo insuficiente';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: granithInputDecoration(
                                    label:
                                        isAdjustment
                                            ? 'Justificativa'
                                            : 'Observações',
                                    hint:
                                        isAdjustment
                                            ? 'Descreva o motivo do ajuste'
                                            : 'Adicione um contexto para a movimentação',
                                    icon: Icons.sticky_note_2_outlined,
                                    accentColor: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.28),
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderColor.withValues(alpha: 0.58),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    onPressed: _isSaving ? null : _submit,
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(_dialogIcon, size: 18),
                    label: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  IconData get _dialogIcon {
    switch (widget.type) {
      case InventoryMovementType.inbound:
        return Icons.add_box_outlined;
      case InventoryMovementType.outbound:
        return Icons.call_made_rounded;
      case InventoryMovementType.transfer:
        return Icons.swap_horiz_rounded;
      case InventoryMovementType.adjustment:
        return Icons.tune_rounded;
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
