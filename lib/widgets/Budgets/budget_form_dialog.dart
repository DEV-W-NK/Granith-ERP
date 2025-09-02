import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/services/budget_type_service.dart';
import 'package:project_granith/themes/app_theme.dart';

// Classe para representar um tipo de orçamento com valor
class BudgetTypeItem {
  final BudgetType budgetType;
  double value;

  BudgetTypeItem({required this.budgetType, this.value = 0.0});

  Map<String, dynamic> toMap() {
    return {
      'budgetTypeId': budgetType.id,
      'budgetTypeName': budgetType.name,
      'budgetTypeDescription': budgetType.description,
      'budgetTypeCategory': budgetType.category,
      'budgetTypeIconName': budgetType.iconName,
      'budgetTypeColor': budgetType.color,
      'value': value,
    };
  }

  static BudgetTypeItem fromMap(Map<String, dynamic> map) {
    // Reconstituir o BudgetType a partir dos dados salvos
    final budgetType = BudgetType(
      id: map['budgetTypeId'] ?? '',
      name: map['budgetTypeName'] ?? '',
      description: map['budgetTypeDescription'] ?? '',
      category: map['budgetTypeCategory'] ?? '',
      isActive: true, // Assumir ativo por padrão
      createdAt: DateTime.now(), // Dados não persistidos
      updatedAt: DateTime.now(), // Dados não persistidos
      iconName: map['budgetTypeIconName'],
      color: map['budgetTypeColor'],
    );

    return BudgetTypeItem(
      budgetType: budgetType,
      value: (map['value'] ?? 0.0).toDouble(),
    );
  }
}

class BudgetFormDialog extends StatefulWidget {
  final Budget? budget;
  final Function(Budget) onSave;

  const BudgetFormDialog({super.key, this.budget, required this.onSave});

  @override
  State<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Novo serviço para tipos de orçamento
  final BudgetTypeService _budgetTypeService = BudgetTypeService();

  BudgetStatus _selectedStatus = BudgetStatus.pending;
  DateTime _creationDate = DateTime.now();
  DateTime? _expirationDate;
  bool _hasExpirationDate = true;

  // Variáveis para Budget Types múltiplos
  List<BudgetType> _availableBudgetTypes = [];
  List<BudgetTypeItem> _selectedBudgetTypeItems = [];
  bool _isLoadingBudgetTypes = false;
  double _totalValue = 0.0;

  final List<int> _expirationDaysOptions = [7, 15, 30, 45, 60, 90];
  int? _selectedExpirationDays = 30;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mapa de ícones comuns para fallback
  final Map<String, IconData> _iconMap = {
    'work': Icons.work,
    'home': Icons.home,
    'business': Icons.business,
    'construction': Icons.construction,
    'design_services': Icons.design_services,
    'computer': Icons.computer,
    'phone': Icons.phone,
    'car_repair': Icons.car_repair,
    'build': Icons.build,
    'electric_bolt': Icons.electric_bolt,
    'plumbing': Icons.plumbing,
    'architecture': Icons.architecture,
    'engineering': Icons.engineering,
    'web': Icons.web,
    'mobile_friendly': Icons.mobile_friendly,
    'campaign': Icons.campaign,
    'paint': Icons.format_paint,
    'photo_camera': Icons.photo_camera,
    'music_note': Icons.music_note,
    'event': Icons.event,
    'restaurant': Icons.restaurant,
  };

