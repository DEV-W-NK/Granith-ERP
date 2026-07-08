import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/services/supplier_service.dart' as services;
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';
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
        decoration: AppDecorations.dialogSurface(
          glowColor: AppColors.accentBlue,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _dialogContent(),
              ),
            ),
            _dialogActions(),
          ],
        ),
      ),
    );
  }

  Widget _dialogHeader() {
    return GranithDialogHeader(
      icon: Icons.search_rounded,
      title: 'Buscar por CNPJ',
      subtitle: 'Consulte dados cadastrais para preencher o fornecedor',
      accentColor: AppColors.accentBlue,
      onClose: () => Navigator.pop(context),
    );
  }

  Widget _dialogContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cnpjInputField(),
          const SizedBox(height: 24),
          if (_isLoading) _loadingWidget(),
          if (_errorMessage != null) _errorWidget(),
          if (_cnpjData != null) _cnpjDataPreview(),
        ],
      ),
    );
  }

  Widget _cnpjInputField() {
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
          decoration: granithInputDecoration(
            label: 'CNPJ',
            hint: '00.000.000/0000-00',
            icon: Icons.business_rounded,
            accentColor: AppColors.accentBlue,
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

  Widget _loadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
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

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
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

  Widget _cnpjDataPreview() {
    if (_cnpjData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
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
          _dataRow('Razão Social', _cnpjData!.razaoSocial),
          if (_cnpjData!.nomeFantasia.isNotEmpty)
            _dataRow('Nome Fantasia', _cnpjData!.nomeFantasia),
          _dataRow(
            'CNPJ',
            services.SupplierService.formatarCNPJ(_cnpjData!.cnpj),
          ),
          _dataRow('Situação', _cnpjData!.situacao),
          if (_cnpjData!.enderecoCompleto.isNotEmpty)
            _dataRow('Endereço', _cnpjData!.enderecoCompleto),
          if (_cnpjData!.telefone.isNotEmpty)
            _dataRow('Telefone', _cnpjData!.telefone),
          if (_cnpjData!.email.isNotEmpty) _dataRow('Email', _cnpjData!.email),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
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

  Widget _dialogActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.5),
                ),
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
      if (!mounted) return;

      if (cnpjData != null) {
        // Verifica se o CNPJ já existe no sistema
        final controller = Provider.of<SupplierController>(
          context,
          listen: false,
        );
        final cleanCnpj = services.SupplierService.limparCNPJ(
          _cnpjController.text,
        );
        final alreadyExists = controller.suppliers.any(
          (supplier) => supplier.cnpj == cleanCnpj,
        );

        if (alreadyExists) {
          setState(() {
            _errorMessage = 'CNPJ ja cadastrado no sistema';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _cnpjData = cnpjData;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = 'CNPJ nao encontrado';
        _isLoading = false;
      });
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
