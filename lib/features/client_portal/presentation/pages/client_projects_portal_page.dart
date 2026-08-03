import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/client_portal/data/client_engineering_document_service.dart';
import 'package:project_granith/features/client_portal/presentation/viewmodels/client_projects_portal_view_model.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshDebounce;
  bool _realtimeStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      unawaited(context.read<ClientProjectsPortalViewModel>().load(auth));
      _startRealtime();
    });
  }

  void _startRealtime() {
    if (_realtimeStarted) return;
    try {
      final client = Supabase.instance.client;
      final channel = client
          .channel('client-engineering-publications')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'engineering_client_document_publications',
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'engineering_client_report_publications',
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'engineering_ecosystem_events',
            callback: (_) => _scheduleRealtimeRefresh(),
          );
      channel.subscribe();
      _realtimeChannel = channel;
      _realtimeStarted = true;
    } on AssertionError {
      // Widget tests can exercise the portal without Supabase initialization.
    }
  }

  void _scheduleRealtimeRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(
        context.read<ClientProjectsPortalViewModel>().load(
          context.read<AuthViewModel>(),
          force: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final channel = _realtimeChannel;
    if (channel != null) {
      try {
        unawaited(Supabase.instance.client.removeChannel(channel));
      } on AssertionError {
        // No initialized client in isolated widget tests.
      }
    }
    super.dispose();
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
                                            approvedMeasurements: viewModel
                                                .approvedMeasurementsForProject(
                                                  project.id,
                                                ),
                                            engineeringDocuments: viewModel
                                                .engineeringDocumentsForProject(
                                                  project.id,
                                                ),
                                            engineeringReports: viewModel
                                                .engineeringReportsForProject(
                                                  project.id,
                                                ),
                                            onOpenEngineeringDocument:
                                                viewModel
                                                    .createEngineeringDocumentUri,
                                            onOpenEngineeringReport:
                                                viewModel
                                                    .createEngineeringReportUri,
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
                    letterSpacing: 0,
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
        _SummaryCard(
          title: 'Medicoes aprovadas',
          value: viewModel.totalApprovedMeasurements.toString(),
          subtitle: 'liberadas para consulta',
          color: AppColors.auraCyan,
        ),
        _SummaryCard(
          title: 'Documentos tecnicos',
          value: viewModel.totalEngineeringDocuments.toString(),
          subtitle: 'revisoes aprovadas e publicadas',
          color: AppColors.accentGold,
        ),
        _SummaryCard(
          title: 'Relatorios tecnicos',
          value: viewModel.totalEngineeringReports.toString(),
          subtitle: 'PDFs aprovados e publicados',
          color: AppColors.accentBlue,
        ),
      ],
    );
  }
}

class _ClientProjectProgressCard extends StatelessWidget {
  const _ClientProjectProgressCard({
    required this.project,
    required this.signedLogs,
    required this.approvedMeasurements,
    required this.engineeringDocuments,
    required this.engineeringReports,
    required this.onOpenEngineeringDocument,
    required this.onOpenEngineeringReport,
  });

  final Project project;
  final List<DailyLogModel> signedLogs;
  final List<ProjectMeasurement> approvedMeasurements;
  final List<ClientEngineeringDocument> engineeringDocuments;
  final List<ClientEngineeringReport> engineeringReports;
  final Future<Uri> Function(ClientEngineeringDocument document)
  onOpenEngineeringDocument;
  final Future<Uri> Function(ClientEngineeringReport report)
  onOpenEngineeringReport;

  @override
  Widget build(BuildContext context) {
    final progress = (project.progressPercentage / 100).clamp(0.0, 1.0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.cardSurface(
        accent: project.status.color,
        emphasized: true,
        radius: 20,
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
          _ClientProjectDetailsSection(
            project: project,
            dateFormat: dateFormat,
          ),
          if (approvedMeasurements.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ClientMeasurementsPreview(measurements: approvedMeasurements),
          ],
          if (engineeringDocuments.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ClientEngineeringDocumentsPreview(
              documents: engineeringDocuments,
              onOpen: onOpenEngineeringDocument,
            ),
          ],
          if (engineeringReports.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ClientEngineeringReportsPreview(
              reports: engineeringReports,
              onOpen: onOpenEngineeringReport,
            ),
          ],
          if (signedLogs.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ClientDailyLogsPreview(logs: signedLogs),
          ],
        ],
      ),
    );
  }
}

class _ClientProjectDetailsSection extends StatelessWidget {
  const _ClientProjectDetailsSection({
    required this.project,
    required this.dateFormat,
  });

