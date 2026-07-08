import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/constants/supplier_constants.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

class SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;
  final Future<void> Function(Supplier) onSave;

  const SupplierFormDialog({super.key, this.supplier, required this.onSave});

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _cnpjFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.supplier != null;

    if (_isEditing) {
      _nameController.text = widget.supplier!.name;
      _cnpjController.text = widget.supplier!.formattedCnpj;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _nameFocusNode.dispose();
    _cnpjFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > SupplierConstants.desktopBreakpoint;
    final inset = size.width < 420 ? 8.0 : 16.0;
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 500.0);

    return GranithDialogSurface(
      width: dialogWidth.toDouble(),
      maxHeight: size.height * 0.92,
      accentColor: AppColors.accentBlue,
      insetPadding: EdgeInsets.all(inset),
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 500 : size.width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: ResponsiveLayout.pagePadding(size.width),
                child: _buildForm(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GranithDialogHeader(
      icon: Icons.business_rounded,
      title: _isEditing ? 'Editar fornecedor' : 'Novo fornecedor',
      subtitle:
          _isEditing
              ? 'Atualize as informacoes cadastrais'
              : 'Preencha os dados para cadastrar',
      accentColor: AppColors.accentBlue,
      onClose: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameField(),
          const SizedBox(height: 20),
          _buildCnpjField(),
          const SizedBox(height: 24),
          _buildFormInfo(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business_rounded,
              size: 18,
              color: AppColors.accentGold.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              SupplierConstants.labelSupplierName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: AppColors.accentRed,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          decoration: granithInputDecoration(
            hint: SupplierConstants.hintSupplierName,
            icon: Icons.business_rounded,
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          textCapitalization: TextCapitalization.words,
          validator: _validateName,
          onFieldSubmitted: (_) => _cnpjFocusNode.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildCnpjField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.badge_rounded,
              size: 18,
              color: AppColors.accentGold.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              SupplierConstants.labelSupplierCnpj,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: AppColors.accentRed,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cnpjController,
          focusNode: _cnpjFocusNode,
          decoration: granithInputDecoration(
            hint: SupplierConstants.hintSupplierCnpj,
            icon: Icons.badge_rounded,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CnpjInputFormatter(),
          ],
          validator: _validateCnpj,
          onFieldSubmitted: (_) => _handleSave(),
        ),
      ],
    );
  }

  Widget _buildFormInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentBlue.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Digite apenas os números do CNPJ. A formatação será aplicada automaticamente.',
              style: TextStyle(
                color: AppColors.accentBlue.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              SupplierConstants.buttonCancel,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryDark,
                        ),
                      ),
                    )
                    : Text(
                      _isEditing
                          ? SupplierConstants.buttonUpdate
                          : SupplierConstants.buttonCreate,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
          ),
        ],
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return SupplierConstants.errorNameRequired;
    }

    if (value.trim().length < SupplierConstants.minNameLength) {
      return 'Nome deve ter pelo menos ${SupplierConstants.minNameLength} caracteres';
    }

    if (value.trim().length > SupplierConstants.maxNameLength) {
      return 'Nome deve ter no máximo ${SupplierConstants.maxNameLength} caracteres';
    }

    return null;
  }

  String? _validateCnpj(String? value) {
    if (value == null || value.trim().isEmpty) {
      return SupplierConstants.errorCnpjRequired;
    }

    final cleanCnpj = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanCnpj.length != SupplierConstants.cnpjLength) {
      return 'CNPJ deve ter 14 dígitos';
    }

    if (!_isValidCnpj(cleanCnpj)) {
      return SupplierConstants.errorInvalidCnpj;
    }

    return null;
  }

  bool _isValidCnpj(String cnpj) {
    if (cnpj.length != 14) return false;

    // Check for known invalid patterns
    if (RegExp(r'^(\d)\1+').hasMatch(cnpj)) return false;

    // Calculate first verification digit
    int sum = 0;
    List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }

    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (digit1 != int.parse(cnpj[12])) return false;

    // Calculate second verification digit
    sum = 0;
    List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }

    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return digit2 == int.parse(cnpj[13]);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cleanCnpj = _cnpjController.text.replaceAll(RegExp(r'[^\d]'), '');

      final supplier = Supplier(
        id: _isEditing ? widget.supplier!.id : '',
        name: _nameController.text.trim(),
        cnpj: cleanCnpj,
        isActive: _isEditing ? widget.supplier!.isActive : true,
        createdAt: _isEditing ? widget.supplier!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.onSave(supplier);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? SupplierConstants.successUpdate
                  : SupplierConstants.successCreate,
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }
}

class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 14) {
      return oldValue;
    }

    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 5) {
        formatted += '.';
      } else if (i == 8) {
        formatted += '/';
      } else if (i == 12) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
