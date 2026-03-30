import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/budgets/budget_card.dart';
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

  // ─── IDs de orçamentos sendo aprovados (evita double-tap) ─────────────────
  final Set<String> _approvingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _forceCheckExpiredBudgets();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AÇÕES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _forceCheckExpiredBudgets() async {
    setState(() => _isUpdatingExpired = true);
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
      if (mounted) setState(() => _isUpdatingExpired = false);
    }
  }

  /// Regra #21 — Aprova orçamento e cria projeto automaticamente.
  Future<void> _approveBudget(Budget budget) async {
    // Guarda referências antes do await
    final messenger = ScaffoldMessenger.of(context);

    // Confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 20),
          SizedBox(width: 10),
          Text('Aprovar orçamento?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ao aprovar "${budget.projectName}", um projeto será criado '
              'automaticamente em Planejamento.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppColors.accentGold, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cliente: ${budget.clientName}\n'
                    'Valor: R\$ ${budget.totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.accentGold, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Aprovar e criar projeto',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Marca como em progresso (previne double-tap)
    setState(() => _approvingIds.add(budget.id));

    try {
      await _service.approveBudget(budget);

      messenger.showSnackBar(SnackBar(
        content: const Text('Orçamento aprovado! Projeto criado em Planejamento.'),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao aprovar orçamento: $e'),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _approvingIds.remove(budget.id));
    }
  }

  Future<void> _rejectBudget(Budget budget) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: AppColors.accentRed, size: 20),
          SizedBox(width: 10),
          Text('Rejeitar orçamento?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        ]),
        content: Text(
          'Tem certeza que deseja rejeitar o orçamento de "${budget.clientName}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeitar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.rejectBudget(budget.id);
      messenger.showSnackBar(const SnackBar(
        content: Text('Orçamento rejeitado.'),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao rejeitar: $e'),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('Confirmar exclusão',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              'Tem certeza que deseja excluir o orçamento de "${budget.clientName}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir',
                    style: TextStyle(color: AppColors.accentRed)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _service.deleteBudget(budget.id);
      messenger.showSnackBar(SnackBar(
        content:
            Text('Orçamento de "${budget.clientName}" excluído com sucesso!'),
        backgroundColor: AppColors.accentGreen,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao excluir orçamento: $e'),
        backgroundColor: AppColors.accentRed,
      ));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

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
          FloatingActionButton.small(
            onPressed: _isUpdatingExpired ? null : _forceCheckExpiredBudgets,
            backgroundColor: AppColors.accentBlue,
            foregroundColor: AppColors.textPrimary,
            heroTag: 'refresh',
            child: _isUpdatingExpired
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                    ),
                  )
                : const Icon(Icons.refresh, size: 18),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => BudgetFormDialog(
                  onSave: (budget) async => _service.addBudget(budget),
                ),
              );
            },
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
            heroTag: 'add',
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
                  color: AppColors.accentGold.withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.attach_money_outlined,
                color: AppColors.accentGold, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orçamentos',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5)),
                SizedBox(height: 4),
                Text('Gerencie seus orçamentos e propostas',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          if (_isUpdatingExpired)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.accentBlue.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('Verificando...',
                      style: TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
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
              children: BudgetStatus.values.map((status) {
                return FilterChip(
                  selected: _filterStatus == status,
                  onSelected: (_) => setState(() {
                    _filterStatus = status;
                    _isFiltering = true;
                  }),
                  label: Text(status.displayName),
                  avatar: Icon(status.icon, size: 16),
                  backgroundColor: AppColors.secondaryDark,
                  selectedColor: status.color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _filterStatus == status
                        ? status.color
                        : AppColors.textSecondary,
                  ),
                  checkmarkColor: status.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          if (_isFiltering)
            TextButton.icon(
              onPressed: () => setState(() {
                _isFiltering = false;
                _filterStatus = BudgetStatus.pending;
              }),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Limpar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar orçamentos...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
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
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentGold, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBudgetList() {
    return StreamBuilder<List<Budget>>(
      stream: _isFiltering
          ? _service.getBudgetsByStatus(_filterStatus)
          : _service.getBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: AppColors.accentRed.withOpacity(0.7)),
                const SizedBox(height: 16),
                const Text('Erro ao carregar orçamentos',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${snapshot.error}',
                    style:
                        const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
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
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                ),
                SizedBox(height: 16),
                Text('Carregando orçamentos...',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final budgets = snapshot.data ?? [];
        final searchTerm = _searchController.text.toLowerCase();
        final filtered = searchTerm.isEmpty
            ? budgets
            : budgets
                .where((b) =>
                    b.clientName.toLowerCase().contains(searchTerm) ||
                    b.projectName.toLowerCase().contains(searchTerm))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money_outlined,
                    size: 64,
                    color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Nenhum orçamento encontrado',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  _isFiltering || searchTerm.isNotEmpty
                      ? 'Tente alterar os filtros ou buscar por outros termos'
                      : 'Clique no botão + para criar seu primeiro orçamento',
                  style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.7),
                      fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final budget = filtered[index];
            final isApproving = _approvingIds.contains(budget.id);

            return BudgetCard(
              budget: budget,
              onTap: () => showDialog(
                context: context,
                builder: (_) => BudgetFormDialog(
                  budget: budget,
                  onSave: (updated) async => _service.updateBudget(updated),
                ),
              ),
              onDelete: () => _deleteBudget(budget),
              // ── Novos callbacks de aprovação ─────────────────────────────
              // Passe estes dois para o BudgetCard e exiba os botões apenas
              // quando budget.status == BudgetStatus.pending
              onApprove: budget.status == BudgetStatus.pending && !isApproving
                  ? () => _approveBudget(budget)
                  : null,
              onReject: budget.status == BudgetStatus.pending && !isApproving
                  ? () => _rejectBudget(budget)
                  : null,
              isApproving: isApproving,
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