  final Project project;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final details = <_ProjectDetail>[
      _ProjectDetail(
        label: 'Cliente',
        value: project.client.trim().isEmpty ? '-' : project.client,
      ),
      _ProjectDetail(
        label: 'Inicio',
        value: dateFormat.format(project.startDate),
      ),
      _ProjectDetail(
        label: 'Previsao',
        value:
            project.endDate != null
                ? dateFormat.format(project.endDate!)
                : 'Sem data definida',
      ),
      _ProjectDetail(
        label: 'Situacao',
        value:
            project.isOverdue
                ? 'Prazo em atraso'
                : project.isCompleted
                ? 'Projeto concluido'
                : 'Dentro do cronograma',
      ),
      _ProjectDetail(label: 'Equipe', value: '${project.teamSize} pessoas'),
      if (project.lastMeasurementAt != null)
        _ProjectDetail(
          label: 'Ultima medicao',
          value: dateFormat.format(project.lastMeasurementAt!),
        ),
      if (project.measurementCount > 0)
        _ProjectDetail(
          label: 'Medicoes registradas',
          value: project.measurementCount.toString(),
        ),
      if (project.tags.isNotEmpty)
        _ProjectDetail(label: 'Tags', value: project.tags.join(', ')),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentBlue,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PortalSectionTitle(
            icon: Icons.apartment_rounded,
            title: 'Detalhes da obra',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                details
                    .map(
                      (detail) => _ProjectMetaCard(
                        label: detail.label,
                        value: detail.value,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProjectDetail {
  final String label;
  final String value;

  const _ProjectDetail({required this.label, required this.value});
}

class _ClientMeasurementsPreview extends StatelessWidget {
  const _ClientMeasurementsPreview({required this.measurements});

  final List<ProjectMeasurement> measurements;

  @override
  Widget build(BuildContext context) {
    final visibleMeasurements = measurements.take(4).toList();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final totalNet = measurements.fold<double>(
      0,
      (total, measurement) => total + measurement.netAmount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.auraCyan,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortalSectionTitle(
            icon: Icons.verified_outlined,
            title: 'Medicoes aprovadas (${measurements.length})',
            trailing: currency.format(totalNet),
          ),
          const SizedBox(height: 12),
          ...visibleMeasurements.map(
            (measurement) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MeasurementLine(
                measurement: measurement,
                dateFormat: dateFormat,
                currency: currency,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementLine extends StatelessWidget {
  const _MeasurementLine({
    required this.measurement,
    required this.dateFormat,
    required this.currency,
  });

  final ProjectMeasurement measurement;
  final DateFormat dateFormat;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardInnerSurface(radius: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: AppDecorations.iconTile(measurement.status.color),
            child: Text(
              measurement.sequence.toString().padLeft(2, '0'),
              style: TextStyle(
                color: measurement.status.color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      measurement.title.trim().isEmpty
                          ? '${measurement.sequence}a medicao'
                          : measurement.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _ClientInfoPill(
                      icon: Icons.event_available_outlined,
                      label: dateFormat.format(measurement.measurementDate),
                    ),
                    _ClientInfoPill(
                      icon: Icons.timeline_rounded,
                      label:
                          '${measurement.clampedAccumulatedPercentage.toStringAsFixed(1)}% acumulado',
                    ),
                  ],
                ),
                if (measurement.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    measurement.notes.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currency.format(measurement.netAmount),
            style: const TextStyle(
              color: AppColors.auraCyan,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientEngineeringDocumentsPreview extends StatelessWidget {
  const _ClientEngineeringDocumentsPreview({
    required this.documents,
    required this.onOpen,
  });

  final List<ClientEngineeringDocument> documents;
  final Future<Uri> Function(ClientEngineeringDocument document) onOpen;

  @override
  Widget build(BuildContext context) {
    final visibleDocuments = documents.take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentGold,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortalSectionTitle(
            icon: Icons.architecture_rounded,
            title: 'Documentos tecnicos publicados (${documents.length})',
          ),
          const SizedBox(height: 12),
          ...visibleDocuments.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openDocument(context, document),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppDecorations.cardInnerSurface(radius: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: AppDecorations.iconTile(
                            document.digitallySigned
                                ? AppColors.accentGreen
                                : AppColors.accentGold,
                          ),
                          child: Icon(
                            document.digitallySigned
                                ? Icons.verified_user_outlined
                                : Icons.picture_as_pdf_outlined,
                            color:
                                document.digitallySigned
                                    ? AppColors.accentGreen
                                    : AppColors.accentGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${document.discipline} · ${document.revisionCode}'
                                '${document.pageCount > 0 ? ' · ${document.pageCount} pag.' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.textSecondary,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    ClientEngineeringDocument document,
  ) async {
    try {
      final uri = await onOpen(document);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('browser_rejected');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel abrir o documento tecnico neste momento.',
          ),
        ),
      );
    }
  }
}

class _ClientEngineeringReportsPreview extends StatelessWidget {
  const _ClientEngineeringReportsPreview({
    required this.reports,
    required this.onOpen,
  });

  final List<ClientEngineeringReport> reports;
  final Future<Uri> Function(ClientEngineeringReport report) onOpen;

  @override
  Widget build(BuildContext context) {
    final visibleReports = reports.take(6).toList();
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentBlue,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortalSectionTitle(
            icon: Icons.analytics_outlined,
            title: 'Relatorios tecnicos publicados (${reports.length})',
          ),
          const SizedBox(height: 12),
          ...visibleReports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openReport(context, report),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppDecorations.cardInnerSurface(radius: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: AppDecorations.iconTile(
                            AppColors.accentBlue,
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Versao ${report.version} · '
                                '${dateFormat.format(report.publishedAt)} · '
                                '${(report.sizeBytes / 1024).toStringAsFixed(0)} KB',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.textSecondary,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReport(
    BuildContext context,
    ClientEngineeringReport report,
  ) async {
    try {
      final uri = await onOpen(report);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('browser_rejected');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel abrir o relatorio tecnico neste momento.',
          ),
        ),
      );
    }
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
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentGreen,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortalSectionTitle(
            icon: Icons.description_outlined,
            title: 'Relatorios liberados (${logs.length})',
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

class _PortalSectionTitle extends StatelessWidget {
  const _PortalSectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Text(
            trailing!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.auraCyan,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
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
      decoration: AppDecorations.cardInnerSurface(radius: 14),
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
      decoration: AppDecorations.statCardSurface(color, radius: 18),
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
      decoration: AppDecorations.cardSurface(
        accent: color,
        elevated: false,
        radius: 18,
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
