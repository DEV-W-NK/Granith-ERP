import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class ClientPortalPage extends StatefulWidget {
  const ClientPortalPage({super.key});

  @override
  State<ClientPortalPage> createState() => _ClientPortalPageState();
}

class _ClientPortalPageState extends State<ClientPortalPage> {
  final ServiceProjetos _projectService = ServiceProjetos();
  final ServiceOrcamentos _budgetService = ServiceOrcamentos();

  bool _isLoading = true;
  String? _selectedAccountId;
  List<ClientAccount> _accounts = [];
  List<Project> _projects = [];
  List<Budget> _budgets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPortalData();
  }

  Future<void> _loadPortalData() async {
    final auth = context.read<AuthViewModel>();
    final accounts = auth.ownedClientAccounts;
    if (_accounts == accounts && !_isLoading) return;

    setState(() {
      _isLoading = true;
      _accounts = accounts;
      _selectedAccountId =
          _selectedAccountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
    });

    if (_selectedAccountId == null) {
      setState(() {
        _projects = [];
        _budgets = [];
        _isLoading = false;
      });
      return;
    }

    final projects = await _projectService.getProjectsByClientAccount(
      _selectedAccountId!,
    );
    final budgets = await _budgetService.fetchBudgets(
      clientAccountId: _selectedAccountId,
    );

    if (!mounted) return;
    setState(() {
      _projects = projects;
      _budgets = budgets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final activeAccount = _accounts.cast<ClientAccount?>().firstWhere(
          (account) => account?.id == _selectedAccountId,
          orElse: () => _accounts.isNotEmpty ? _accounts.first : null,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              )
            : RefreshIndicator(
                onRefresh: _loadPortalData,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portal do Cliente',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activeAccount != null
                                    ? 'Acompanhamento exclusivo das obras vinculadas a ${activeAccount.name}.'
                                    : 'Nenhuma conta de cliente vinculada a este acesso.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => auth.logout(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sair'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_accounts.length > 1)
                      SizedBox(
                        width: 320,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Conta do cliente',
                          ),
                          items: _accounts
                              .map(
                                (account) => DropdownMenuItem(
                                  value: account.id,
                                  child: Text(account.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() => _selectedAccountId = value);
                            await _loadPortalData();
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _MetricCard(
                          title: 'Projetos ativos',
                          value: _projects
                              .where((project) => project.status != ProjectStatus.completed)
                              .length
                              .toString(),
                          color: AppColors.accentBlue,
                        ),
                        _MetricCard(
                          title: 'Orcamentos',
                          value: _budgets.length.toString(),
                          color: AppColors.accentGold,
                        ),
                        _MetricCard(
                          title: 'Valor total contratado',
                          value:
                              'R\$ ${_projects.fold<double>(0, (sum, item) => sum + item.budget).toStringAsFixed(0)}',
                          color: AppColors.accentGreen,
                        ),
                        _MetricCard(
                          title: 'Custo aplicado',
                          value:
                              'R\$ ${_projects.fold<double>(0, (sum, item) => sum + item.currentCost).toStringAsFixed(0)}',
                          color: AppColors.auraCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'Projetos vinculados',
                      child: _projects.isEmpty
                          ? const Text(
                              'Nenhum projeto vinculado a esta conta.',
                              style: TextStyle(color: AppColors.textSecondary),
                            )
                          : Column(
                              children: _projects
                                  .map(
                                    (project) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: project.status.color.withValues(alpha: 0.16),
                                        child: Icon(
                                          project.status.icon,
                                          color: project.status.color,
                                        ),
                                      ),
                                      title: Text(
                                        project.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Status: ${project.status.displayName} • Progresso: ${project.formattedProgress}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      trailing: Text(
                                        project.formattedBudget,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Orcamentos e propostas',
                      child: _budgets.isEmpty
                          ? const Text(
                              'Nenhum orcamento vinculado a esta conta.',
                              style: TextStyle(color: AppColors.textSecondary),
                            )
                          : Column(
                              children: _budgets
                                  .map(
                                    (budget) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: budget.status.color.withValues(alpha: 0.16),
                                        child: Icon(
                                          budget.status.icon,
                                          color: budget.status.color,
                                        ),
                                      ),
                                      title: Text(
                                        budget.projectName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Status: ${budget.status.displayName}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      trailing: Text(
                                        'R\$ ${budget.totalValue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: AppColors.glowShadows(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.65),
        ),
        boxShadow: AppColors.glowShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
