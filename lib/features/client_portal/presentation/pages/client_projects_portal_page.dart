import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/client_portal/presentation/viewmodels/client_projects_portal_view_model.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:provider/provider.dart';

class ClientProjectsPortalPage extends StatelessWidget {
  const ClientProjectsPortalPage({
    super.key,
    ClientProjectsPortalViewModel? viewModel,
  }) : _viewModel = viewModel;

  final ClientProjectsPortalViewModel? _viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _viewModel ?? ClientProjectsPortalViewModel(),
      child: const _ClientProjectsPortalView(),
    );
  }
}

class _ClientProjectsPortalView extends StatefulWidget {
  const _ClientProjectsPortalView();

  @override
  State<_ClientProjectsPortalView> createState() =>
      _ClientProjectsPortalViewState();
}

class _ClientProjectsPortalViewState extends State<_ClientProjectsPortalView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientProjectsPortalViewModel>().load(
        context.read<AuthViewModel>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final viewModel = context.watch<ClientProjectsPortalViewModel>();
    final activeAccount = viewModel.activeAccount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child:
            viewModel.isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                )
                : RefreshIndicator(
                  onRefresh: () => viewModel.load(auth, force: true),
                  child: GranithPageBackground(
                    scrollable: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ClientProjectsHero(
                          accountName:
                              activeAccount?.name ?? 'Portal do Cliente',
                          userEmail: auth.user?.email ?? '-',
                          hasMultipleAccounts: viewModel.accounts.length > 1,
                          selectedAccountId: viewModel.selectedAccountId,
                          accountItems:
                              viewModel.accounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account.id,
                                      child: Text(account.name),
                                    ),
                                  )
                                  .toList(),
                          onAccountChanged: (value) async {
                            if (value == null) return;
                            await context
                                .read<ClientProjectsPortalViewModel>()
                                .selectAccount(value, auth);
                          },
                          onLogout: auth.logout,
                        ),
                        const SizedBox(height: 20),
                        if (viewModel.errorMessage != null) ...[
                          _PortalMessageCard(
                            title: 'Falha ao carregar projetos',
                            message: viewModel.errorMessage!,
                            color: AppColors.accentRed,
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (activeAccount == null)
                          const _EmptyClientProjectsState()
                        else ...[
                          _ProjectsSummaryStrip(viewModel: viewModel),
                          const SizedBox(height: 20),
                          if (viewModel.projects.isEmpty)
                            const _PortalMessageCard(
                              title: 'Nenhum projeto vinculado',
                              message:
                                  'Esta conta ainda nao possui projetos vinculados para consulta.',
                              color: AppColors.accentGold,
                            )
                          else
                            Column(
                              children:
                                  viewModel.projects
                                      .map(
                                        (project) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: _ClientProjectProgressCard(
                                            project: project,
                                            signedLogs: viewModel
                                                .signedLogsForProject(
                                                  project.id,
                                                ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

class _ClientProjectsHero extends StatelessWidget {
  const _ClientProjectsHero({
    required this.accountName,
    required this.userEmail,
    required this.hasMultipleAccounts,
    required this.selectedAccountId,
    required this.accountItems,
    required this.onAccountChanged,
    required this.onLogout,
  });

  final String accountName;
  final String userEmail;
  final bool hasMultipleAccounts;
  final String? selectedAccountId;
  final List<DropdownMenuItem<String>> accountItems;
  final Future<void> Function(String?) onAccountChanged;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.16),
            AppColors.surfaceDark.withValues(alpha: 0.86),
            AppColors.auraCyan.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.22)),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;

          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.24),
                  ),
                ),
                child: const Text(
                  'ACOMPANHAMENTO DE OBRAS',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                accountName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Consulte apenas os projetos vinculados a sua conta e acompanhe o andamento de cada obra em uma leitura direta.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              _ClientInfoPill(
                icon: Icons.alternate_email_rounded,
                label: userEmail,
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasMultipleAccounts)
                SizedBox(
                  width: isWide ? 280 : double.infinity,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Conta do cliente',
                    ),
                    items: accountItems,
                    onChanged: (value) {
                      onAccountChanged(value);
                    },
                  ),
                ),
              if (hasMultipleAccounts) const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ProjectsSummaryStrip extends StatelessWidget {
  const _ProjectsSummaryStrip({required this.viewModel});

  final ClientProjectsPortalViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Projetos',
          value: viewModel.totalProjects.toString(),
          subtitle: 'vinculados a esta conta',
          color: AppColors.accentBlue,
        ),
        _SummaryCard(
          title: 'Em andamento',
          value: viewModel.inProgressProjects.toString(),
          subtitle: 'obras em execucao',
          color: AppColors.accentGold,
        ),
        _SummaryCard(
          title: 'Concluidos',
          value: viewModel.completedProjects.toString(),
          subtitle: 'entregas finalizadas',
          color: AppColors.accentGreen,
        ),
        _SummaryCard(
          title: 'Avanco medio',
          value: '${viewModel.averageProgress.toStringAsFixed(0)}%',
          subtitle: 'media geral de progresso',
          color: AppColors.auraCyan,
        ),
        _SummaryCard(
          title: 'Diarios liberados',
          value: viewModel.totalSignedDailyLogs.toString(),
          subtitle: 'relatorios assinados',
          color: AppColors.accentGreen,
        ),
      ],
    );
  }
}

