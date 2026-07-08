import 'package:flutter/material.dart';
import 'package:project_granith/constants/budget_type_constants.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

class BudgetTypeFormDialog extends StatefulWidget {
  final BudgetType? budgetType;
  final Function(BudgetType) onSave;

  const BudgetTypeFormDialog({
    super.key,
    this.budgetType,
    required this.onSave,
  });

  @override
  State<BudgetTypeFormDialog> createState() => _BudgetTypeFormDialogState();
}

class _BudgetTypeFormDialogState extends State<BudgetTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = BudgetTypeConstants.categories.first;
  String? _selectedIcon;
  Color? _selectedColor;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.budgetType != null;

  List<String> get _categoryOptions {
    final options = [...BudgetTypeConstants.categories];
    if (_selectedCategory.isNotEmpty && !options.contains(_selectedCategory)) {
      options.add(_selectedCategory);
    }
    return options;
  }

  List<Color> get _availableColors => const [
    Color(0xFFD1A93D),
    Color(0xFF2196F3),
    Color(0xFF43A047),
    Color(0xFFE53935),
    Color(0xFF7E57C2),
    Color(0xFFFF9800),
    Color(0xFF009688),
    Color(0xFF607D8B),
    Color(0xFF3F51B5),
    Color(0xFFE91E63),
    Color(0xFF795548),
    Color(0xFFFF5722),
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final budgetType = widget.budgetType;
    if (budgetType == null) return;

    _nameController.text = budgetType.name;
    _descriptionController.text = budgetType.description;
    _selectedCategory = budgetType.category;
    _selectedIcon = budgetType.iconName;
    _selectedColor = _parseColor(budgetType.color);
    _isActive = budgetType.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final inset = size.width < 420 ? 10.0 : 24.0;
    final dialogWidth = (size.width - inset * 2).clamp(320.0, 820.0).toDouble();
    final dialogMaxHeight = size.height * (size.height < 720 ? 0.94 : 0.9);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(inset),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: dialogMaxHeight),
        decoration: AppDecorations.dialogSurface(glowColor: _effectiveColor()),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isWide ? 18 : 14),
                    child: _buildBody(isWide),
                  );
                },
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final color = _effectiveColor();
    final icon = _effectiveIcon();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: AppDecorations.dialogHeader(accent: color),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              boxShadow: AppColors.auraShadows(color),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Editar tipo de orçamento'
                      : 'Novo tipo de orçamento',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isWide) {
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormSection(
            title: 'Identificação',
            icon: Icons.badge_outlined,
            child:
                isWide
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNameField()),
                        const SizedBox(width: 14),
                        Expanded(child: _buildCategorySelector()),
                      ],
                    )
                    : Column(
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 14),
                        _buildCategorySelector(),
                      ],
                    ),
          ),
          const SizedBox(height: 14),
          _FormSection(
            title: 'Descrição comercial',
            icon: Icons.notes_rounded,
            child: _buildDescriptionField(),
          ),
          const SizedBox(height: 14),
          _FormSection(
            title: 'Aparência',
            icon: Icons.palette_outlined,
            child: _buildVisualControls(isWide),
          ),
          const SizedBox(height: 14),
          _buildStatusSwitch(),
        ],
      ),
    );

    if (!isWide) {
      return Column(
        children: [_buildPreviewPanel(), const SizedBox(height: 14), form],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 240, child: _buildPreviewPanel()),
        const SizedBox(width: 18),
        Expanded(child: form),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    final color = _effectiveColor();
    final icon = _effectiveIcon();
    final name =
        _nameController.text.trim().isEmpty
            ? 'Tipo sem nome'
            : _nameController.text.trim();
    final description =
        _descriptionController.text.trim().isEmpty
            ? 'Sem descrição'
            : _descriptionController.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              _StatusPreviewPill(active: _isActive),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BudgetTypeConstants.categoryIcons[_selectedCategory] ??
                      Icons.category,
                  color: color,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _selectedCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        label: 'Nome',
        hint: 'Mão de Obra, Engenharia, Combustível',
        icon: Icons.sell_outlined,
      ),
      maxLength: BudgetTypeConstants.maxNameLength,
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Nome é obrigatório';
        if (text.length < BudgetTypeConstants.minNameLength) {
          return 'Informe pelo menos ${BudgetTypeConstants.minNameLength} caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      minLines: 3,
      maxLines: 5,
      maxLength: BudgetTypeConstants.maxDescriptionLength,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        label: 'Descrição',
        hint: 'Resumo objetivo do custo ou escopo coberto por este tipo',
        icon: Icons.notes_rounded,
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Descrição é obrigatória';
        if (text.length < BudgetTypeConstants.minDescriptionLength) {
          return 'Informe pelo menos ${BudgetTypeConstants.minDescriptionLength} caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Categoria'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _categoryOptions.map((category) {
                final selected = category == _selectedCategory;
                final color =
                    BudgetTypeConstants.categoryColors[category] ??
                    AppColors.accentGold;
                final icon =
                    BudgetTypeConstants.categoryIcons[category] ??
                    Icons.category;

                return _SelectableToken(
                  label: category,
                  icon: icon,
                  color: color,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _selectedIcon = null;
                      _selectedColor = null;
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisualControls(bool isWide) {
    final iconSelector = _buildIconSelector();
    final colorSelector = _buildColorSelector();

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [iconSelector, const SizedBox(height: 14), colorSelector],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: iconSelector),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: colorSelector),
      ],
    );
  }

  Widget _buildIconSelector() {
    final displayColor = _effectiveColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Ícone'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 300
                    ? 5
                    : constraints.maxWidth < 430
                    ? 6
                    : 7;

            return Container(
              height: 170,
              padding: const EdgeInsets.all(10),
              decoration: _controlSurfaceDecoration(),
              child: GridView.builder(
                itemCount: BudgetTypeConstants.availableIcons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final entry = BudgetTypeConstants.availableIcons.entries
                      .elementAt(index);
                  final selected = _selectedIcon == entry.key;
                  return Tooltip(
                    message: entry.key,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = selected ? null : entry.key;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? displayColor.withValues(alpha: 0.16)
                                  : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selected
                                    ? displayColor.withValues(alpha: 0.65)
                                    : AppColors.borderColor.withValues(
                                      alpha: 0.25,
                                    ),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          color:
                              selected ? displayColor : AppColors.textSecondary,
                          size: 19,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Cor'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _controlSurfaceDecoration(),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                _availableColors.map((color) {
                  final selected = _selectedColor == color;
                  return Tooltip(
                    message:
                        '#${color.toARGB32().toRadixString(16).toUpperCase()}',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = selected ? null : color;
                        });
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color:
                                selected
                                    ? AppColors.textPrimary
                                    : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child:
                            selected
                                ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                                : null,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    final color = _isActive ? AppColors.accentGreen : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(
              _isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.visibility_off_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disponibilidade',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isActive ? 'Ativo para novos orçamentos' : 'Oculto no uso',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged:
                _isLoading
                    ? null
                    : (value) => setState(() => _isActive = value),
            activeThumbColor: AppColors.accentGreen,
            activeTrackColor: AppColors.accentGreen.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cancel = OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.55),
            ),
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancelar'),
        );
        final save = ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon:
              _isLoading
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryDark),
                    ),
                  )
                  : const Icon(Icons.save_outlined, size: 18),
          label: Text(_isEditing ? 'Salvar alterações' : 'Criar tipo'),
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.98),
            border: Border(
              top: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.38),
              ),
            ),
          ),
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [save, const SizedBox(height: 8), cancel],
                  )
                  : Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: save),
                    ],
                  ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return granithInputDecoration(
      label: label,
      hint: hint,
      icon: icon,
      accentColor: _effectiveColor(),
    ).copyWith(
      counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
    );
  }

  BoxDecoration _controlSurfaceDecoration() {
    return AppDecorations.formPanel(borderColor: _effectiveColor());
  }

  Color _effectiveColor() {
    return _selectedColor ??
        BudgetTypeConstants.categoryColors[_selectedCategory] ??
        AppColors.accentGold;
  }

  IconData _effectiveIcon() {
    return _selectedIcon != null
        ? BudgetTypeConstants.availableIcons[_selectedIcon!] ?? Icons.category
        : BudgetTypeConstants.categoryIcons[_selectedCategory] ??
            Icons.category;
  }

  Color? _parseColor(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final numeric = int.tryParse(value);
    if (numeric != null) return Color(numeric);

    final hex = value.replaceFirst('#', '');
    if (hex.length == 6 || hex.length == 8) {
      final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (parsed != null) return Color(parsed);
    }

    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final budgetType = BudgetType(
        id: widget.budgetType?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        iconName: _selectedIcon,
        color: _selectedColor?.toARGB32().toString(),
        isActive: _isActive,
        createdAt: widget.budgetType?.createdAt ?? now,
        updatedAt: now,
      );

      await Future.sync(() => widget.onSave(budgetType));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentGold, size: 17),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SelectableToken extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableToken({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.14) : AppColors.primaryDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected
                    ? color.withValues(alpha: 0.55)
                    : AppColors.borderColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPreviewPill extends StatelessWidget {
  final bool active;

  const _StatusPreviewPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accentGreen : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
