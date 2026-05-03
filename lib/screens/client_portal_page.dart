import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:provider/provider.dart';

class ClientPortalPage extends StatefulWidget {
  const ClientPortalPage({super.key});

  @override
  State<ClientPortalPage> createState() => _ClientPortalPageState();
}

class _ClientPortalPageState extends State<ClientPortalPage> {
  final ServiceProjetos _projectService = ServiceProjetos();
  final ServiceOrcamentos _budgetService = ServiceOrcamentos();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _isLoading = true;
  String? _selectedAccountId;
  String _lastLoadSignature = '';
  List<ClientAccount> _accounts = [];
  List<Project> _projects = [];
  List<Budget> _budgets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPortalData();
  }

  Future<void> _loadPortalData({bool force = false}) async {
    final auth = context.read<AuthViewModel>();
    final accounts = auth.ownedClientAccounts;
    final selectedId =
        _selectedAccountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
    final signature =
        '${accounts.map((item) => item.id).join(',')}|$selectedId|${auth.user?.email ?? ''}';

    if (!force && signature == _lastLoadSignature && !_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _accounts = accounts;
      _selectedAccountId = selectedId;
      _lastLoadSignature = signature;
    });

    if (selectedId == null) {
      if (!mounted) return;
      setState(() {
        _projects = [];
        _budgets = [];
        _isLoading = false;
      });
      return;
    }

    final results = await Future.wait([
      _projectService.getProjectsByClientAccount(selectedId),
      _budgetService.fetchBudgets(clientAccountId: selectedId),
    ]);

    if (!mounted) return;
    setState(() {
      _projects = results[0] as List<Project>;
      _budgets = results[1] as List<Budget>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final systemSettings = context.watch<SystemSettingsViewModel>().settings;
    final activeAccount = _resolveActiveAccount();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accentBlue),
              )
            : RefreshIndicator(
                onRefresh: () => _loadPortalData(force: true),
                child: GranithPageBackground(
                  scrollable: true,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GranithReveal(
                        delay: const Duration(milliseconds: 40),
                        child: _buildHeroSection(auth, activeAccount, systemSettings),
                      ),
                      const SizedBox(height: 20),
                      if (activeAccount == null)
                        const GranithReveal(
                          delay: Duration(milliseconds: 100),
                          child: _ClientEmptyState(),
                        )
                      else ...[
                        GranithReveal(
                          delay: const Duration(milliseconds: 110),
                          child: _buildMetricsStrip(systemSettings),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 1080;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: GranithReveal(
                                      delay: const Duration(milliseconds: 180),
                                      child: _buildProjectsSection(
                                        systemSettings,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        GranithReveal(
                                          delay: const Duration(milliseconds: 240),
                                          child: systemSettings.clientPortalShowBudgets
                                              ? _buildBudgetsSection(
                                                  systemSettings,
                                                  compact: true,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        if (systemSettings.clientPortalShowBudgets)
                                          const SizedBox(height: 18),
                                        GranithReveal(
                                          delay: const Duration(milliseconds: 320),
                                          child: _buildRelationshipSection(
                                            activeAccount,
                                            systemSettings,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                GranithReveal(
                                  delay: const Duration(milliseconds: 180),
                                  child: _buildProjectsSection(
                                    systemSettings,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                GranithReveal(
                                  delay: const Duration(milliseconds: 240),
                                  child: systemSettings.clientPortalShowBudgets
                                      ? _buildBudgetsSection(systemSettings)
                                      : const SizedBox.shrink(),
                                ),
                                if (systemSettings.clientPortalShowBudgets)
                                  const SizedBox(height: 18),
                                GranithReveal(
                                  delay: const Duration(milliseconds: 320),
                                  child: _buildRelationshipSection(
                                    activeAccount,
                                    systemSettings,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  ClientAccount? _resolveActiveAccount() {
    if (_accounts.isEmpty) {
      return null;
    }

    for (final account in _accounts) {
      if (account.id == _selectedAccountId) {
        return account;
      }
    }

    return _accounts.first;
  }

  Widget _buildHeroSection(
    AuthViewModel auth,
    ClientAccount? activeAccount,
    SystemSettings systemSettings,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.18),
            AppColors.surfaceDark.withValues(alpha: 0.82),
            AppColors.accentGold.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.22),
        ),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  '${systemSettings.workspaceName.toUpperCase()} CLIENT SURFACE',
                  style: const TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                activeAccount?.name ?? 'Portal do Cliente',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                activeAccount != null
                    ? systemSettings.clientPortalWelcomeMessage.replaceAll(
                        '{cliente}',
                        activeAccount.name,
                      )
                    : 'Esta conta ainda nao possui empresa cliente vinculada ao portal.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    icon: Icons.alternate_email_rounded,
                    label: auth.user?.email ?? '-',
                  ),
                  if (activeAccount?.contactEmail.isNotEmpty == true)
                    _InfoPill(
                      icon: Icons.markunread_outlined,
                      label: activeAccount!.contactEmail,
                    ),
                  if (activeAccount?.contactPhone.isNotEmpty == true)
                    _InfoPill(
                      icon: Icons.phone_in_talk_outlined,
                      label: activeAccount!.contactPhone,
                    ),
                  if (systemSettings.supportEmail.trim().isNotEmpty)
                    _InfoPill(
                      icon: Icons.support_agent_rounded,
                      label: systemSettings.supportEmail,
                    ),
                  if (systemSettings.supportPhone.trim().isNotEmpty)
                    _InfoPill(
                      icon: Icons.headset_mic_outlined,
                      label: systemSettings.supportPhone,
                    ),
                ],
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (_accounts.length > 1)
                SizedBox(
                  width: isWide ? 280 : double.infinity,
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
                      await _loadPortalData(force: true);
                    },
                  ),
                ),
              if (_accounts.length > 1) const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 18),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: info),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricsStrip(SystemSettings systemSettings) {
    final activeProjects =
        _projects.where((project) => project.status != ProjectStatus.completed).length;
    final approvedBudgets =
        _budgets.where((budget) => budget.status == BudgetStatus.approved).length;
    final pendingBudgets =
        _budgets.where((budget) => budget.status == BudgetStatus.pending).length;
    final completedProjects =
        _projects.where((project) => project.status == ProjectStatus.completed).length;
    final totalContracted = _projects.fold<double>(
      0,
      (sum, item) => sum + item.budget,
    );
    final totalApplied = _projects.fold<double>(
      0,
      (sum, item) => sum + item.currentCost,
    );
    final avgProgress = _projects.isEmpty
        ? 0.0
        : _projects.fold<double>(0, (sum, item) => sum + item.progressPercentage) /
            _projects.length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          title: 'Projetos ativos',
          value: activeProjects.toString(),
          subtitle: '${_projects.length} vinculados',
          color: AppColors.accentBlue,
        ),
        _MetricCard(
          title: 'Progresso medio',
          value: '${avgProgress.toStringAsFixed(0)}%',
          subtitle: 'execucao consolidada',
          color: AppColors.auraCyan,
        ),
        _MetricCard(
          title: systemSettings.clientPortalShowBudgets
              ? 'Propostas aprovadas'
              : 'Projetos concluidos',
          value: systemSettings.clientPortalShowBudgets
              ? approvedBudgets.toString()
              : completedProjects.toString(),
          subtitle: systemSettings.clientPortalShowBudgets
              ? '$pendingBudgets pendentes'
              : 'historico consolidado',
          color: AppColors.accentGold,
        ),
        if (systemSettings.clientPortalShowBudgetValues)
          _MetricCard(
            title: 'Valor contratado',
            value: _currency.format(totalContracted),
            subtitle: 'visao total do portfolio',
            color: AppColors.accentGreen,
          ),
        if (systemSettings.clientPortalShowCurrentCosts)
          _MetricCard(
            title: 'Custo aplicado',
            value: _currency.format(totalApplied),
            subtitle: 'estimativa baseada no ERP',
            color: AppColors.duskBlue,
          ),
      ],
    );
  }

  Widget _buildProjectsSection(SystemSettings systemSettings) {
    return _SectionCard(
      title: 'Projetos vinculados',
      subtitle: 'Acompanhamento das obras relacionadas a esta conta cliente.',
      child: _projects.isEmpty
          ? const _SectionEmptyCopy(
              title: 'Nenhum projeto vinculado',
              message:
                  'Quando um projeto for associado a esta conta de cliente, ele aparecera aqui com status, avancos e indicadores liberados pelo ERP.',
            )
          : Column(
              children: _projects
                  .map(
                    (project) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GranithPressable(
                        child: _ProjectSpotlightCard(
                          project: project,
                          currency: _currency,
                          dateFormat: _dateFormat,
                          showBudgetValues:
                              systemSettings.clientPortalShowBudgetValues,
                          showCurrentCosts:
                              systemSettings.clientPortalShowCurrentCosts,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildBudgetsSection(
    SystemSettings systemSettings, {
    bool compact = false,
  }) {
    final content = _budgets.isEmpty
        ? const _SectionEmptyCopy(
            title: 'Nenhum orcamento vinculado',
            message:
                'As propostas comerciais associadas a esta conta aparecerao aqui para consulta do cliente.',
          )
        : Column(
            children: _budgets
                .map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GranithPressable(
                      child: _BudgetOverviewTile(
                        budget: budget,
                        currency: _currency,
                        dateFormat: _dateFormat,
                        showBudgetValue:
                            systemSettings.clientPortalShowBudgetValues,
                      ),
                    ),
                  ),
                )
                .toList(),
          );

    return _SectionCard(
      title: compact ? 'Propostas e orcamentos' : 'Orcamentos e propostas',
      subtitle: systemSettings.clientPortalShowBudgetValues
          ? 'Status comercial e valores associados ao relacionamento.'
          : 'Status comercial, validade e andamento das propostas associadas.',
      child: content,
    );
  }

  Widget _buildRelationshipSection(
    ClientAccount account,
    SystemSettings systemSettings,
  ) {
    final activeProject = _projects.cast<Project?>().firstWhere(
          (project) => project?.status == ProjectStatus.inProgress,
          orElse: () => _projects.isNotEmpty ? _projects.first : null,
        );
    final latestBudget = _budgets.isNotEmpty ? _budgets.first : null;

    return _SectionCard(
      title: 'Visao do relacionamento',
      subtitle: 'Leituras executivas para o cliente entender a carteira atual.',
      child: Column(
        children: [
          _RelationshipFact(
            icon: Icons.apartment_rounded,
            title: 'Conta principal do portal',
            description: account.name,
            accent: AppColors.accentBlue,
          ),
          const SizedBox(height: 12),
          _RelationshipFact(
            icon: Icons.engineering_outlined,
            title: 'Projeto em destaque',
            description: activeProject != null
                ? '${activeProject.name} • ${activeProject.status.displayName}'
                : 'Nenhum projeto em execucao no momento',
            accent: AppColors.accentGold,
          ),
          const SizedBox(height: 12),
          _RelationshipFact(
            icon: systemSettings.clientPortalShowBudgets
                ? Icons.request_quote_outlined
                : Icons.visibility_off_outlined,
            title: systemSettings.clientPortalShowBudgets
                ? 'Ultima movimentacao comercial'
                : 'Postura comercial da conta',
            description: systemSettings.clientPortalShowBudgets
                ? latestBudget != null
                    ? '${latestBudget.projectName} • ${latestBudget.status.displayName}'
                    : 'Sem orcamentos associados ainda'
                : 'Os detalhes comerciais desta conta foram mantidos em modo essencial pelo ERP.',
            accent: AppColors.auraCyan,
          ),
          if (systemSettings.supportEmail.trim().isNotEmpty ||
              systemSettings.supportPhone.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _RelationshipFact(
              icon: Icons.support_agent_rounded,
              title: 'Canal de relacionamento',
              description: systemSettings.supportPhone.trim().isNotEmpty
                  ? systemSettings.supportPhone
                  : systemSettings.supportEmail,
              accent: AppColors.accentBlue,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: AppColors.glowShadows(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.68),
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
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ProjectSpotlightCard extends StatelessWidget {
  final Project project;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final bool showBudgetValues;
  final bool showCurrentCosts;

  const _ProjectSpotlightCard({
    required this.project,
    required this.currency,
    required this.dateFormat,
    required this.showBudgetValues,
    required this.showCurrentCosts,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDays = project.daysUntilDeadline;
    final deadlineLabel = project.endDate != null
        ? 'Prazo: ${dateFormat.format(project.endDate!.toLocal())}'
        : 'Prazo em definicao';
    final progressValue = (project.progressPercentage / 100).clamp(0.0, 1.0);
    final spotlights = <Widget>[
      if (showBudgetValues)
        _NumericSpotlight(
          label: 'Valor contratado',
          value: currency.format(project.budget),
          accent: AppColors.accentBlue,
        ),
      if (showCurrentCosts)
        _NumericSpotlight(
          label: 'Custo aplicado',
          value: currency.format(project.currentCost),
          accent: project.isOverBudget
              ? AppColors.accentRed
              : AppColors.accentGreen,
        ),
      _NumericSpotlight(
        label: 'Progresso estimado',
        value: project.formattedProgress,
        accent: AppColors.accentGold,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: project.status.color.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: project.status.color.withValues(alpha: 0.14),
                child: Icon(project.status.icon, color: project.status.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.client,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: project.status.displayName,
                color: project.status.color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            project.description.isNotEmpty
                ? project.description
                : 'Projeto sem descricao operacional detalhada no momento.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InlineFact(
                icon: Icons.place_outlined,
                label: project.location.isNotEmpty ? project.location : 'Local nao informado',
              ),
              _InlineFact(icon: Icons.event_outlined, label: deadlineLabel),
              _InlineFact(
                icon: Icons.schedule_rounded,
                label: remainingDays == null
                    ? 'Sem prazo final'
                    : remainingDays == 0
                        ? 'Prazo atingido'
                        : '$remainingDays dias restantes',
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalSpacing = (spotlights.length - 1) * 12;
              final tileWidth = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - totalSpacing) / spotlights.length
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in spotlights)
                    SizedBox(width: tileWidth, child: tile),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progressValue,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetOverviewTile extends StatelessWidget {
  final Budget budget;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final bool showBudgetValue;

  const _BudgetOverviewTile({
    required this.budget,
    required this.currency,
    required this.dateFormat,
    required this.showBudgetValue,
  });

  @override
  Widget build(BuildContext context) {
    final expiration = budget.expirationDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: budget.status.color.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: budget.status.color.withValues(alpha: 0.14),
                child: Icon(budget.status.icon, color: budget.status.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.projectName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      budget.clientName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: budget.status.displayName,
                color: budget.status.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InlineFact(
                icon: Icons.payments_outlined,
                label: showBudgetValue
                    ? currency.format(budget.totalValue)
                    : 'Valor sob consulta',
              ),
              _InlineFact(
                icon: Icons.event_available_outlined,
                label: expiration != null
                    ? 'Valido ate ${dateFormat.format(expiration.toLocal())}'
                    : 'Sem validade definida',
              ),
            ],
          ),
          if (budget.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              budget.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelationshipFact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const _RelationshipFact({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InlineFact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineFact({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumericSpotlight extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _NumericSpotlight({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyCopy extends StatelessWidget {
  final String title;
  final String message;

  const _SectionEmptyCopy({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientEmptyState extends StatelessWidget {
  const _ClientEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.65),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nenhuma conta cliente vinculada',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Para este login acessar o portal do cliente, e preciso cadastrar uma conta em "Permissoes e Clientes" usando o mesmo e-mail do usuario e vincular projetos/orcamentos a essa conta.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
