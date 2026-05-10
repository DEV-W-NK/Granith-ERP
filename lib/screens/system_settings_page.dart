import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/screens/subscription_page.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/utils/seeder.dart';
import 'package:project_granith/widgets/TransparencyBanner.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';
import 'package:provider/provider.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final TextEditingController _workspaceNameController =
      TextEditingController();
  final TextEditingController _workspaceTaglineController =
      TextEditingController();
  final TextEditingController _dashboardTitleController =
      TextEditingController();
  final TextEditingController _dashboardSubtitleController =
      TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportPhoneController = TextEditingController();
  final TextEditingController _clientPortalWelcomeController =
      TextEditingController();
  final TextEditingController _timeClockInpiController =
      TextEditingController();
  final TextEditingController _timeClockEmployerNameController =
      TextEditingController();
  final TextEditingController _timeClockEmployerDocumentController =
      TextEditingController();
  final TextEditingController _timeClockTimezoneController =
      TextEditingController();

  bool _aiAssistantPreviewEnabled = true;
  bool _compactNavigation = false;
  bool _clientPortalShowBudgets = true;
  bool _clientPortalShowBudgetValues = true;
  bool _clientPortalShowCurrentCosts = true;
  bool _timeClockEnabled = true;
  bool _timeClockGeofenceRequired = true;
  bool _timeClockStoreRejectedAttempts = true;
  bool _isSeeding = false;

  String _boundSnapshot = '';

  @override
  void dispose() {
    _workspaceNameController.dispose();
    _workspaceTaglineController.dispose();
    _dashboardTitleController.dispose();
    _dashboardSubtitleController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _clientPortalWelcomeController.dispose();
    _timeClockInpiController.dispose();
    _timeClockEmployerNameController.dispose();
    _timeClockEmployerDocumentController.dispose();
    _timeClockTimezoneController.dispose();
    super.dispose();
  }

  void _bindFromSettings(SystemSettings settings) {
    final snapshot = [
      settings.workspaceName,
      settings.workspaceTagline,
      settings.dashboardGreetingTitle,
      settings.dashboardGreetingSubtitle,
      settings.supportEmail,
      settings.supportPhone,
      settings.clientPortalWelcomeMessage,
      settings.aiAssistantPreviewEnabled,
      settings.compactNavigation,
      settings.clientPortalShowBudgets,
      settings.clientPortalShowBudgetValues,
      settings.clientPortalShowCurrentCosts,
      settings.timeClockEnabled,
      settings.timeClockGeofenceRequired,
      settings.timeClockStoreRejectedAttempts,
      settings.timeClockInpiRegistrationNumber,
      settings.timeClockEmployerName,
      settings.timeClockEmployerDocument,
      settings.timeClockTimezone,
    ].join('|');

    if (_boundSnapshot == snapshot) {
      return;
    }

    _boundSnapshot = snapshot;
    _workspaceNameController.text = settings.workspaceName;
    _workspaceTaglineController.text = settings.workspaceTagline;
    _dashboardTitleController.text = settings.dashboardGreetingTitle;
    _dashboardSubtitleController.text = settings.dashboardGreetingSubtitle;
    _supportEmailController.text = settings.supportEmail;
    _supportPhoneController.text = settings.supportPhone;
    _clientPortalWelcomeController.text = settings.clientPortalWelcomeMessage;
    _aiAssistantPreviewEnabled = settings.aiAssistantPreviewEnabled;
    _compactNavigation = settings.compactNavigation;
    _clientPortalShowBudgets = settings.clientPortalShowBudgets;
    _clientPortalShowBudgetValues = settings.clientPortalShowBudgetValues;
    _clientPortalShowCurrentCosts = settings.clientPortalShowCurrentCosts;
    _timeClockEnabled = settings.timeClockEnabled;
    _timeClockGeofenceRequired = settings.timeClockGeofenceRequired;
    _timeClockStoreRejectedAttempts = settings.timeClockStoreRejectedAttempts;
    _timeClockInpiController.text = settings.timeClockInpiRegistrationNumber;
    _timeClockEmployerNameController.text = settings.timeClockEmployerName;
    _timeClockEmployerDocumentController.text =
        settings.timeClockEmployerDocument;
    _timeClockTimezoneController.text = settings.timeClockTimezone;
  }

  Future<void> _save(SystemSettingsViewModel viewModel) async {
    final next = viewModel.settings.copyWith(
      workspaceName: _workspaceNameController.text,
      workspaceTagline: _workspaceTaglineController.text,
      dashboardGreetingTitle: _dashboardTitleController.text,
      dashboardGreetingSubtitle: _dashboardSubtitleController.text,
      supportEmail: _supportEmailController.text,
      supportPhone: _supportPhoneController.text,
      clientPortalWelcomeMessage: _clientPortalWelcomeController.text,
      aiAssistantPreviewEnabled: _aiAssistantPreviewEnabled,
      compactNavigation: _compactNavigation,
      clientPortalShowBudgets: _clientPortalShowBudgets,
      clientPortalShowBudgetValues: _clientPortalShowBudgetValues,
      clientPortalShowCurrentCosts: _clientPortalShowCurrentCosts,
      timeClockEnabled: _timeClockEnabled,
      timeClockGeofenceRequired: _timeClockGeofenceRequired,
      timeClockStoreRejectedAttempts: _timeClockStoreRejectedAttempts,
      timeClockInpiRegistrationNumber: _timeClockInpiController.text,
      timeClockEmployerName: _timeClockEmployerNameController.text,
      timeClockEmployerDocument: _timeClockEmployerDocumentController.text,
      timeClockTimezone: _timeClockTimezoneController.text,
    );

    final success = await viewModel.save(next);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Configuracoes salvas com sucesso.'
              : viewModel.errorMessage ?? 'Nao foi possivel salvar.',
        ),
        backgroundColor: success ? AppColors.accentBlue : AppColors.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemSettingsViewModel>(
      builder: (context, viewModel, child) {
        final settings = viewModel.settings;
        _bindFromSettings(settings);

        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GranithReveal(
                    delay: const Duration(milliseconds: 40),
                    child: _buildHeader(viewModel),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 110),
                    child: _buildPostureStrip(settings),
                  ),
                  const SizedBox(height: 18),
                  const GranithReveal(
                    delay: Duration(milliseconds: 145),
                    child: TransparencyBanner(),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 180),
                    child: _ConfigSectionCard(
                      title: 'Identidade do Workspace',
                      subtitle: 'Nome e assinatura visual do ERP.',
                      icon: Icons.business_rounded,
                      initiallyExpanded: true,
                      child: Column(
                        children: [
                          TextField(
                            controller: _workspaceNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do workspace',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _workspaceTaglineController,
                            decoration: const InputDecoration(
                              labelText: 'Tagline operacional',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 240),
                    child: _ConfigSectionCard(
                      title: 'Dashboard Executivo',
                      subtitle: 'Texto de entrada e densidade da interface.',
                      icon: Icons.dashboard_customize_rounded,
                      initiallyExpanded: true,
                      child: Column(
                        children: [
                          TextField(
                            controller: _dashboardTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Titulo de saudacao',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _dashboardSubtitleController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Subtitulo do dashboard',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile.adaptive(
                            value: _aiAssistantPreviewEnabled,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Exibir preview do assistente de IA',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Atalho visual no topo do dashboard.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged: (value) {
                              setState(
                                () => _aiAssistantPreviewEnabled = value,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile.adaptive(
                            value: _compactNavigation,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Menu lateral compacto',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Mais espaco para o conteudo.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged: (value) {
                              setState(() => _compactNavigation = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 300),
                    child: _ConfigSectionCard(
                      title: 'Ponto REP-P',
                      subtitle: 'Regras do ponto mobile.',
                      icon: Icons.fingerprint_rounded,
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: _timeClockEnabled,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Modulo de ponto ativo',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Controla novas batidas no mobile.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged: (value) {
                              setState(() => _timeClockEnabled = value);
                            },
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile.adaptive(
                            value: _timeClockGeofenceRequired,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Exigir cerca da obra',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Valida presenca na geofence.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged:
                                _timeClockEnabled
                                    ? (value) {
                                      setState(
                                        () =>
                                            _timeClockGeofenceRequired = value,
                                      );
                                    }
                                    : null,
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile.adaptive(
                            value: _timeClockStoreRejectedAttempts,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Guardar tentativas fora da regra',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Mantem auditoria das recusas.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged:
                                _timeClockEnabled
                                    ? (value) {
                                      setState(
                                        () =>
                                            _timeClockStoreRejectedAttempts =
                                                value,
                                      );
                                    }
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _timeClockInpiController,
                            decoration: const InputDecoration(
                              labelText: 'Registro INPI do REP-P',
                              hintText: 'Preencher quando registrado',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _timeClockEmployerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Razao social empregadora',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _timeClockEmployerDocumentController,
                            decoration: const InputDecoration(
                              labelText: 'CNPJ/CPF empregador',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _timeClockTimezoneController,
                            decoration: const InputDecoration(
                              labelText: 'Fuso horario fiscal',
                              hintText: 'America/Sao_Paulo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 360),
                    child: _ConfigSectionCard(
                      title: 'Portal do Cliente',
                      subtitle: 'O que o cliente pode enxergar.',
                      icon: Icons.groups_rounded,
                      child: Column(
                        children: [
                          TextField(
                            controller: _clientPortalWelcomeController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Mensagem principal do portal',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile.adaptive(
                            value: _clientPortalShowBudgets,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Exibir area de propostas e orcamentos',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Mostra a trilha comercial.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged: (value) {
                              setState(() => _clientPortalShowBudgets = value);
                            },
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile.adaptive(
                            value: _clientPortalShowBudgetValues,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Exibir valores de orcamentos e contratos',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Abre valores ao cliente.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged:
                                _clientPortalShowBudgets
                                    ? (value) {
                                      setState(
                                        () =>
                                            _clientPortalShowBudgetValues =
                                                value,
                                      );
                                    }
                                    : null,
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile.adaptive(
                            value: _clientPortalShowCurrentCosts,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Exibir custo aplicado nas obras',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Para contratos com maior transparencia.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            onChanged: (value) {
                              setState(
                                () => _clientPortalShowCurrentCosts = value,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 420),
                    child: _ConfigSectionCard(
                      title: 'Uso da Plataforma',
                      subtitle: 'Consumo e observabilidade do Supabase.',
                      icon: Icons.monitor_heart_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acompanhe operacoes, storage e maturidade da telemetria interna.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SettingsHintChip(
                                icon: Icons.analytics_outlined,
                                label: 'Operacoes do banco',
                              ),
                              _SettingsHintChip(
                                icon: Icons.cloud_queue_rounded,
                                label: 'Storage observado',
                              ),
                              _SettingsHintChip(
                                icon: Icons.attach_money_rounded,
                                label: 'Governanca',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SubscriptionPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.monitor_heart_outlined),
                              label: const Text('Abrir relatorio'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 18),
                    GranithReveal(
                      delay: const Duration(milliseconds: 390),
                      child: _buildDeveloperToolsSection(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  GranithReveal(
                    delay: const Duration(milliseconds: 420),
                    child: _ConfigSectionCard(
                      title: 'Relacionamento e Suporte',
                      subtitle: 'Contato exibido no portal.',
                      icon: Icons.support_agent_rounded,
                      child: Column(
                        children: [
                          TextField(
                            controller: _supportEmailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail de suporte/relacionamento',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _supportPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone/WhatsApp',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeveloperToolsSection() {
    return _ConfigSectionCard(
      title: 'Ferramentas de desenvolvimento',
      subtitle: 'Base demonstrativa local.',
      icon: Icons.bug_report_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: _isSeeding ? null : _runSeeder,
            icon:
                _isSeeding
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.cloud_sync_rounded),
            label: Text(
              _isSeeding ? 'Executando seeder...' : 'Executar seeder',
            ),
          ),
          const _SettingsHintChip(
            icon: Icons.bug_report_outlined,
            label: 'Somente debug',
          ),
        ],
      ),
    );
  }

  Future<void> _runSeeder() async {
    if (!kDebugMode || _isSeeding) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.92),
            title: const Text(
              'Executar seeder?',
              style: TextStyle(color: AppColors.accentBlue),
            ),
            content: const Text(
              'Isso ira criar ou atualizar dados demonstrativos no banco.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Executar',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _isSeeding = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciando seeder... isso pode levar alguns segundos.'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final seeder = DatabaseSeeder();
      final success = await seeder.seed();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Banco populado com sucesso.'
                : seeder.lastErrorMessage ??
                    'Erro ao popular banco. Verifique o console.',
          ),
          backgroundColor:
              success ? AppColors.accentGreen : AppColors.accentRed,
          duration: Duration(seconds: success ? 4 : 10),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro critico: $error'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Widget _buildHeader(SystemSettingsViewModel viewModel) {
    final compact = MediaQuery.sizeOf(context).width < ResponsiveLayout.compact;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Central de Configuracoes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ajustes essenciais do workspace, dashboard e portal.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: AppColors.accentRed),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: viewModel.isSaving ? null : () => _save(viewModel),
            icon:
                viewModel.isSaving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : const Icon(Icons.save_outlined),
            label: Text(
              viewModel.isSaving
                  ? 'Salvando...'
                  : compact
                  ? 'Salvar'
                  : 'Salvar configuracoes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostureStrip(SystemSettings settings) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SettingsPostureTile(
          title: 'Workspace vivo',
          value: settings.workspaceName,
          subtitle: settings.workspaceTagline,
          accent: AppColors.accentBlue,
        ),
        _SettingsPostureTile(
          title: 'Portal do cliente',
          value: settings.clientPortalShowBudgets ? 'Expandido' : 'Essencial',
          subtitle:
              settings.clientPortalShowCurrentCosts
                  ? 'transparencia operacional aberta'
                  : 'custos preservados no ERP',
          accent: AppColors.accentGold,
        ),
        _SettingsPostureTile(
          title: 'Experiencia',
          value: settings.compactNavigation ? 'Compacta' : 'Panoramica',
          subtitle:
              settings.aiAssistantPreviewEnabled
                  ? 'preview de IA habilitado'
                  : 'IA visual oculta',
          accent: AppColors.auraCyan,
        ),
      ],
    );
  }
}

class _ConfigSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool initiallyExpanded;
  final Widget child;

  const _ConfigSectionCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final sectionIcon = icon ?? Icons.tune_rounded;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.48),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textMuted,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(sectionIcon, color: AppColors.accentBlue, size: 18),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _SettingsPostureTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _SettingsPostureTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Tooltip(
      message: subtitle,
      child: Container(
        constraints:
            width < ResponsiveLayout.compact
                ? const BoxConstraints()
                : const BoxConstraints(minWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHintChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingsHintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.accentBlue),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
