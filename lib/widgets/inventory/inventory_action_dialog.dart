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

  const InventoryActionDialog({
    super.key,
    required this.item,
    required this.type,
  });

  @override
  State<InventoryActionDialog> createState() => _InventoryActionDialogState();
}

class _InventoryActionDialogState extends State<InventoryActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController _qtdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Project> _projects = [];
  Project? _selectedProject;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final response = await AppSupabase.client
          .from('projects')
          .select()
          .order('name');

      final projs =
          (response as List).map((row) {
            final data = Map<String, dynamic>.from(row as Map);
            return Project.fromMap(data['id'] as String? ?? '', data);
          }).toList();

      if (mounted) {
        setState(() {
          _projects = projs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.type == InventoryMovementType.transfer;
    final title = isTransfer ? 'Transferir para Obra' : 'Registrar Baixa / Uso';
    final color = isTransfer ? AppColors.accentBlue : AppColors.accentRed;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        title,
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
                        'Disponível: ${widget.item.quantity.toStringAsFixed(2)} ${widget.item.unit}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      DropdownButtonFormField<Project>(
                        dropdownColor: AppColors.secondaryDark,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText:
                              isTransfer
                                  ? 'Para qual Obra? (Destino)'
                                  : 'Utilizado em qual Obra?',
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
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedProject = val),
                        validator:
                            isTransfer
                                ? (val) =>
                                    val == null
                                        ? 'Selecione a obra de destino'
                                        : null
                                : null,
                      ),
                      if (!isTransfer)
                        const Padding(
                          padding: EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'Deixe vazio para baixar como uso geral/perda do Depósito',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _qtdController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Quantidade (${widget.item.unit})',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Informe a quantidade';
                          final qtd = double.tryParse(val) ?? 0;
                          if (qtd <= 0) return 'Inválido';
                          if (qtd > widget.item.quantity)
                            return 'Saldo insuficiente';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Observações (Opcional)',
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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final qtd = double.parse(_qtdController.text);

        // Criando o objeto de movimentação
        final movement = InventoryMovement(
          id: '', // Sera gerado pelo banco
          itemId: widget.item.id,
          itemName: widget.item.name,
          quantity: qtd,
          type: widget.type,
          projectId: _selectedProject?.id,
          projectName: _selectedProject?.name,
          date: DateTime.now(),
          notes: _notesController.text,
          userId: 'current_user',
        );

        // Chamando o método no serviço (CORRIGIDO AQUI: addMovement com M maiúsculo)
        await _inventoryService.addMovement(movement);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimentação registrada com sucesso!'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
