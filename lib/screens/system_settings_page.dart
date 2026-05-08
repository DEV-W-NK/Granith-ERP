import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/screens/subscription_page.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/utils/seeder.dart';
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

  bool _aiAssistantPreviewEnabled = true;
  bool _compactNavigation = false;
  bool _clientPortalShowBudgets = true;
  bool _clientPortalShowBudgetValues = true;
  bool _clientPortalShowCurrentCosts = true;
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
                  GranithReveal(
                    delay: const Duration(milliseconds: 180),
                    child: _ConfigSectionCard(
                      title: 'Identidade do Workspace',
                      subtitle:
                          'Define como o Granith se apresenta no login, menu lateral e dashboards.',
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
                      subtitle:
                          'Ajusta a linguagem do painel principal e ativa experiencias de produto em destaque.',
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
                              'Mantem o atalho visual de copilot no topo do dashboard como experimento guiado.',
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
                              'Reduz a largura da navegacao lateral para ambientes operacionais com foco em conteudo.',
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
                      title: 'Portal do Cliente',
                      subtitle:
                          'Controla quanto de transparencia operacional e comercial o cliente enxerga no portal.',
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
                              'Mostra ao cliente a trilha comercial com propostas aprovadas, pendentes e historico vinculado.',
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
                              'Permite um portal mais transparente para clientes de relacionamento premium ou contratos abertos.',
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
                              'Ideal para clientes com contrato por custo real, medicao aberta ou governanca ampliada.',
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
                    delay: const Duration(milliseconds: 360),
                    child: _ConfigSectionCard(
                      title: 'Custos e Infra Supabase',
                      subtitle:
                          'Centraliza a leitura de consumo observado do backend e prepara o terreno para um monitoramento financeiro mais maduro.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'O Granith agora possui um centro de observabilidade para o Supabase. Ele e ideal para enxergar operacoes, storage rastreado e o nivel de maturidade da telemetria interna antes de integrar billing oficial.',
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
                                label: 'Leitura de governanca',
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
                              label: const Text(
                                'Abrir centro de custos do Supabase',
                              ),
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
                      subtitle:
                          'Dados usados para orientar o cliente dentro do portal e reduzir ruido operacional.',
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
                              labelText: 'Telefone/WhatsApp de suporte',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed:
                          viewModel.isSaving ? null : () => _save(viewModel),
                      icon:
                          viewModel.isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.save_outlined),
                      label: Text(
                        viewModel.isSaving
                            ? 'Salvando...'
                            : 'Salvar configuracoes',
                      ),
                    ),
                  ),
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
      subtitle:
          'Disponivel apenas em debug para preparar uma base demonstrativa local.',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.18),
            AppColors.surfaceDark.withValues(alpha: 0.84),
            AppColors.accentGold.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.22)),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
                    'Central de Configuracoes',
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
                  'Ajuste o comportamento do Granith como produto, nao so como tela.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aqui entram as decisoes que mudam a percepcao do ERP: identidade do workspace, transparencia do portal do cliente, densidade da interface e linguagem do painel executivo.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
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
  final Widget child;

  const _ConfigSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.62),
        ),
        boxShadow: AppColors.glowShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
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

    return Container(
      constraints:
          width < ResponsiveLayout.compact
              ? const BoxConstraints()
              : const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: AppColors.auraShadows(accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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

class _SettingsHintChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingsHintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accentBlue),
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
