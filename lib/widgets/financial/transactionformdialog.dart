import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

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
  static const _projectBudgetCategories = {
    TransactionCategory.material,
    TransactionCategory.labor,
    TransactionCategory.equipment,
  };

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

  bool get _isProjectBudgetCategory =>
      _type == TransactionType.expense &&
      _projectBudgetCategories.contains(_category);

  String get _allocationHelperText {
    if (_isProjectBudgetCategory) {
      return 'Custos de obra entram no projeto/orçamento. Gastos internos ficam como Administrativo.';
    }
    if (_type == TransactionType.expense) {
      return 'Sem projeto = gasto operacional da empresa.';
    }
    return 'Opcional para receitas sem obra vinculada.';
  }

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
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 700;
    final isCompact = size.width < ResponsiveLayout.compact;
    final horizontalPadding = isCompact ? 16.0 : 24.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(size.width < 420 ? 8 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: AppDecorations.dialogSurface(
          glowColor:
              _type == TransactionType.income
                  ? AppColors.accentGreen
                  : AppColors.accentGold,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 560 : double.infinity,
            maxHeight: size.height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    24,
                  ),
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
                                  v!.trim().isEmpty
                                      ? 'Campo obrigatório'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _responsivePair(
                          _buildAmountField(),
                          _buildStatusDropdown(),
                          isCompact,
                        ),
                        const SizedBox(height: 16),
                        _responsivePair(
                          _buildDatePicker(
                            label: 'Vencimento',
                            icon: Icons.calendar_today_outlined,
                            date: _dueDate,
                            nullable: false,
                            onChanged: (d) {
                              if (d != null) setState(() => _dueDate = d);
                            },
                          ),
                          _buildDatePicker(
                            label: 'Pagamento',
                            icon: Icons.check_circle_outline,
                            date: _paymentDate,
                            nullable: true,
                            onChanged: (d) => setState(() => _paymentDate = d),
                          ),
                          isCompact,
                        ),
                        const SizedBox(height: 16),
                        _responsivePair(
                          _buildCategoryDropdown(),
                          _buildOriginDropdown(),
                          isCompact,
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
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _responsivePair(Widget first, Widget second, bool isCompact) {
    if (isCompact) {
      return Column(children: [first, const SizedBox(height: 12), second]);
    }

    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildHeader() {
    final isIncome = _type == TransactionType.income;
    final color = isIncome ? AppColors.accentGreen : AppColors.accentGold;
    final label =
        _isEditing
            ? 'Editar transação'
            : (isIncome ? 'Nova receita' : 'Nova despesa');

    return GranithDialogHeader(
      icon: isIncome ? Icons.arrow_upward : Icons.arrow_downward,
      title: label,
      subtitle: 'Lancamento financeiro manual com status, origem e projeto',
      accentColor: color,
      onClose: () => Navigator.of(context).pop(),
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
            AppColors.accentGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeButton(
            TransactionType.expense,
            'Despesa',
            Icons.arrow_downward,
            AppColors.accentGold,
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
          color:
              selected
                  ? color.withValues(alpha: 0.12)
                  : AppColors.surfaceDark.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? color.withValues(alpha: 0.50)
                    : AppColors.borderColor.withValues(alpha: 0.58),
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
      initialValue: _status,
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
      initialValue: _category,
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
      initialValue: _origin,
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
      initialValue: _selectedProjectId,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _decoration(
        'Projeto / orçamento',
        Icons.account_tree_outlined,
      ).copyWith(
        helperText: _allocationHelperText,
        helperMaxLines: 2,
        helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
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
      validator:
          (v) =>
              _isProjectBudgetCategory && v == null
                  ? 'Selecione o projeto/orçamento ou use Administrativo.'
                  : null,
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
      final auth = _maybeReadAuth(context);
      final createdBy =
          widget.initial?.createdBy ?? auth?.user?.uid ?? 'unknown';

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
    return granithInputDecoration(
      label: label,
      hint: '',
      icon: icon,
      accentColor:
          _type == TransactionType.income
              ? AppColors.accentGreen
              : AppColors.accentGold,
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

AuthViewModel? _maybeReadAuth(BuildContext context) {
  try {
    return context.read<AuthViewModel>();
  } on ProviderNotFoundException {
    return null;
  }
}
