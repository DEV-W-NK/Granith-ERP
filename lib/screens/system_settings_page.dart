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
        final width = MediaQuery.sizeOf(context).width;
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
              padding: ResponsiveLayout.pagePadding(
                width,
              ).add(const EdgeInsets.only(bottom: 36)),
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
                  _SettingsCardsGrid(
                    children: [
                      GranithReveal(
                        delay: const Duration(milliseconds: 180),
                        child: _buildIdentitySection(),
                      ),
                      GranithReveal(
                        delay: const Duration(milliseconds: 240),
                        child: _buildDashboardSection(),
                      ),
                      GranithReveal(
                        delay: const Duration(milliseconds: 300),
                        child: _buildPortalSection(),
                      ),
                      GranithReveal(
                        delay: const Duration(milliseconds: 360),
                        child: _buildTimeClockSection(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsCardsGrid(
                    children: [
                      GranithReveal(
                        delay: const Duration(milliseconds: 420),
                        child: _buildPlatformUsageSection(),
                      ),
                      if (kDebugMode)
                        GranithReveal(
                          delay: const Duration(milliseconds: 450),
                          child: _buildDeveloperToolsSection(),
                        ),
                      GranithReveal(
                        delay: const Duration(milliseconds: 480),
                        child: _buildSupportSection(),
                      ),
                    ],
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

  Widget _buildIdentitySection() {
    return _ConfigSectionCard(
      title: 'Identidade do Workspace',
      subtitle: 'Nome, assinatura e apresentacao do ERP.',
      icon: Icons.business_rounded,
      accent: AppColors.accentBlue,
      child: Column(
        children: [
          TextField(
            controller: _workspaceNameController,
            decoration: const InputDecoration(labelText: 'Nome do workspace'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _workspaceTaglineController,
            decoration: const InputDecoration(labelText: 'Tagline operacional'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection() {
    return _ConfigSectionCard(
      title: 'Dashboard Executivo',
      subtitle: 'Entrada, saudacao e densidade da interface.',
      icon: Icons.dashboard_customize_rounded,
      accent: AppColors.auraCyan,
      child: Column(
        children: [
          TextField(
            controller: _dashboardTitleController,
            decoration: const InputDecoration(labelText: 'Titulo de saudacao'),
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
          _SettingsSwitchTile(
            value: _aiAssistantPreviewEnabled,
            title: 'Preview do assistente de IA',
            subtitle: 'Atalho visual no topo do dashboard.',
            onChanged:
                (value) => setState(() => _aiAssistantPreviewEnabled = value),
          ),
          _SettingsSwitchTile(
            value: _compactNavigation,
            title: 'Menu lateral compacto',
            subtitle: 'Mais espaco para o conteudo.',
            onChanged: (value) => setState(() => _compactNavigation = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalSection() {
    return _ConfigSectionCard(
      title: 'Portal do Cliente',
      subtitle: 'Visibilidade comercial e operacional para clientes.',
      icon: Icons.groups_rounded,
      accent: AppColors.accentGold,
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
          _SettingsSwitchTile(
            value: _clientPortalShowBudgets,
            title: 'Propostas e orcamentos',
            subtitle: 'Mostra a trilha comercial no portal.',
            onChanged:
                (value) => setState(() => _clientPortalShowBudgets = value),
          ),
          _SettingsSwitchTile(
            value: _clientPortalShowBudgetValues,
            title: 'Valores de orcamentos e contratos',
            subtitle: 'Abre valores ao cliente.',
            onChanged:
                _clientPortalShowBudgets
                    ? (value) =>
                        setState(() => _clientPortalShowBudgetValues = value)
                    : null,
          ),
          _SettingsSwitchTile(
            value: _clientPortalShowCurrentCosts,
            title: 'Custo aplicado nas obras',
            subtitle: 'Para contratos com maior transparencia.',
            onChanged:
                (value) =>
                    setState(() => _clientPortalShowCurrentCosts = value),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeClockSection() {
    return _ConfigSectionCard(
      title: 'Ponto REP-P',
      subtitle: 'Regras do ponto mobile e dados fiscais.',
      icon: Icons.fingerprint_rounded,
      accent: AppColors.accentGreen,
      child: Column(
        children: [
          _SettingsSwitchTile(
            value: _timeClockEnabled,
            title: 'Modulo de ponto ativo',
            subtitle: 'Controla novas batidas no mobile.',
            onChanged: (value) => setState(() => _timeClockEnabled = value),
          ),
          _SettingsSwitchTile(
            value: _timeClockGeofenceRequired,
            title: 'Exigir cerca da obra',
            subtitle: 'Valida presenca na geofence.',
            onChanged:
                _timeClockEnabled
                    ? (value) =>
                        setState(() => _timeClockGeofenceRequired = value)
                    : null,
          ),
          _SettingsSwitchTile(
            value: _timeClockStoreRejectedAttempts,
            title: 'Auditar recusas',
            subtitle: 'Guarda tentativas fora da regra.',
            onChanged:
                _timeClockEnabled
                    ? (value) =>
                        setState(() => _timeClockStoreRejectedAttempts = value)
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
            decoration: const InputDecoration(labelText: 'CNPJ/CPF empregador'),
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
    );
  }

  Widget _buildPlatformUsageSection() {
    return _ConfigSectionCard(
      title: 'Consumo da plataforma',
      subtitle: 'Consumo e observabilidade do Supabase.',
      icon: Icons.monitor_heart_outlined,
      accent: AppColors.accentBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acompanhe operacoes, storage e maturidade da telemetria interna.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
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
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                );
              },
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Abrir relatorio'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return _ConfigSectionCard(
      title: 'Relacionamento e Suporte',
      subtitle: 'Contato exibido no portal.',
      icon: Icons.support_agent_rounded,
      accent: AppColors.accentGold,
      child: Column(
        children: [
          TextField(
            controller: _supportEmailController,
            decoration: const InputDecoration(labelText: 'E-mail de suporte'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _supportPhoneController,
            decoration: const InputDecoration(labelText: 'Telefone/WhatsApp'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperToolsSection() {
    return _ConfigSectionCard(
      title: 'Ferramentas de desenvolvimento',
      subtitle: 'Base demonstrativa local.',
      icon: Icons.bug_report_outlined,
      accent: AppColors.accentRed,
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
    return _SettingsCardsGrid(
      gap: 12,
      children: [
        _SettingsPostureTile(
          icon: Icons.business_center_rounded,
          title: 'Workspace vivo',
          value: settings.workspaceName,
          subtitle: settings.workspaceTagline,
          accent: AppColors.accentBlue,
        ),
        _SettingsPostureTile(
          icon: Icons.favorite_rounded,
          title: 'IA e navegacao',
          value:
              settings.aiAssistantPreviewEnabled ? 'IA visivel' : 'IA oculta',
          subtitle:
              settings.compactNavigation
                  ? 'navegacao compacta habilitada'
                  : 'navegacao panoramica habilitada',
          accent: AppColors.auraCyan,
        ),
        _SettingsPostureTile(
          icon: Icons.groups_rounded,
          title: 'Portal do cliente',
          value: settings.clientPortalShowBudgets ? 'Expandido' : 'Essencial',
          subtitle:
              settings.clientPortalShowCurrentCosts
                  ? 'transparencia operacional aberta'
                  : 'custos preservados no ERP',
          accent: AppColors.accentGold,
        ),
        _SettingsPostureTile(
          icon: Icons.fingerprint_rounded,
          title: 'Ponto REP-P',
          value: settings.timeClockEnabled ? 'Ativo' : 'Pausado',
          subtitle:
              settings.timeClockGeofenceRequired
                  ? 'geofence obrigatoria nas batidas'
                  : 'geofence desativada nas batidas',
          accent: AppColors.accentGreen,
        ),
      ],
    );
  }
}

class _SettingsCardsGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const _SettingsCardsGrid({required this.children, this.gap = 14});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 900;
        if (!useTwoColumns) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) SizedBox(height: gap),
                children[index],
              ],
            ],
          );
        }

        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

class _ConfigSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color accent;
  final Widget child;

  const _ConfigSectionCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.accent = AppColors.accentBlue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final sectionIcon = icon ?? Icons.tune_rounded;

    return Container(
      width: double.infinity,
      decoration: AppDecorations.cardSurface(accent: accent, radius: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                ),
                child: Icon(sectionIcon, color: accent, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.borderColor.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool>? onChanged;

  const _SettingsSwitchTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        softWrap: true,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        softWrap: true,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.25),
      ),
      onChanged: onChanged,
    );
  }
}

class _SettingsPostureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _SettingsPostureTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: AppDecorations.iconTile(accent),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.25,
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
