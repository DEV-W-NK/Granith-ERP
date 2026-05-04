import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class TransactionFormDialog extends StatefulWidget {
  final FinancialTransactionModel? initial;
  final TransactionType? forceType;

  const TransactionFormDialog({super.key, this.initial, this.forceType});

  static Future<void> show(
    BuildContext context, {
    FinancialTransactionModel? initial,
    TransactionType? forceType,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => TransactionFormDialog(initial: initial, forceType: forceType),
    );
  }

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  late TransactionStatus _status;
  late TransactionOrigin _origin;
  late TransactionCategory _category;

  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late DateTime _dueDate;
  DateTime? _paymentDate;
  String? _selectedProjectId;

  bool _isSaving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;

    _type = t?.type ?? widget.forceType ?? TransactionType.expense;
    _status = t?.status ?? TransactionStatus.pending;
    _origin = t?.origin ?? TransactionOrigin.manual;
    _category = t?.category ?? TransactionCategory.other;

    _descCtrl.text = t?.description ?? '';
    _amountCtrl.text = t != null ? t.amount.toStringAsFixed(2) : '';
    _notesCtrl.text = t?.notes ?? '';

    _dueDate = t?.dueDate ?? DateTime.now();
    _paymentDate = t?.paymentDate;
    _selectedProjectId = t?.projectId;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 560 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.forceType == null) ...[
                        const SizedBox(height: 20),
                        _buildTypeToggle(),
                      ],
                      const SizedBox(height: 20),
                      _buildTextField(
                        ctrl: _descCtrl,
                        label: 'Descrição',
                        icon: Icons.description_outlined,
                        validator:
                            (v) =>
                                v!.trim().isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildAmountField()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatusDropdown()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              label: 'Vencimento',
                              icon: Icons.calendar_today_outlined,
                              date: _dueDate,
                              nullable: false,
                              onChanged: (d) {
                                if (d != null) setState(() => _dueDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDatePicker(
                              label: 'Pagamento',
                              icon: Icons.check_circle_outline,
                              date: _paymentDate,
                              nullable: true,
                              onChanged:
                                  (d) => setState(() => _paymentDate = d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildCategoryDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildOriginDropdown()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProjectDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        ctrl: _notesCtrl,
                        label: 'Observações (opcional)',
                        icon: Icons.notes_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 28),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final isIncome = _type == TransactionType.income;
    final color = isIncome ? Colors.greenAccent : Colors.redAccent;
    final label =
        _isEditing
            ? 'Editar transação'
            : (isIncome ? 'Nova receita' : 'Nova despesa');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ─── Type toggle ─────────────────────────────────────────────────────────────

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: _typeButton(
            TransactionType.income,
            'Receita',
            Icons.arrow_upward,
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeButton(
            TransactionType.expense,
            'Despesa',
            Icons.arrow_downward,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _typeButton(
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textMuted,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Campos ──────────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration(label, icon),
      validator: validator,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration('Valor (R\$)', Icons.attach_money),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Obrigatório';
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) return 'Valor inválido';
        return null;
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<TransactionStatus>(
      value: _status,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration('Status', Icons.flag_outlined),
      items:
          TransactionStatus.values
              .map(
                (s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s))),
              )
              .toList(),
      onChanged: (v) => setState(() => _status = v!),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<TransactionCategory>(
      value: _category,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration('Categoria', Icons.category_outlined),
      items:
          TransactionCategory.values
              .map(
                (c) =>
                    DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
              )
              .toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _buildOriginDropdown() {
    return DropdownButtonFormField<TransactionOrigin>(
      value: _origin,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration('Origem', Icons.link_outlined),
      items:
          TransactionOrigin.values
              .map(
                (o) => DropdownMenuItem(value: o, child: Text(_originLabel(o))),
              )
              .toList(),
      onChanged: (v) => setState(() => _origin = v!),
    );
  }

  Widget _buildProjectDropdown() {
    final projects = context.watch<ProjectsController>().projects;

    return DropdownButtonFormField<String?>(
      value: _selectedProjectId,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration('Projeto (opcional)', Icons.folder_outlined),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Nenhum / Administrativo'),
        ),
        ...projects.map(
          (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
        ),
      ],
      onChanged: (v) => setState(() => _selectedProjectId = v),
    );
  }

  // nullable=false → dueDate (sempre DateTime, nunca null)
  // nullable=true  → paymentDate (null = ainda não pago)
  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? date,
    required bool nullable,
    required void Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder:
              (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accentGold,
                  ),
                ),
                child: child!,
              ),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _decoration(label, icon),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Não definido',
          style: TextStyle(
            color: date != null ? Colors.white : AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─── Botão salvar ─────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final isIncome = _type == TransactionType.income;
    final color = isIncome ? Colors.greenAccent : AppColors.accentGold;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryDark,
                  ),
                )
                : Text(
                  _isEditing ? 'SALVAR ALTERAÇÕES' : 'REGISTRAR',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
      ),
    );
  }

  // ─── Lógica de salvar ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // AuthController.user retorna UserModel? — usamos user.id
      final authCtrl = context.read<AuthController>();
      final createdBy =
          widget.initial?.createdBy ?? authCtrl.user?.uid ?? 'unknown';

      final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));

      final transaction = FinancialTransactionModel(
        id: widget.initial?.id ?? '',
        description: _descCtrl.text.trim(),
        amount: amount,
        type: _type,
        status: _status,
        origin: _origin,
        category: _category,
        dueDate: _dueDate,
        paymentDate: _paymentDate,
        projectId: _selectedProjectId,
        supplierId: widget.initial?.supplierId,
        referenceId: widget.initial?.referenceId,
        createdBy: createdBy,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      final ctrl = context.read<FinancialController>();
      if (_isEditing) {
        await ctrl.updateTransaction(transaction);
      } else {
        await ctrl.addTransaction(transaction);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Transação atualizada!'
                  : '${_type == TransactionType.income ? "Receita" : "Despesa"} registrada!',
            ),
            backgroundColor:
                _type == TransactionType.income ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Helpers de UI ───────────────────────────────────────────────────────────

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.accentGold),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String _statusLabel(TransactionStatus s) => switch (s) {
    TransactionStatus.pending => 'Pendente',
    TransactionStatus.paid => 'Pago',
    TransactionStatus.overdue => 'Atrasado',
    TransactionStatus.cancelled => 'Cancelado',
  };

  String _categoryLabel(TransactionCategory c) => switch (c) {
    TransactionCategory.material => 'Material',
    TransactionCategory.labor => 'Mão de obra',
    TransactionCategory.equipment => 'Equipamento',
    TransactionCategory.administrative => 'Administrativo',
    TransactionCategory.measurement => 'Medição',
    TransactionCategory.tax => 'Imposto / Taxa',
    TransactionCategory.other => 'Outro',
  };

  String _originLabel(TransactionOrigin o) => switch (o) {
    TransactionOrigin.manual => 'Manual',
    TransactionOrigin.purchase => 'Compra',
    TransactionOrigin.laborCost => 'Mão de obra',
    TransactionOrigin.materialUsage => 'Consumo material',
    TransactionOrigin.budget => 'Orçamento / Medição',
  };
}
