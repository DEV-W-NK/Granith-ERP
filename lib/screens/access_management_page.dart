import 'package:flutter/material.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/access_management_service.dart';
import 'package:project_granith/services/client_account_service.dart';
import 'package:project_granith/services/client_portal_access_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class _PermissionOption {
  final String code;
  final String label;
  final String description;
  final bool visibleByDefault;

  const _PermissionOption({
    required this.code,
    required this.label,
    required this.description,
    this.visibleByDefault = true,
  });
}

class AccessManagementPage extends StatefulWidget {
  final int initialTabIndex;
  final AccessManagementService? accessService;
  final ClientAccountService? clientAccountService;
  final ClientPortalAccessService? clientPortalAccessService;

  const AccessManagementPage({
    super.key,
    this.initialTabIndex = 0,
    this.accessService,
    this.clientAccountService,
    this.clientPortalAccessService,
  });

  @override
  State<AccessManagementPage> createState() => _AccessManagementPageState();
}

class _AccessManagementPageState extends State<AccessManagementPage>
    with SingleTickerProviderStateMixin {
  late final AccessManagementService _accessService;
  late final ClientAccountService _clientAccountService;
  late final ClientPortalAccessService _clientPortalAccessService;

  static const List<_PermissionOption> _knownPermissions = [
    _PermissionOption(
      code: 'projects.read',
      label: 'Visualizar projetos',
      description: 'Permite consultar obras, contratos e detalhes do projeto.',
    ),
    _PermissionOption(
      code: 'projects.write',
      label: 'Criar e editar projetos',
      description: 'Permite cadastrar obras e alterar dados de projetos.',
    ),
    _PermissionOption(
      code: 'budgets.read',
      label: 'Visualizar orcamentos',
      description: 'Permite consultar propostas, valores e historico.',
    ),
    _PermissionOption(
      code: 'budgets.write',
      label: 'Criar e editar orcamentos',
      description: 'Permite montar, aprovar e atualizar orcamentos.',
    ),
    _PermissionOption(
      code: 'financial.read',
      label: 'Visualizar financeiro',
      description: 'Permite consultar entradas, saidas e relatorios.',
    ),
    _PermissionOption(
      code: 'financial.write',
      label: 'Lancar financeiro',
      description: 'Permite criar e atualizar contas a pagar ou receber.',
    ),
    _PermissionOption(
      code: 'inventory.read',
      label: 'Visualizar estoque',
      description: 'Permite consultar saldos e movimentacoes de materiais.',
    ),
    _PermissionOption(
      code: 'inventory.write',
      label: 'Movimentar estoque',
      description: 'Permite registrar entradas, saidas e ajustes.',
    ),
    _PermissionOption(
      code: PermissionCodes.purchasesApprove,
      label: 'Aprovar orcamentos de compra',
      description:
          'Permite aprovar orcamentos de compra de qualquer setor solicitante.',
    ),
    _PermissionOption(
      code: PermissionCodes.purchasesConsolidate,
      label: 'Consolidar compras',
      description:
          'Permite informar nota fiscal, prazo de entrega e enviar a compra ao financeiro.',
    ),
    _PermissionOption(
      code: PermissionCodes.purchaseFinanceRead,
      label: 'Ver contas de compras',
      description:
          'Permite consultar apenas contas financeiras originadas por compras.',
    ),
    _PermissionOption(
      code: PermissionCodes.purchaseFinanceWrite,
      label: 'Pagar contas de compras',
      description:
          'Permite quitar ou cancelar contas a pagar originadas por compras.',
    ),
    _PermissionOption(
      code: 'people.manage',
      label: 'Gerenciar pessoas',
      description: 'Permite administrar colaboradores, cargos e beneficios.',
    ),
    _PermissionOption(
      code: PermissionCodes.peopleSalaryRead,
      label: 'Visualizar salarios no RH',
      description:
          'Permite ver e alterar os salarios dos colaboradores no modulo de RH.',
    ),
    _PermissionOption(
      code: 'access.manage',
      label: 'Gerenciar acessos',
      description: 'Permite alterar papeis, permissoes e acessos de clientes.',
    ),
    _PermissionOption(
      code: 'settings.manage',
      label: 'Configurar sistema',
      description: 'Permite alterar preferencias gerais do ERP.',
    ),
    _PermissionOption(
      code: 'billing.manage',
      label: 'Gerenciar assinatura',
      description: 'Permite consultar consumo e dados de assinatura.',
    ),
    _PermissionOption(
      code: 'mobile.hierarchy.manage',
      label: 'Gerenciar hierarquia mobile',
      description: 'Permite configurar niveis de acesso do app mobile.',
    ),
    _PermissionOption(
      code: 'mobile.materials.request',
      label: 'Solicitar materiais no app',
      description: 'Permite criar requisicoes de materiais pelo mobile.',
    ),
    _PermissionOption(
      code: 'mobile.daily_logs.write',
      label: 'Lancar diario no app',
      description: 'Permite registrar diario de obra pelo mobile.',
    ),
    _PermissionOption(
      code: 'mobile.team.manage',
      label: 'Gerenciar equipes no app',
      description: 'Permite administrar equipes pelo mobile.',
    ),
    _PermissionOption(
      code: 'mobile.payroll.self.read',
      label: 'Ver proprio pagamento',
      description: 'Permite consultar informacoes pessoais de pagamento.',
    ),
    _PermissionOption(
      code: 'obras',
      label: 'Obras',
      description: 'Permissao legada para acesso aos modulos de obras.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'diario',
      label: 'Diario de obras',
      description: 'Permissao legada para acessar diarios de obra.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'medicoes',
      label: 'Medicoes',
      description: 'Permissao legada para acessar medicoes de obra.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'financeiro',
      label: 'Financeiro',
      description: 'Permissao legada para o modulo financeiro.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'relatorios',
      label: 'Relatorios',
      description: 'Permissao legada para relatorios gerenciais.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'rh',
      label: 'Recursos humanos',
      description: 'Permissao legada para os modulos de RH.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'suprimentos',
      label: 'Suprimentos',
      description: 'Permissao legada para fornecedores e requisicoes.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'compras',
      label: 'Compras',
      description: 'Permissao legada para compras e pedidos.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'estoque',
      label: 'Estoque',
      description: 'Permissao legada para controle de estoque.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'portal_cliente',
      label: 'Portal do cliente',
      description: 'Permissao legada para acesso ao portal do cliente.',
      visibleByDefault: false,
    ),
    _PermissionOption(
      code: 'admin',
      label: 'Administrador legado',
      description:
          'Permissao antiga de administrador mantida por compatibilidade.',
      visibleByDefault: false,
    ),
  ];

  List<String> get _availablePermissionCodes =>
      _knownPermissions.map((permission) => permission.code).toList();

  late final TabController _tabController;
  bool _isLoading = true;
  bool _isSendingInvite = false;
  bool _isSavingAccess = false;
  List<UserModel> _users = [];
  List<ClientAccount> _clients = [];
  final Map<String, UserModel> _draftUsers = {};

  @override
  void initState() {
    super.initState();
    _accessService = widget.accessService ?? AccessManagementService();
    _clientAccountService =
        widget.clientAccountService ?? ClientAccountService();
    _clientPortalAccessService =
        widget.clientPortalAccessService ?? ClientPortalAccessService();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex == 1 ? 1 : 0,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _accessService.getUsers();
      final clients = await _clientAccountService.getClientAccounts();
      if (!mounted) return;
      setState(() {
        _users = users;
        _clients = clients;
        _draftUsers.clear();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePendingAccessChanges() async {
    if (_isSavingAccess) return;

    final changedUsers = _changedAccessUsers;
    if (changedUsers.isEmpty) return;

    setState(() => _isSavingAccess = true);
    try {
      for (final user in changedUsers) {
        await _accessService.updateUserAccess(user);
      }
      await _loadData();
      if (!mounted) return;
      _showFeedback(
        changedUsers.length == 1
            ? 'Permissoes e papel atualizados.'
            : 'Permissoes e papeis atualizados.',
      );
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        'Nao foi possivel salvar permissoes: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAccess = false);
      }
    }
  }

  List<UserModel> get _changedAccessUsers =>
      _users.map((user) => _draftUsers[user.uid]).whereType<UserModel>().where((
        draft,
      ) {
        final original = _users.firstWhere(
          (user) => user.uid == draft.uid,
          orElse: () => draft,
        );
        return _hasAccessChanged(original, draft);
      }).toList();

  bool get _hasPendingAccessChanges => _changedAccessUsers.isNotEmpty;

  UserModel _draftFor(UserModel user) => _draftUsers[user.uid] ?? user;

  void _stageUserAccess(UserModel original, UserModel draft) {
    setState(() {
      if (_hasAccessChanged(original, draft)) {
        _draftUsers[original.uid] = draft;
      } else {
        _draftUsers.remove(original.uid);
      }
    });
  }

  bool _hasAccessChanged(UserModel original, UserModel draft) {
    return original.role != draft.role ||
        !_samePermissions(original.permissions, draft.permissions);
  }

  bool _samePermissions(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    final leftSet = left.toSet();
    final rightSet = right.toSet();
    if (leftSet.length != rightSet.length) return false;
    return leftSet.every(rightSet.contains);
  }

  List<String> _normalizePermissions(Iterable<String> permissions) {
    final set = permissions.toSet();
    return [
      ..._availablePermissionCodes.where(set.contains),
      ...set.where(
        (permission) => !_availablePermissionCodes.contains(permission),
      ),
    ];
  }

  List<_PermissionOption> _permissionOptionsFor(UserModel draft) {
    final knownCodes = _availablePermissionCodes.toSet();
    final currentPermissionCodes = draft.permissions.toSet();
    final visibleKnownPermissions = _knownPermissions.where(
      (permission) =>
          permission.visibleByDefault ||
          currentPermissionCodes.contains(permission.code),
    );
    final unknownCurrentPermissions = draft.permissions
        .where((permission) => !knownCodes.contains(permission))
        .map(
          (permission) => _PermissionOption(
            code: permission,
            label: _humanizePermissionCode(permission),
            description:
                'Permissao cadastrada anteriormente. Codigo interno: $permission',
          ),
        );

    return [...visibleKnownPermissions, ...unknownCurrentPermissions];
  }

  String _humanizePermissionCode(String code) {
    final normalized =
        code
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .trim();
    if (normalized.isEmpty) return 'Permissao sem nome';
    return normalized
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _openClientDialog([ClientAccount? client]) async {
    final result = await showDialog<_ClientAccountDialogResult>(
      context: context,
      builder: (_) => _ClientAccountDialog(client: client),
    );

    if (result == null) return;

    try {
      final savedAccount = await _clientAccountService.saveClientAccount(
        result.account,
      );
      if (!mounted) return;

      if (result.provisionAccess) {
        await _sendPortalInvite(savedAccount);
        return;
      }

      await _loadData();
      if (!mounted) return;
      _showFeedback('Cadastro do cliente salvo com sucesso.');
    } catch (error) {
      if (!mounted) return;
      _showFeedback('Nao foi possivel salvar o cliente: $error', isError: true);
    }
  }

  Future<void> _sendPortalInvite(ClientAccount client) async {
    if (_isSendingInvite) return;

    setState(() => _isSendingInvite = true);
    try {
      final result = await _clientPortalAccessService.createOrResendAccess(
        client,
      );
      await _loadData();
      if (!mounted) return;
      _showFeedback(result.message);
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        error is ClientPortalAccessException ? error.message : '$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingInvite = false);
      }
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissoes e Clientes',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Controle quem acessa cada area do ERP e acompanhe o cadastro dos clientes com acesso ao portal.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.borderColor.withValues(alpha: 0.65),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: width < ResponsiveLayout.compact,
                  tabAlignment:
                      width < ResponsiveLayout.compact
                          ? TabAlignment.start
                          : null,
                  indicatorColor: AppColors.accentBlue,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Usuarios e acessos'),
                    Tab(text: 'Clientes do portal'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentBlue,
                          ),
                        )
                        : TabBarView(
                          controller: _tabController,
                          children: [_buildUsersTab(), _buildClientsTab()],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    final changedCount = _changedAccessUsers.length;

    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.only(bottom: _hasPendingAccessChanges ? 96 : 12),
          itemCount: _users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final user = _users[index];
            final draft = _draftFor(user);
            final hasChanges = _hasAccessChanged(user, draft);

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      hasChanges
                          ? AppColors.accentGold.withValues(alpha: 0.78)
                          : AppColors.borderColor.withValues(alpha: 0.65),
                ),
                boxShadow: AppColors.glowShadows(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName!
                                  : user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width:
                            MediaQuery.sizeOf(context).width <
                                    ResponsiveLayout.compact
                                ? 150
                                : 180,
                        child: DropdownButtonFormField<UserRole>(
                          key: ValueKey('${user.uid}-${draft.role.name}'),
                          initialValue: draft.role,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de usuario',
                          ),
                          items:
                              UserRole.values
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.displayName),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (role) {
                            if (role == null) return;
                            _stageUserAccess(user, draft.copyWith(role: role));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _permissionOptionsFor(draft).map((permission) {
                          final selected = draft.permissions.contains(
                            permission.code,
                          );
                          return Tooltip(
                            message:
                                '${permission.description}\nCodigo interno: ${permission.code}',
                            child: FilterChip(
                              label: Text(permission.label),
                              selected: selected,
                              onSelected: (value) {
                                final permissions = draft.permissions.toSet();
                                if (value) {
                                  permissions.add(permission.code);
                                } else {
                                  permissions.remove(permission.code);
                                }
                                _stageUserAccess(
                                  user,
                                  draft.copyWith(
                                    permissions: _normalizePermissions(
                                      permissions,
                                    ),
                                  ),
                                );
                              },
                              selectedColor: AppColors.accentBlue.withValues(
                                alpha: 0.18,
                              ),
                              backgroundColor: AppColors.surfaceDark.withValues(
                                alpha: 0.5,
                              ),
                              labelStyle: TextStyle(
                                color:
                                    selected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                              ),
                              side: BorderSide(
                                color:
                                    selected
                                        ? AppColors.accentBlue
                                        : AppColors.borderColor.withValues(
                                          alpha: 0.65,
                                        ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
        if (_hasPendingAccessChanges)
          Positioned(
            right: 0,
            bottom: 0,
            child: _SaveAccessButton(
              changedCount: changedCount,
              isSaving: _isSavingAccess,
              onPressed: _savePendingAccessChanges,
            ),
          ),
      ],
    );
  }

  Widget _buildClientsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.65),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < ResponsiveLayout.compact;
              final description = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Listagem de clientes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cadastre o cliente com o e-mail do responsavel pelo portal e envie o convite de primeiro acesso pela propria listagem.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              );
              final action = ElevatedButton.icon(
                onPressed: () => _openClientDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Cadastrar cliente'),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    description,
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: action),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: description),
                  const SizedBox(width: 16),
                  action,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child:
              _clients.isEmpty
                  ? _buildEmptyClientsState()
                  : ListView.separated(
                    itemCount: _clients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      final inviteActionLabel = _getInviteActionLabel(
                        client.portalAccessStatus,
                      );

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.borderColor.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          boxShadow: AppColors.glowShadows(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentBlue.withValues(
                                      alpha: 0.12,
                                    ),
                                    boxShadow: AppColors.auraShadows(
                                      AppColors.accentBlue,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Conta do portal: ${client.ownerEmail}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (client.contactPhone.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          client.contactPhone,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                _PortalStatusChip(
                                  status: client.portalAccessStatus,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _InfoPill(
                                  icon: Icons.mark_email_read_outlined,
                                  label:
                                      client.portalInvitedAt == null
                                          ? 'Convite ainda nao enviado'
                                          : 'Ultimo convite: ${_formatDate(client.portalInvitedAt!)}',
                                ),
                                _InfoPill(
                                  icon: Icons.login_rounded,
                                  label:
                                      client.portalLastAccessAt == null
                                          ? 'Cliente ainda nao acessou o portal'
                                          : 'Ultimo acesso: ${_formatDate(client.portalLastAccessAt!)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final editButton = OutlinedButton.icon(
                                  onPressed: () => _openClientDialog(client),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar cadastro'),
                                );
                                final inviteButton = ElevatedButton.icon(
                                  onPressed:
                                      _isSendingInvite
                                          ? null
                                          : () => _sendPortalInvite(client),
                                  icon: Icon(
                                    _getInviteActionIcon(
                                      client.portalAccessStatus,
                                    ),
                                  ),
                                  label: Text(inviteActionLabel),
                                );

                                if (constraints.maxWidth <
                                    ResponsiveLayout.compact) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: editButton,
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: inviteButton,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: editButton),
                                    const SizedBox(width: 12),
                                    Expanded(child: inviteButton),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyClientsState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.12),
                boxShadow: AppColors.auraShadows(AppColors.accentBlue),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum cliente cadastrado',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie o primeiro cadastro e envie o convite de acesso ao portal no mesmo fluxo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _openClientDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Cadastrar cliente'),
            ),
          ],
        ),
      ),
    );
  }

  String _getInviteActionLabel(ClientPortalAccessStatus status) {
    switch (status) {
      case ClientPortalAccessStatus.pending:
        return 'Enviar convite';
      case ClientPortalAccessStatus.invited:
        return 'Reenviar convite';
      case ClientPortalAccessStatus.active:
        return 'Enviar novo convite';
    }
  }

  IconData _getInviteActionIcon(ClientPortalAccessStatus status) {
    switch (status) {
      case ClientPortalAccessStatus.pending:
        return Icons.send_outlined;
      case ClientPortalAccessStatus.invited:
      case ClientPortalAccessStatus.active:
        return Icons.mark_email_unread_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final safeDate = date.toLocal();
    final day = safeDate.day.toString().padLeft(2, '0');
    final month = safeDate.month.toString().padLeft(2, '0');
    final year = safeDate.year.toString();
    final hour = safeDate.hour.toString().padLeft(2, '0');
    final minute = safeDate.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _SaveAccessButton extends StatelessWidget {
  final int changedCount;
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveAccessButton({
    required this.changedCount,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        changedCount == 1
            ? 'Salvar acesso do usuario'
            : 'Salvar acessos dos usuarios';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.glowShadows(AppColors.accentGold),
      ),
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onPressed,
        icon:
            isSaving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.save_rounded),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}

class _PortalStatusChip extends StatelessWidget {
  final ClientPortalAccessStatus status;

  const _PortalStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case ClientPortalAccessStatus.pending:
        color = AppColors.accentGold;
        break;
      case ClientPortalAccessStatus.invited:
        color = AppColors.accentBlue;
        break;
      case ClientPortalAccessStatus.active:
        color = AppColors.accentGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ClientAccountDialogResult {
  final ClientAccount account;
  final bool provisionAccess;

  const _ClientAccountDialogResult({
    required this.account,
    required this.provisionAccess,
  });
}

class _ClientAccountDialog extends StatefulWidget {
  final ClientAccount? client;

  const _ClientAccountDialog({this.client});

  @override
  State<_ClientAccountDialog> createState() => _ClientAccountDialogState();
}

class _ClientAccountDialogState extends State<_ClientAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ownerEmailController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _notesController;
  late bool _provisionAccessOnSave;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _ownerEmailController = TextEditingController(
      text: client?.ownerEmail ?? '',
    );
    _contactEmailController = TextEditingController(
      text: client?.contactEmail ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: client?.contactPhone ?? '',
    );
    _notesController = TextEditingController(text: client?.notes ?? '');
    _provisionAccessOnSave =
        client == null ||
        client.portalAccessStatus == ClientPortalAccessStatus.pending;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerEmailController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;
    final size = MediaQuery.sizeOf(context);
    final inset = size.width < 420 ? 8.0 : 24.0;
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 560.0);

    return AlertDialog(
      insetPadding: EdgeInsets.all(inset),
      title: Text(isEditing ? 'Editar cliente' : 'Cadastrar cliente'),
      content: SizedBox(
        width: dialogWidth.toDouble(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cliente',
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o nome'
                              : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ownerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail da conta do portal',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o e-mail da conta';
                    }
                    if (!value.contains('@')) {
                      return 'Informe um e-mail valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail comercial',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactPhoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observacoes'),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        value: _provisionAccessOnSave,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Enviar convite do portal ao salvar',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'O sistema envia o convite para o e-mail informado. Quando o cliente usar o link, ele define a senha e volta para o login do Granith.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        onChanged: (value) {
                          setState(() => _provisionAccessOnSave = value);
                        },
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Status atual do convite: ${widget.client!.portalAccessStatus.label}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final base = widget.client ?? ClientAccount.empty();
            Navigator.pop(
              context,
              _ClientAccountDialogResult(
                provisionAccess: _provisionAccessOnSave,
                account: base.copyWith(
                  id: base.id.isEmpty ? '' : base.id,
                  name: _nameController.text,
                  ownerEmail: _ownerEmailController.text,
                  contactEmail: _contactEmailController.text,
                  contactPhone: _contactPhoneController.text,
                  notes: _notesController.text,
                ),
              ),
            );
          },
          child: Text(
            _provisionAccessOnSave ? 'Salvar e enviar convite' : 'Salvar',
          ),
        ),
      ],
    );
  }
}
