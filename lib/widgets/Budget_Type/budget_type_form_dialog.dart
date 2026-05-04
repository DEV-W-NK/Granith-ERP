import 'package:flutter/material.dart';
import 'package:project_granith/constants/budget_type_constants.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/themes/app_theme.dart';

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
    if (widget.budgetType != null) {
      final budgetType = widget.budgetType!;
      _nameController.text = budgetType.name;
      _descriptionController.text = budgetType.description;
      _selectedCategory = budgetType.category;
      _selectedIcon = budgetType.iconName;
      _isActive = budgetType.isActive;

      if (budgetType.color != null) {
        _selectedColor = Color(int.parse(budgetType.color!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >
        BudgetTypeConstants.desktopBreakpoint;

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isDesktop ? 600 : null,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildDialogBody(),
              ),
            ),
            _buildDialogActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, Color(0xFF1a1a2e)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: AppColors.accentGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.budgetType == null
                      ? 'Novo Tipo de Orçamento'
                      : 'Editar Tipo de Orçamento',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.budgetType == null
                      ? 'Preencha as informações do novo tipo'
                      : 'Altere as informações necessárias',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameField(),
          const SizedBox(height: 20),
          _buildDescriptionField(),
          const SizedBox(height: 20),
          _buildCategorySelector(),
          const SizedBox(height: 20),
          _buildIconSelector(),
          const SizedBox(height: 20),
          _buildColorSelector(),
          const SizedBox(height: 20),
          _buildStatusSwitch(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nome *',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Ex: Alvenaria, Pintura, Elétrica...',
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
                color: AppColors.accentGold,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            if (value.trim().length < BudgetTypeConstants.minNameLength) {
              return 'Nome deve ter pelo menos ${BudgetTypeConstants.minNameLength} caracteres';
            }
            if (value.trim().length > BudgetTypeConstants.maxNameLength) {
              return 'Nome deve ter no máximo ${BudgetTypeConstants.maxNameLength} caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descrição *',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Descreva detalhadamente este tipo de orçamento...',
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
                color: AppColors.accentGold,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Descrição é obrigatória';
            }
            if (value.trim().length <
                BudgetTypeConstants.minDescriptionLength) {
              return 'Descrição deve ter pelo menos ${BudgetTypeConstants.minDescriptionLength} caracteres';
            }
            if (value.trim().length >
                BudgetTypeConstants.maxDescriptionLength) {
              return 'Descrição deve ter no máximo ${BudgetTypeConstants.maxDescriptionLength} caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoria *',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                  // Reset icon selection when category changes
                  _selectedIcon = null;
                });
              }
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: AppColors.surfaceDark,
            style: const TextStyle(color: AppColors.textPrimary),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
            items:
                BudgetTypeConstants.categories.map((category) {
                  final categoryColor =
                      BudgetTypeConstants.categoryColors[category] ??
                      AppColors.accentGold;
                  final categoryIcon =
                      BudgetTypeConstants.categoryIcons[category] ??
                      Icons.category;

                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(categoryIcon, color: categoryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          category,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ícone',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: BudgetTypeConstants.availableIcons.length,
            itemBuilder: (context, index) {
              final iconEntry = BudgetTypeConstants.availableIcons.entries
                  .elementAt(index);
              final iconName = iconEntry.key;
              final iconData = iconEntry.value;
              final isSelected = _selectedIcon == iconName;
              final displayColor =
                  _selectedColor ??
                  BudgetTypeConstants.categoryColors[_selectedCategory] ??
                  AppColors.accentGold;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = isSelected ? null : iconName;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? displayColor.withOpacity(0.2)
                            : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected
                              ? displayColor
                              : AppColors.borderColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: isSelected ? displayColor : AppColors.textMuted,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final availableColors = [
      AppColors.accentGold,
      AppColors.accentBlue,
      AppColors.accentRed,
      AppColors.accentGreen,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFFE91E63), // Pink
      const Color(0xFF009688), // Teal
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFFFF5722), // Deep Orange
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.horizontal,
            itemCount: availableColors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = availableColors[index];
              final isSelected = _selectedColor == color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = isSelected ? null : color;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.textPrimary
                              : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                          : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.visibility : Icons.visibility_off,
            color: _isActive ? AppColors.accentGold : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isActive
                      ? 'Este tipo estará disponível para uso'
                      : 'Este tipo ficará oculto e indisponível',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeThumbColor: AppColors.accentGold,
            activeTrackColor: AppColors.accentGold.withOpacity(0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.textMuted.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.borderColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.primaryDark,
                          ),
                        ),
                      )
                      : Text(
                        widget.budgetType == null ? 'Criar' : 'Salvar',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final budgetType = BudgetType(
        id: widget.budgetType?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        iconName: _selectedIcon,
        color: _selectedColor?.value.toString(),
        isActive: _isActive,
        createdAt: widget.budgetType?.createdAt ?? now,
        updatedAt: now,
      );

      widget.onSave(budgetType);
      Navigator.of(context).pop();
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
