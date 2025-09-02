import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/Budgets/budget_card.dart';
import 'package:project_granith/widgets/budgets/budget_form_dialog.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final ServiceOrcamentos _service = ServiceOrcamentos();
  final TextEditingController _searchController = TextEditingController();
  BudgetStatus _filterStatus = BudgetStatus.pending;
  bool _isFiltering = false;
  bool _isUpdatingExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Adicione verificação aqui também
      if (mounted) {
        _forceCheckExpiredBudgets();
      }
    });
  }

  Future<void> _forceCheckExpiredBudgets() async {
    setState(() {
      _isUpdatingExpired = true;
    });

    try {
      await _service.forceUpdateExpiredBudgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verificando Orçamentos Expirados...'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar orçamentos expirados: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingExpired = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          _buildSearchBar(),
          Expanded(child: _buildBudgetList()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão para verificar orçamentos expirados
          FloatingActionButton.small(
            onPressed: _isUpdatingExpired ? null : _forceCheckExpiredBudgets,
            backgroundColor: AppColors.accentBlue,
            foregroundColor: AppColors.textPrimary,
            heroTag: "refresh",
            child:
                _isUpdatingExpired
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    )
                    : const Icon(Icons.refresh, size: 18),
          ),
          const SizedBox(height: 8),
          // Botão para adicionar novo orçamento
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => BudgetFormDialog(
                      onSave: (budget) async {
                        await _service.addBudget(budget);
                      },
                    ),
              );
            },
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
            heroTag: "add",
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryDark.withBlue(20)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.attach_money_outlined,
              color: AppColors.accentGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orçamentos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gerencie seus orçamentos e propostas',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (_isUpdatingExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Verificando...',
                    style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children:
                  BudgetStatus.values.map((status) {
                    return FilterChip(
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = status;
                          _isFiltering = true;
                        });
                      },
                      label: Text(status.displayName),
                      avatar: Icon(status.icon, size: 16),
                      backgroundColor: AppColors.secondaryDark,
                      selectedColor: status.color.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color:
                            _filterStatus == status
                                ? status.color
                                : AppColors.textSecondary,
                      ),
                      checkmarkColor: status.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          // Botão para limpar filtros
          if (_isFiltering)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isFiltering = false;
                  _filterStatus = BudgetStatus.pending;
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Limpar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar orçamentos...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                    )
                    : null,
            filled: true,
            fillColor: AppColors.secondaryDark.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildBudgetList() {
    return StreamBuilder<List<Budget>>(
      stream:
          _isFiltering
              ? _service.getBudgetsByStatus(_filterStatus)
              : _service.getBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.accentRed.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar orçamentos',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {}); // Força rebuild
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Carregando orçamentos...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final budgets = snapshot.data ?? [];
        final searchTerm = _searchController.text.toLowerCase();

        final filteredBudgets =
            searchTerm.isEmpty
                ? budgets
                : budgets
                    .where(
                      (budget) =>
                          budget.clientName.toLowerCase().contains(
                            searchTerm,
                          ) ||
                          budget.projectName.toLowerCase().contains(searchTerm),
                    )
                    .toList();

        if (filteredBudgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_money_outlined,
                  size: 64,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum orçamento encontrado',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFiltering || searchTerm.isNotEmpty
                      ? 'Tente alterar os filtros ou buscar por outros termos'
                      : 'Clique no botão + para criar seu primeiro orçamento',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredBudgets.length,
          itemBuilder: (context, index) {
            final budget = filteredBudgets[index];
            return BudgetCard(
              budget: budget,
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => BudgetFormDialog(
                        budget: budget,
                        onSave: (updatedBudget) async {
                          await _service.updateBudget(updatedBudget);
                        },
                      ),
                );
              },
              onDelete: () async {
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text(
                              'Confirmar exclusão',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            content: Text(
                              'Tem certeza que deseja excluir o orçamento de "${budget.clientName}"?',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Excluir',
                                  style: TextStyle(color: AppColors.accentRed),
                                ),
                              ),
                            ],
                          ),
                    ) ??
                    false;

                if (confirmed) {
                  // ✅ Capturar o contexto ANTES da operação assíncrona
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  try {
                    await _service.deleteBudget(budget.id);

                    // ✅ Usar as referências capturadas ao invés do context
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Orçamento de "${budget.clientName}" excluído com sucesso!',
                        ),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  } catch (e) {
                    // ✅ Usar as referências capturadas
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir orçamento: $e'),
                        backgroundColor: AppColors.accentRed,
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