  // Função para converter iconName em IconData
  IconData _getIconFromName(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.work_outline; // Ícone padrão
    }
    return _iconMap[iconName] ?? Icons.work_outline;
  }

  // Função para converter cor string em Color
  Color _getColorFromString(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.blue; // Cor padrão
    }

    try {
      // Se for um código hex (ex: "#FF5722" ou "FF5722")
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      // Se for um valor int como string
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.blue; // Fallback se não conseguir parsear
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Carregar tipos de orçamento primeiro
    _loadBudgetTypes();

    if (widget.budget != null) {
      _clientController.text = widget.budget!.clientName;
      _projectController.text = widget.budget!.projectName;
      _descriptionController.text = widget.budget!.description;
      _selectedStatus = _getUpdatedStatus(widget.budget!);
      _creationDate = widget.budget!.creationDate;
      _expirationDate = widget.budget!.expirationDate;
      _hasExpirationDate = _expirationDate != null;
      _totalValue = widget.budget!.totalValue;

      // Carregar os tipos de orçamento existentes após carregar os tipos disponíveis
      _loadExistingBudgetTypes();

      if (_expirationDate != null) {
        final days = _expirationDate!.difference(_creationDate).inDays;
        if (_expirationDaysOptions.contains(days)) {
          _selectedExpirationDays = days;
        } else {
          _selectedExpirationDays = null;
        }
      }
    } else {
      _expirationDate = _creationDate.add(
        Duration(days: _selectedExpirationDays!),
      );
    }
  }

  // Nova função para carregar os tipos de orçamento existentes
  Future<void> _loadExistingBudgetTypes() async {
    if (widget.budget == null) return;

    // Aguardar os tipos de orçamento serem carregados
    while (_isLoadingBudgetTypes) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _selectedBudgetTypeItems.clear();

      // Se o budget tem items, tentar reconstruir os tipos baseado nos items
      if (widget.budget!.items.isNotEmpty) {
        for (var item in widget.budget!.items) {
          // Tentar encontrar o tipo correspondente pela descrição
          BudgetType? matchingType;

          for (var availableType in _availableBudgetTypes) {
            // Verificar se a descrição do item contém o nome do tipo
            if (item.description.toLowerCase().contains(
              availableType.name.toLowerCase(),
            )) {
              matchingType = availableType;
              break;
            }
          }

          // Se encontrou um tipo correspondente, adicionar
          if (matchingType != null) {
            _selectedBudgetTypeItems.add(
              BudgetTypeItem(
                budgetType: matchingType,
                value:
                    item.total, // Corrigido: usar item.total em vez de item.totalPrice
              ),
            );
          } else {
            // Se não encontrou, criar um tipo genérico baseado no item
            final genericType = BudgetType(
              id: 'generic_${DateTime.now().millisecondsSinceEpoch}',
              name: item.description.split(' - ').first,
              description:
                  item.description.contains(' - ')
                      ? item.description.split(' - ').last
                      : 'Serviço personalizado',
              category: 'Outros',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              iconName: 'work',
              color: '#2196F3',
            );

            _selectedBudgetTypeItems.add(
              BudgetTypeItem(
                budgetType: genericType,
                value: item.total, // Corrigido: usar item.total
              ),
            );
          }
        }
      }
      // Fallback: se tem budgetType único (sistema antigo)
      else if (widget.budget!.budgetType != null) {
        _selectedBudgetTypeItems.add(
          BudgetTypeItem(
            budgetType: widget.budget!.budgetType!,
            value: widget.budget!.totalValue,
          ),
        );
      }
      // Se não tem items nem budgetType, mas tem um budgetTypeId, tentar encontrar o tipo
      else if (widget.budget!.budgetTypeId != null) {
        final matchingType = _availableBudgetTypes.firstWhere(
          (type) => type.id == widget.budget!.budgetTypeId,
          orElse:
              () => BudgetType(
                id: widget.budget!.budgetTypeId!,
                name: 'Tipo Desconhecido',
                description: 'Tipo de orçamento não encontrado',
                category: 'Outros',
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                iconName: 'work',
                color: '#2196F3',
              ),
        );

        _selectedBudgetTypeItems.add(
          BudgetTypeItem(
            budgetType: matchingType,
            value: widget.budget!.totalValue,
          ),
        );
      }

      // Recalcular o total
      _calculateTotalValue();
    });
  }

  Future<void> _loadBudgetTypes() async {
    setState(() {
      _isLoadingBudgetTypes = true;
    });

    try {
      final budgetTypes = await _budgetTypeService.getActiveBudgetTypes();
      setState(() {
        _availableBudgetTypes = budgetTypes;
        _isLoadingBudgetTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBudgetTypes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar tipos de orçamento: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  BudgetStatus _getUpdatedStatus(Budget budget) {
    if (budget.expirationDate != null &&
        DateTime.now().isAfter(budget.expirationDate!) &&
        budget.status == BudgetStatus.pending) {
      return BudgetStatus.expired;
    }
    return budget.status;
  }

  void _updateExpirationDate() {
    if (_hasExpirationDate && _selectedExpirationDays != null) {
      setState(() {
        _expirationDate = _creationDate.add(
          Duration(days: _selectedExpirationDays!),
        );
      });
    }
  }

  void _calculateTotalValue() {
    double total = 0.0;
    for (var item in _selectedBudgetTypeItems) {
      total += item.value;
    }
    setState(() {
      _totalValue = total;
    });
  }

  void _addBudgetTypeItem(BudgetType budgetType) {
    if (!_selectedBudgetTypeItems.any(
      (item) => item.budgetType.id == budgetType.id,
    )) {
      setState(() {
        _selectedBudgetTypeItems.add(BudgetTypeItem(budgetType: budgetType));
      });
      _calculateTotalValue();
    }
  }

  void _removeBudgetTypeItem(int index) {
    setState(() {
      _selectedBudgetTypeItems.removeAt(index);
    });
    _calculateTotalValue();
  }

  void _updateBudgetTypeItemValue(int index, double value) {
    setState(() {
      _selectedBudgetTypeItems[index].value = value;
    });
    _calculateTotalValue();
  }

  Future<void> _selectCustomExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecionar data de expiração',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accentGold,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.surfaceDark,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expirationDate = picked;
        _selectedExpirationDays = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  bool _isExpired() {
    return _expirationDate != null && DateTime.now().isAfter(_expirationDate!);
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.accentGold, size: 20),
            filled: true,
            fillColor: AppColors.secondaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorStyle: const TextStyle(color: AppColors.accentRed),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetTypesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGold, Color(0xFFB8941F)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tipos de Orçamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatCurrency(_totalValue),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de tipos selecionados
            if (_selectedBudgetTypeItems.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedBudgetTypeItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedBudgetTypeItems[index];
                  final iconData = _getIconFromName(item.budgetType.iconName);
                  final iconColor = _getColorFromString(item.budgetType.color);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(iconData, color: iconColor, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.budgetType.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (item.budgetType.description.isNotEmpty)
                                Text(
                                  item.budgetType.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            initialValue:
                                item.value > 0 ? item.value.toString() : '',
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0,00',
                              prefix: const Text('R\$ '),
                              prefixStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.primaryDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              final numValue = double.tryParse(value) ?? 0.0;
                              _updateBudgetTypeItemValue(index, numValue);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeBudgetTypeItem(index),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.accentRed,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Botão para adicionar tipo
            if (_isLoadingBudgetTypes)
              const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              )
            else
              GestureDetector(
                onTap: () => _showBudgetTypeSelector(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: AppColors.accentGold,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Adicionar Tipo de Orçamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBudgetTypeSelector() {
    final availableTypes =
        _availableBudgetTypes
            .where(
              (type) =>
                  !_selectedBudgetTypeItems.any(
                    (item) => item.budgetType.id == type.id,
                  ),
            )
            .toList();

    if (availableTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os tipos de orçamento já foram adicionados'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecionar Tipo de Orçamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableTypes.length,
                  itemBuilder: (context, index) {
                    final budgetType = availableTypes[index];
                    final iconData = _getIconFromName(budgetType.iconName);
                    final iconColor = _getColorFromString(budgetType.color);

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      title: Text(
                        budgetType.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle:
                          budgetType.description.isNotEmpty
                              ? Text(
                                budgetType.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              )
                              : null,
                      onTap: () {
                        _addBudgetTypeItem(budgetType);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status do Orçamento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondaryDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BudgetStatus>(
              value: _selectedStatus,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.accentGold,
              ),
              items:
                  BudgetStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: status.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              status.icon,
                              color: status.color,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            status.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGold, Color(0xFFB8941F)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primaryDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Prazo de Validade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  Switch(
                    value: _hasExpirationDate,
                    onChanged: (value) {
                      setState(() {
                        _hasExpirationDate = value;
                        if (value) {
                          _updateExpirationDate();
                        } else {
                          _expirationDate = null;
                          _selectedExpirationDays = 30;
                        }
                      });
                    },
                    activeColor: AppColors.accentGold,
                    activeTrackColor: AppColors.accentGold.withOpacity(0.3),
                    inactiveThumbColor: AppColors.textMuted,
                    inactiveTrackColor: AppColors.borderColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasExpirationDate
                              ? 'Prazo ativado'
                              : 'Sem prazo definido',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _hasExpirationDate
                              ? 'O orçamento terá data de expiração'
                              : 'O orçamento não expirará automaticamente',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_hasExpirationDate) ...[
              const SizedBox(height: 20),

              const Text(
                'Selecione o prazo:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _expirationDaysOptions.map((days) {
                      final isSelected = _selectedExpirationDays == days;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedExpirationDays = days;
                              _updateExpirationDate();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  isSelected
                                      ? const LinearGradient(
                                        colors: [
                                          AppColors.accentGold,
                                          Color(0xFFB8941F),
                                        ],
                                      )
                                      : null,
                              color:
                                  isSelected ? null : AppColors.secondaryDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.transparent
                                        : AppColors.borderColor,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: AppColors.accentGold
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color:
                                      isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$days dias',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _selectCustomExpirationDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _selectedExpirationDays == null
                              ? AppColors.accentGold
                              : AppColors.borderColor,
                      width: _selectedExpirationDays == null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color:
                            _selectedExpirationDays == null
                                ? AppColors.accentGold
                                : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedExpirationDays == null
                              ? 'Data personalizada selecionada'
                              : 'Escolher data específica',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                _selectedExpirationDays == null
                                    ? AppColors.accentGold
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color:
                            _selectedExpirationDays == null
                                ? AppColors.accentGold
                                : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              if (_expirationDate != null) ...[
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        _isExpired()
                            ? AppColors.accentRed.withOpacity(0.1)
                            : AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _isExpired()
                              ? AppColors.accentRed
                              : AppColors.accentGreen,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              _isExpired()
                                  ? AppColors.accentRed
                                  : AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isExpired()
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isExpired()
                                  ? 'ORÇAMENTO EXPIRADO'
                                  : 'Válido até: ${_formatDate(_expirationDate!)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    _isExpired()
                                        ? AppColors.accentRed
                                        : AppColors.accentGreen,
                              ),
                            ),
                            if (_isExpired())
                              Text(
                                'Expirou em: ${_formatDate(_expirationDate!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentRed,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accentGold, Color(0xFFB8941F)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.budget != null
                                  ? Icons.edit_rounded
                                  : Icons.add_rounded,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.budget != null
                                      ? 'Editar Orçamento'
                                      : 'Novo Orçamento',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  widget.budget != null
                                      ? 'Modifique as informações do orçamento'
                                      : 'Preencha os dados para criar um novo orçamento',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryDark.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cliente e Projeto
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomTextField(
                                  controller: _clientController,
                                  label: 'Cliente',
                                  icon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nome do cliente é obrigatório';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCustomTextField(
                                  controller: _projectController,
                                  label: 'Projeto',
                                  icon: Icons.work_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nome do projeto é obrigatório';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Seção de Tipos de Orçamento
                          _buildBudgetTypesSection(),
                          const SizedBox(height: 24),

                          // Status
                          _buildStatusDropdown(),
                          const SizedBox(height: 24),

                          // Seção de Expiração
                          _buildExpirationSection(),
                          const SizedBox(height: 20),

                          // Descrição
                          _buildCustomTextField(
                            controller: _descriptionController,
                            label: 'Descrição (Opcional)',
                            icon: Icons.description_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),

                          // Botões
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      // Validar se pelo menos um tipo foi adicionado
                                      if (_selectedBudgetTypeItems.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Adicione pelo menos um tipo de orçamento',
                                            ),
                                            backgroundColor:
                                                AppColors.accentRed,
                                          ),
                                        );
                                        return;
                                      }

                                      // Validar se todos os tipos têm valor
                                      final hasInvalidValues =
                                          _selectedBudgetTypeItems.any(
                                            (item) => item.value <= 0,
                                          );
                                      if (hasInvalidValues) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Todos os tipos devem ter um valor maior que zero',
                                            ),
                                            backgroundColor:
                                                AppColors.accentRed,
                                          ),
                                        );
                                        return;
                                      }

                                      BudgetStatus finalStatus =
                                          _selectedStatus;
                                      if (_hasExpirationDate &&
                                          _expirationDate != null &&
                                          DateTime.now().isAfter(
                                            _expirationDate!,
                                          ) &&
                                          _selectedStatus ==
                                              BudgetStatus.pending) {
                                        finalStatus = BudgetStatus.expired;
                                      }

                                      // Converter BudgetTypeItems para BudgetItems tradicionais
                                      // Cada tipo de orçamento vira um item no orçamento
                                      final budgetItems =
                                          _selectedBudgetTypeItems.map((
                                            typeItem,
                                          ) {
                                            return BudgetItem(
                                              description:
                                                  '${typeItem.budgetType.name} - ${typeItem.budgetType.description}',
                                              quantity: 1,
                                              unitPrice: typeItem.value,
                                            );
                                          }).toList();

                                      // Criar o orçamento
                                      final budget = Budget(
                                        id:
                                            widget.budget?.id ??
                                            DateTime.now()
                                                .millisecondsSinceEpoch
                                                .toString(),
                                        clientName: _clientController.text,
                                        projectName: _projectController.text,
                                        totalValue: _totalValue,
                                        creationDate: _creationDate,
                                        expirationDate:
                                            _hasExpirationDate
                                                ? _expirationDate
                                                : null,
                                        status: finalStatus,
                                        description:
                                            _descriptionController.text,
                                        items: budgetItems,
                                        // Para compatibilidade, se houver apenas um tipo, usar os campos antigos
                                        budgetTypeId:
                                            _selectedBudgetTypeItems.length == 1
                                                ? _selectedBudgetTypeItems
                                                    .first
                                                    .budgetType
                                                    .id
                                                : null,
                                        budgetType:
                                            _selectedBudgetTypeItems.length == 1
                                                ? _selectedBudgetTypeItems
                                                    .first
                                                    .budgetType
                                                : null,
                                      );

                                      widget.onSave(budget);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentGold,
                                    foregroundColor: AppColors.primaryDark,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.budget != null
                                            ? 'Salvar Alterações'
                                            : 'Criar Orçamento',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _clientController.dispose();
    _projectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
