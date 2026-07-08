import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item;

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

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
    _weightController = TextEditingController(
      text: widget.item?.weight?.toString(),
    );
    _widthController = TextEditingController(
      text: widget.item?.width?.toString(),
    );
    _heightController = TextEditingController(
      text: widget.item?.height?.toString(),
    );
    _lengthController = TextEditingController(
      text: widget.item?.length?.toString(),
    );
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
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < ResponsiveLayout.compact;
    final inset = size.width < 420 ? 8.0 : 24.0;
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 500.0);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: EdgeInsets.all(inset),
      title: Text(
        isEditing ? 'Editar Item' : 'Novo Item',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: dialogWidth.toDouble(),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Informa\u00e7\u00f5es B\u00e1sicas'),
                const SizedBox(height: 16),
                _buildBasicFields(isCompact),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    'Descri\u00e7\u00e3o (Opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                _sectionTitle('Log\u00edstica & Frete (Opcional)'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    'Peso (kg)',
                  ).copyWith(suffixText: 'kg'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_decimalFormatter],
                ),
                const SizedBox(height: 16),
                _buildDimensionFields(isCompact),
              ],
            ),
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
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
          ),
          child: Text(isEditing ? 'Salvar Altera\u00e7\u00f5es' : 'Criar Item'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentGold,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBasicFields(bool isCompact) {
    final nameField = TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration('Nome do Item*'),
      validator: _requiredValidator,
    );
    final unitField = TextFormField(
      controller: _unitController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration('Unidade (ex: kg)*'),
      validator: _requiredValidator,
    );

    if (isCompact) {
      return Column(
        children: [nameField, const SizedBox(height: 16), unitField],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: nameField),
        const SizedBox(width: 16),
        Expanded(child: unitField),
      ],
    );
  }

  Widget _buildDimensionFields(bool isCompact) {
    final fields = [
      _dimensionField(_widthController, 'Largura'),
      _dimensionField(_heightController, 'Altura'),
      _dimensionField(_lengthController, 'Comp.'),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            fields[index],
            if (index < fields.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: fields[0]),
        const SizedBox(width: 16),
        Expanded(child: fields[1]),
        const SizedBox(width: 16),
        Expanded(child: fields[2]),
      ],
    );
  }

  Widget _dimensionField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label).copyWith(suffixText: 'cm'),
      keyboardType: TextInputType.number,
      inputFormatters: [_decimalFormatter],
    );
  }

  FilteringTextInputFormatter get _decimalFormatter =>
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'));

  String? _requiredValidator(String? value) {
    return value?.isEmpty == true ? 'Obrigat\u00f3rio' : null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newItem = Item(
        id: widget.item?.id ?? '',
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
    return granithInputDecoration(
      label: label,
      hint: '',
      accentColor: AppColors.accentBlue,
    );
  }
}
