import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/services/supplier_service.dart' as services;
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class CNPJLookupDialog extends StatefulWidget {
  const CNPJLookupDialog({super.key});

  @override
  State<CNPJLookupDialog> createState() => _CNPJLookupDialogState();
}

class _CNPJLookupDialogState extends State<CNPJLookupDialog> {
  final _cnpjController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _service = services.SupplierService();

  bool _isLoading = false;
  services.CNPJData? _cnpjData;
  String? _errorMessage;

  @override
  void dispose() {
    _cnpjController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isDesktop ? 600 : null,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _DialogContent(),
              ),
            ),
            _DialogActions(),
          ],
        ),
      ),
    );
  }

  Widget _DialogHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withOpacity(0.1),
            AppColors.accentBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buscar por CNPJ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulte dados da Receita Federal',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.borderColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _DialogContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CNPJInputField(),
          const SizedBox(height: 24),
          if (_isLoading) _LoadingWidget(),
          if (_errorMessage != null) _ErrorWidget(),
          if (_cnpjData != null) _CNPJDataPreview(),
        ],
      ),
    );
  }

  Widget _CNPJInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CNPJ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cnpjController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CNPJFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '00.000.000/0000-00',
            hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: AppColors.accentBlue,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentRed,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'CNPJ é obrigatório';
            }

            final cleanCnpj = value.replaceAll(RegExp(r'[^\d]'), '');
            if (cleanCnpj.length != 14) {
              return 'CNPJ deve ter 14 dígitos';
            }

            if (!services.SupplierService.validarCNPJ(cleanCnpj)) {
              return 'CNPJ inválido';
            }

            return null;
          },
          onChanged: (_) {
            // Limpa dados anteriores quando o CNPJ muda
            if (_cnpjData != null || _errorMessage != null) {
              setState(() {
                _cnpjData = null;
                _errorMessage = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _LoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Consultando dados na Receita Federal...',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _ErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.accentRed,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _CNPJDataPreview() {
    if (_cnpjData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Dados encontrados',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DataRow('Razão Social', _cnpjData!.razaoSocial),
          if (_cnpjData!.nomeFantasia.isNotEmpty)
            _DataRow('Nome Fantasia', _cnpjData!.nomeFantasia),
          _DataRow(
            'CNPJ',
            services.SupplierService.formatarCNPJ(_cnpjData!.cnpj),
          ),
          _DataRow('Situação', _cnpjData!.situacao),
          if (_cnpjData!.enderecoCompleto.isNotEmpty)
            _DataRow('Endereço', _cnpjData!.enderecoCompleto),
          if (_cnpjData!.telefone.isNotEmpty)
            _DataRow('Telefone', _cnpjData!.telefone),
          if (_cnpjData!.email.isNotEmpty) _DataRow('Email', _cnpjData!.email),
        ],
      ),
    );
  }

  Widget _DataRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < ResponsiveLayout.compact;
          final labelText = Text(
            '$label:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
          final valueText = Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 2), valueText],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: labelText),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }

  Widget _DialogActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: BorderSide(color: AppColors.borderColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _getActionButtonCallback(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _cnpjData != null
                        ? AppColors.accentGreen
                        : AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(_cnpjData != null ? 'Cadastrar' : 'Consultar'),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getActionButtonCallback() {
    if (_isLoading) return null;

    if (_cnpjData != null) {
      return _createSupplierFromCNPJ;
    } else {
      return _consultarCNPJ;
    }
  }

  Future<void> _consultarCNPJ() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cnpjData = null;
    });

    try {
      final cnpjData = await _service.consultarCNPJ(_cnpjController.text);

      if (cnpjData != null) {
        // Verifica se o CNPJ já existe no sistema
        final controller = Provider.of<SupplierController>(
          context,
          listen: false,
        );
        final existingSupplier = controller.suppliers.firstWhere(
          (s) =>
              s.cnpj ==
              services.SupplierService.limparCNPJ(_cnpjController.text),
          orElse: () => null as dynamic,
        );

        setState(() {
          _errorMessage = 'CNPJ já cadastrado no sistema';
          _isLoading = false;
        });
        return;

        setState(() {
          _cnpjData = cnpjData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createSupplierFromCNPJ() async {
    if (_cnpjData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = Provider.of<SupplierController>(
        context,
        listen: false,
      );
      final supplier = _cnpjData!.toSupplier();

      await controller.createSupplier(supplier);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('Fornecedor "${supplier.name}" cadastrado com sucesso!'),
              ],
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}

// Formatador de CNPJ
class _CNPJFormatter extends TextInputFormatter {
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