class _ClientProjectProgressCard extends StatelessWidget {
  const _ClientProjectProgressCard({
    required this.project,
    required this.signedLogs,
  });

  final Project project;
  final List<DailyLogModel> signedLogs;

  @override
  Widget build(BuildContext context) {
    final progress = (project.progressPercentage / 100).clamp(0.0, 1.0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: project.status.color.withValues(alpha: 0.24)),
        boxShadow: AppColors.glowShadows(project.status.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: project.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: project.status.color.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      project.status.icon,
                      size: 16,
                      color: project.status.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      project.status.displayName,
                      style: TextStyle(
                        color: project.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (project.location.trim().isNotEmpty)
                _ClientInfoPill(
                  icon: Icons.location_on_outlined,
                  label: project.location,
                ),
              _ClientInfoPill(
                icon: Icons.groups_rounded,
                label: '${project.teamSize} pessoas na equipe',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            project.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (project.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: AppColors.surfaceDark.withValues(
                      alpha: 0.70,
                    ),
                    valueColor: AlwaysStoppedAnimation(project.status.color),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                project.formattedProgress,
                style: TextStyle(
                  color: project.status.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ProjectMetaCard(
                label: 'Inicio',
                value: dateFormat.format(project.startDate),
              ),
              _ProjectMetaCard(
                label: 'Previsao',
                value:
                    project.endDate != null
                        ? dateFormat.format(project.endDate!)
                        : 'Sem data definida',
              ),
              _ProjectMetaCard(
                label: 'Situacao',
                value:
                    project.isOverdue
                        ? 'Prazo em atraso'
                        : project.isCompleted
                        ? 'Projeto concluido'
                        : 'Dentro do cronograma',
              ),
            ],
          ),
          if (signedLogs.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ClientDailyLogsPreview(logs: signedLogs),
          ],
        ],
      ),
    );
  }
}

class _ClientDailyLogsPreview extends StatelessWidget {
  const _ClientDailyLogsPreview({required this.logs});

  final List<DailyLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final visibleLogs = logs.take(3).toList();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.accentGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diarios assinados (${logs.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...visibleLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(log.date),
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      log.activitiesDescription.trim().isEmpty
                          ? 'Relatorio liberado para consulta.'
                          : log.activitiesDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetaCard extends StatelessWidget {
  const _ProjectMetaCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      width: width < ResponsiveLayout.compact ? double.infinity : 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      width: width < ResponsiveLayout.compact ? double.infinity : 230,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PortalMessageCard extends StatelessWidget {
  const _PortalMessageCard({
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoPill extends StatelessWidget {
  const _ClientInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyClientProjectsState extends StatelessWidget {
  const _EmptyClientProjectsState();

  @override
  Widget build(BuildContext context) {
    return const _PortalMessageCard(
      title: 'Conta sem vinculacao',
      message:
          'Este acesso ainda nao possui uma conta de cliente vinculada. Cadastre ou associe a conta no painel administrativo para liberar a consulta de projetos.',
      color: AppColors.accentGold,
    );
  }
}
