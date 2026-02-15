import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para input formatters
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item; // Se null, é criação. Se preenchido, é edição.

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _unitController;
  late TextEditingController _weightController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _lengthController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _descController = TextEditingController(text: widget.item?.description);
    _unitController = TextEditingController(text: widget.item?.unit ?? 'un');
    
    // Formatação numérica simples
    _weightController = TextEditingController(text: widget.item?.weight?.toString());
    _widthController = TextEditingController(text: widget.item?.width?.toString());
    _heightController = TextEditingController(text: widget.item?.height?.toString());
    _lengthController = TextEditingController(text: widget.item?.length?.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _unitController.dispose();
    _weightController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        isEditing ? 'Editar Item' : 'Novo Item',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: 500, // Largura fixa para desktop/tablet
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Informações Básicas ===
                const Text('Informações Básicas', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Nome do Item*'),
                        validator: (value) => value?.isEmpty == true ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _unitController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Unidade (ex: kg)*'),
                        validator: (value) => value?.isEmpty == true ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Descrição (Opcional)'),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),
                
                // === Informações de Frete ===
                const Text('Logística & Frete (Opcional)', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _weightController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Peso (kg)').copyWith(suffixText: 'kg'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Largura').copyWith(suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Altura').copyWith(suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Comp.').copyWith(suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
          ),
          child: Text(isEditing ? 'Salvar Alterações' : 'Criar Item'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newItem = Item(
        id: widget.item?.id ?? '', // ID vazio na criação, será ignorado/gerado
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        unit: _unitController.text.trim(),
        weight: double.tryParse(_weightController.text),
        width: double.tryParse(_widthController.text),
        height: double.tryParse(_heightController.text),
        length: double.tryParse(_lengthController.text),
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, newItem);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accentGold),
      ),
      filled: true,
      fillColor: AppColors.backgroundDark,
    );
  }
}