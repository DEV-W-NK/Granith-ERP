import 'package:flutter/material.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/access_management_service.dart';
import 'package:project_granith/services/auth_service.dart';
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

enum _AccessRoleFilter { all, admin, employee, client }

enum _AccessChangeFilter { all, changed, unchanged }

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
      code: PermissionCodes.aiUsageRead,
      label: 'Ver consumo de IA',
      description: 'Permite acompanhar tokens, chamadas e custo estimado.',
    ),
    _PermissionOption(
      code: PermissionCodes.aiPricingManage,
      label: 'Configurar preco da IA',
      description:
          'Permite ajustar preco manual por milhao de tokens para estimativas.',
    ),
    _PermissionOption(
      code: PermissionCodes.aiMonitor,
      label: 'Auditar historico de IA',
      description:
          'Permite consultar conversas de IA de usuarios para monitoramento autorizado.',
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
      code: 'mobile.work_hours.manual',
      label: 'Apontar horas fora da cerca',
      description:
          'Permite registrar horas produtivas no app sem presenca fisica na obra.',
    ),
    _PermissionOption(
      code: 'mobile.fuel_logs.write',
      label: 'Lancar combustivel no app',
      description:
          'Permite registrar abastecimentos, hodometro e nota fiscal pelo mobile.',
    ),
    _PermissionOption(
      code: 'time_clock.read',
      label: 'Consultar ponto',
      description: 'Permite consultar registros brutos e relatorios de ponto.',
    ),
    _PermissionOption(
      code: 'time_clock.manage',
      label: 'Gerenciar ponto',
      description:
          'Permite configurar o modulo REP-P e tratar inconsistencias de jornada.',
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

  static const int _initialVisibleItems = 18;
  static const int _visibleItemsStep = 18;

  late final TabController _tabController;
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  final Set<String> _expandedUserIds = <String>{};

  bool _isLoadingUsers = false;
  bool _isLoadingClients = false;
  bool _usersLoaded = false;
  bool _clientsLoaded = false;
  bool _isSendingInvite = false;
  bool _isSavingAccess = false;
  bool _isProvisioningInternalUser = false;
  Object? _usersLoadError;
  Object? _clientsLoadError;
  String _userSearchQuery = '';
  String _clientSearchQuery = '';
  _AccessRoleFilter _roleFilter = _AccessRoleFilter.all;
  _AccessChangeFilter _changeFilter = _AccessChangeFilter.all;
  ClientPortalAccessStatus? _clientStatusFilter;
  int _visibleUserCount = _initialVisibleItems;
  int _visibleClientCount = _initialVisibleItems;
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
    _tabController.addListener(_handleTabChange);
    _loadActiveTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _userSearchController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    _loadActiveTab();
  }

  void _loadActiveTab() {
    if (_tabController.index == 0) {
      _loadUsers();
    } else {
      _loadClients();
    }
  }

  Future<void> _loadUsers({bool force = false}) async {
    if (_isLoadingUsers || (_usersLoaded && !force)) return;

    setState(() {
      _isLoadingUsers = true;
      _usersLoadError = null;
    });
    try {
      final users = await _accessService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _usersLoaded = true;
        _draftUsers.clear();
        _visibleUserCount = _initialVisibleItems;
        final userIds = users.map((user) => user.uid).toSet();
        _expandedUserIds.removeWhere((id) => !userIds.contains(id));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _usersLoadError = error);
      _showFeedback(
        'Nao foi possivel carregar usuarios: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _loadClients({bool force = false}) async {
    if (_isLoadingClients || (_clientsLoaded && !force)) return;

    setState(() {
      _isLoadingClients = true;
      _clientsLoadError = null;
    });
    try {
      final clients = await _clientAccountService.getClientAccounts();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _clientsLoaded = true;
        _visibleClientCount = _initialVisibleItems;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _clientsLoadError = error);
      _showFeedback(
        'Nao foi possivel carregar clientes: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingClients = false);
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
      await _loadUsers(force: true);
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

  Future<void> _openInternalUserDialog() async {
    List<EmployeeAccessBinding> employees = const [];
    try {
      employees = await _accessService.getActiveEmployeeBindings();
    } catch (_) {
      employees = const [];
    }

    if (!mounted) return;
    final result = await _InternalUserDialog.show(
      context,
      employees: employees,
    );
    if (result == null || _isProvisioningInternalUser) return;

    setState(() => _isProvisioningInternalUser = true);
    try {
      final user = await _accessService.createInternalUser(
        username: result.username,
        password: result.password,
        displayName: result.displayName,
        role: result.role,
        permissions: const [],
        employeeId: result.employeeId,
        employeeName: result.employeeName,
      );
      await _loadUsers(force: true);
      if (!mounted) return;
      setState(() {
        _expandedUserIds.add(user.uid);
      });
      _showFeedback('Usuario interno criado com sucesso.');
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        error is InternalUserProvisionException ? error.message : '$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProvisioningInternalUser = false);
      }
    }
  }

  Future<void> _resetInternalUserPassword(UserModel user) async {
    final password = await _InternalPasswordResetDialog.show(context, user);
    if (password == null || _isProvisioningInternalUser) return;

    setState(() => _isProvisioningInternalUser = true);
    try {
      await _accessService.resetInternalUserPassword(
        user: user,
        password: password,
      );
      if (!mounted) return;
      _showFeedback('Senha do usuario interno redefinida.');
    } catch (error) {
      if (!mounted) return;
      _showFeedback(
        error is InternalUserProvisionException ? error.message : '$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProvisioningInternalUser = false);
      }
    }
  }

  List<UserModel> get _changedAccessUsers {
    final originalsById = {for (final user in _users) user.uid: user};
    return _draftUsers.values.where((draft) {
      final original = originalsById[draft.uid];
      return original != null && _hasAccessChanged(original, draft);
    }).toList();
  }

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

  List<UserModel> get _filteredUsers {
    final query = _normalizeSearchText(_userSearchQuery);
    return _users.where((user) {
      final draft = _draftFor(user);
      if (!_matchesRoleFilter(draft.role)) return false;
      if (!_matchesChangeFilter(user, draft)) return false;
      if (query.isEmpty) return true;

      final selectedPermissionLabels = _knownPermissions
          .where((permission) => draft.permissions.contains(permission.code))
          .map((permission) => permission.label);
      final searchableText = _normalizeSearchText(
        [
          user.displayName,
          user.username,
          user.email,
          user.status,
          user.clientAccountName,
          draft.role.displayName,
          draft.permissions.join(' '),
          selectedPermissionLabels.join(' '),
        ].whereType<String>().join(' '),
      );
      return searchableText.contains(query);
    }).toList();
  }

  List<ClientAccount> get _filteredClients {
    final query = _normalizeSearchText(_clientSearchQuery);
    return _clients.where((client) {
      if (_clientStatusFilter != null &&
          client.portalAccessStatus != _clientStatusFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final searchableText = _normalizeSearchText(
        [
          client.name,
          client.ownerEmail,
          client.contactEmail,
          client.contactPhone,
          client.status,
          client.portalAccessStatus.label,
          client.notes,
        ].join(' '),
      );
      return searchableText.contains(query);
    }).toList();
  }

  String _normalizeSearchText(String value) => value.toLowerCase().trim();

  bool _matchesRoleFilter(UserRole role) {
    switch (_roleFilter) {
      case _AccessRoleFilter.all:
        return true;
      case _AccessRoleFilter.admin:
        return role == UserRole.admin;
      case _AccessRoleFilter.employee:
        return role == UserRole.employee;
      case _AccessRoleFilter.client:
        return role == UserRole.client;
    }
  }

  bool _matchesChangeFilter(UserModel original, UserModel draft) {
    final changed = _hasAccessChanged(original, draft);
    switch (_changeFilter) {
      case _AccessChangeFilter.all:
        return true;
      case _AccessChangeFilter.changed:
        return changed;
      case _AccessChangeFilter.unchanged:
        return !changed;
    }
  }

  void _setRoleFilter(_AccessRoleFilter filter) {
    setState(() {
      _roleFilter = filter;
      _visibleUserCount = _initialVisibleItems;
    });
  }

  void _setChangeFilter(_AccessChangeFilter filter) {
    setState(() {
      _changeFilter = filter;
      _visibleUserCount = _initialVisibleItems;
    });
  }

  void _setClientStatusFilter(ClientPortalAccessStatus? status) {
    setState(() {
      _clientStatusFilter = status;
      _visibleClientCount = _initialVisibleItems;
    });
  }

  void _toggleUserEditor(String userId) {
    setState(() {
      if (_expandedUserIds.contains(userId)) {
        _expandedUserIds.remove(userId);
      } else {
        _expandedUserIds.add(userId);
      }
    });
  }

  void _clearUserFilters() {
    setState(() {
      _userSearchController.clear();
      _userSearchQuery = '';
      _roleFilter = _AccessRoleFilter.all;
      _changeFilter = _AccessChangeFilter.all;
      _visibleUserCount = _initialVisibleItems;
    });
  }

  void _clearClientFilters() {
    setState(() {
      _clientSearchController.clear();
      _clientSearchQuery = '';
      _clientStatusFilter = null;
      _visibleClientCount = _initialVisibleItems;
    });
  }

  Map<String, List<_PermissionOption>> _groupPermissionOptions(
    List<_PermissionOption> options,
  ) {
    final groups = <String, List<_PermissionOption>>{};
    for (final option in options) {
      groups
          .putIfAbsent(_permissionGroupFor(option.code), () => [])
          .add(option);
    }
    return groups;
  }

  String _permissionGroupFor(String code) {
    if (code.startsWith('projects.') ||
        code == 'obras' ||
        code == 'diario' ||
        code == 'medicoes') {
      return 'Projetos e obras';
    }
    if (code.startsWith('budgets.') || code == 'relatorios') {
      return 'Orcamentos e relatorios';
    }
    if (code.startsWith('financial.') ||
        code.startsWith('purchase_finance.') ||
        code == 'financeiro') {
      return 'Financeiro';
    }
    if (code.startsWith('inventory.') ||
        code.startsWith('purchases.') ||
        code == 'suprimentos' ||
        code == 'compras' ||
        code == 'estoque') {
      return 'Suprimentos';
    }
    if (code.startsWith('people.') || code == 'rh') {
      return 'Pessoas e RH';
    }
    if (code.startsWith('mobile.') || code.startsWith('time_clock.')) {
      return 'Mobile e campo';
    }
    if (code == 'portal_cliente') {
      return 'Portal do cliente';
    }
    if (code.startsWith('access.') ||
        code.startsWith('settings.') ||
        code.startsWith('billing.') ||
        code.startsWith('ai.') ||
        code == 'admin') {
      return 'Administracao';
    }
    return 'Outras permissoes';
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.accentGold;
      case UserRole.employee:
        return AppColors.accentBlue;
      case UserRole.client:
        return AppColors.accentGreen;
    }
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

      await _loadClients(force: true);
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
      await _loadClients(force: true);
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
                child: TabBarView(
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
    if (_usersLoadError != null && _users.isEmpty) {
      return _buildLoadErrorState(
        title: 'Nao foi possivel carregar usuarios',
        message: _usersLoadError.toString(),
        onRetry: () => _loadUsers(force: true),
      );
    }
    if (!_usersLoaded) {
      return _buildLoadingState('Carregando usuarios...');
    }

    final filteredUsers = _filteredUsers;
    final visibleUsers = filteredUsers.take(_visibleUserCount).toList();
    final hasMoreUsers = visibleUsers.length < filteredUsers.length;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: _hasPendingAccessChanges ? 96 : 12),
          children: [
            _buildUsersToolbar(
              totalCount: _users.length,
              filteredCount: filteredUsers.length,
              changedCount: changedCount,
            ),
            const SizedBox(height: 16),
            if (_users.isEmpty)
              _buildEmptyUsersState()
            else if (filteredUsers.isEmpty)
              _buildNoMatchesState(
                icon: Icons.manage_search_rounded,
                title: 'Nenhum usuario encontrado',
                message: 'Ajuste a busca ou remova os filtros aplicados.',
                onClear: _clearUserFilters,
              )
            else ...[
              for (final user in visibleUsers) ...[
                _buildUserAccessCard(user),
                const SizedBox(height: 14),
              ],
              if (hasMoreUsers)
                _buildLoadMoreButton(
                  visibleCount: visibleUsers.length,
                  totalCount: filteredUsers.length,
                  onPressed: () {
                    setState(() {
                      _visibleUserCount += _visibleItemsStep;
                    });
                  },
                ),
            ],
          ],
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
    if (_clientsLoadError != null && _clients.isEmpty) {
      return _buildLoadErrorState(
        title: 'Nao foi possivel carregar clientes',
        message: _clientsLoadError.toString(),
        onRetry: () => _loadClients(force: true),
      );
    }
    if (!_clientsLoaded) {
      return _buildLoadingState('Carregando clientes...');
    }

    final filteredClients = _filteredClients;
    final visibleClients = filteredClients.take(_visibleClientCount).toList();
    final hasMoreClients = visibleClients.length < filteredClients.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _buildClientsToolbar(
          totalCount: _clients.length,
          filteredCount: filteredClients.length,
        ),
        const SizedBox(height: 16),
        if (_clients.isEmpty)
          _buildEmptyClientsState()
        else if (filteredClients.isEmpty)
          _buildNoMatchesState(
            icon: Icons.manage_search_rounded,
            title: 'Nenhum cliente encontrado',
            message: 'Ajuste a busca ou remova os filtros aplicados.',
            onClear: _clearClientFilters,
          )
        else ...[
          for (final client in visibleClients) ...[
            _buildClientAccountCard(client),
            const SizedBox(height: 14),
          ],
          if (hasMoreClients)
            _buildLoadMoreButton(
              visibleCount: visibleClients.length,
              totalCount: filteredClients.length,
              onPressed: () {
                setState(() {
                  _visibleClientCount += _visibleItemsStep;
                });
              },
            ),
        ],
      ],
    );
  }

  Widget _buildUsersToolbar({
    required int totalCount,
    required int filteredCount,
    required int changedCount,
  }) {
    final adminCount = _users.where((user) => _draftFor(user).isAdmin).length;
    final clientCount = _users.where((user) => _draftFor(user).isClient).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usuarios do sistema',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$filteredCount de $totalCount usuarios na visualizacao',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              );
              final refreshButton = OutlinedButton.icon(
                onPressed:
                    _isLoadingUsers ? null : () => _loadUsers(force: true),
                icon:
                    _isLoadingUsers
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              );
              final createInternalButton = ElevatedButton.icon(
                onPressed:
                    _isProvisioningInternalUser
                        ? null
                        : _openInternalUserDialog,
                icon:
                    _isProvisioningInternalUser
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Criar usuario interno'),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: createInternalButton,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: refreshButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  createInternalButton,
                  const SizedBox(width: 10),
                  refreshButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              labelText: 'Buscar usuario',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  _userSearchQuery.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          setState(() {
                            _userSearchController.clear();
                            _userSearchQuery = '';
                            _visibleUserCount = _initialVisibleItems;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
            ),
            onChanged: (value) {
              setState(() {
                _userSearchQuery = value;
                _visibleUserCount = _initialVisibleItems;
              });
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Todos',
                selected: _roleFilter == _AccessRoleFilter.all,
                onSelected: () => _setRoleFilter(_AccessRoleFilter.all),
              ),
              _buildFilterChip(
                label: 'Administradores',
                selected: _roleFilter == _AccessRoleFilter.admin,
                onSelected: () => _setRoleFilter(_AccessRoleFilter.admin),
              ),
              _buildFilterChip(
                label: 'Colaboradores',
                selected: _roleFilter == _AccessRoleFilter.employee,
                onSelected: () => _setRoleFilter(_AccessRoleFilter.employee),
              ),
              _buildFilterChip(
                label: 'Clientes',
                selected: _roleFilter == _AccessRoleFilter.client,
                onSelected: () => _setRoleFilter(_AccessRoleFilter.client),
              ),
              _buildFilterChip(
                label: 'Alterados',
                selected: _changeFilter == _AccessChangeFilter.changed,
                color: AppColors.accentGold,
                onSelected: () => _setChangeFilter(_AccessChangeFilter.changed),
              ),
              _buildFilterChip(
                label: 'Sem alteracao',
                selected: _changeFilter == _AccessChangeFilter.unchanged,
                onSelected:
                    () => _setChangeFilter(_AccessChangeFilter.unchanged),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricPill(
                icon: Icons.people_alt_outlined,
                value: totalCount.toString(),
                label: 'total',
                color: AppColors.accentBlue,
              ),
              _buildMetricPill(
                icon: Icons.admin_panel_settings_outlined,
                value: adminCount.toString(),
                label: 'admins',
                color: AppColors.accentGold,
              ),
              _buildMetricPill(
                icon: Icons.business_center_outlined,
                value: clientCount.toString(),
                label: 'clientes',
                color: AppColors.accentGreen,
              ),
              _buildMetricPill(
                icon: Icons.edit_note_rounded,
                value: changedCount.toString(),
                label: 'pendentes',
                color: AppColors.accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsToolbar({
    required int totalCount,
    required int filteredCount,
  }) {
    final pendingCount =
        _clients
            .where(
              (client) =>
                  client.portalAccessStatus == ClientPortalAccessStatus.pending,
            )
            .length;
    final invitedCount =
        _clients
            .where(
              (client) =>
                  client.portalAccessStatus == ClientPortalAccessStatus.invited,
            )
            .length;
    final activeCount =
        _clients
            .where(
              (client) =>
                  client.portalAccessStatus == ClientPortalAccessStatus.active,
            )
            .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clientes do portal',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$filteredCount de $totalCount clientes na visualizacao',
                    style: const TextStyle(color: AppColors.textSecondary),
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
                    title,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: action),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _clientSearchController,
            decoration: InputDecoration(
              labelText: 'Buscar cliente',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  _clientSearchQuery.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          setState(() {
                            _clientSearchController.clear();
                            _clientSearchQuery = '';
                            _visibleClientCount = _initialVisibleItems;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
            ),
            onChanged: (value) {
              setState(() {
                _clientSearchQuery = value;
                _visibleClientCount = _initialVisibleItems;
              });
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Todos',
                selected: _clientStatusFilter == null,
                onSelected: () => _setClientStatusFilter(null),
              ),
              _buildFilterChip(
                label: 'Sem acesso',
                selected:
                    _clientStatusFilter == ClientPortalAccessStatus.pending,
                color: AppColors.accentGold,
                onSelected:
                    () => _setClientStatusFilter(
                      ClientPortalAccessStatus.pending,
                    ),
              ),
              _buildFilterChip(
                label: 'Convidados',
                selected:
                    _clientStatusFilter == ClientPortalAccessStatus.invited,
                color: AppColors.accentBlue,
                onSelected:
                    () => _setClientStatusFilter(
                      ClientPortalAccessStatus.invited,
                    ),
              ),
              _buildFilterChip(
                label: 'Ativos',
                selected:
                    _clientStatusFilter == ClientPortalAccessStatus.active,
                color: AppColors.accentGreen,
                onSelected:
                    () =>
                        _setClientStatusFilter(ClientPortalAccessStatus.active),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricPill(
                icon: Icons.people_alt_outlined,
                value: totalCount.toString(),
                label: 'total',
                color: AppColors.accentBlue,
              ),
              _buildMetricPill(
                icon: Icons.mail_outline_rounded,
                value: pendingCount.toString(),
                label: 'sem acesso',
                color: AppColors.accentGold,
              ),
              _buildMetricPill(
                icon: Icons.mark_email_read_outlined,
                value: invitedCount.toString(),
                label: 'convidados',
                color: AppColors.accentBlue,
              ),
              _buildMetricPill(
                icon: Icons.verified_user_outlined,
                value: activeCount.toString(),
                label: 'ativos',
                color: AppColors.accentGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAccessCard(UserModel user) {
    final draft = _draftFor(user);
    final hasChanges = _hasAccessChanged(user, draft);
    final expanded = _expandedUserIds.contains(user.uid);
    final roleColor = _roleColor(draft.role);
    final displayName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email;
    final loginLabel =
        user.isInternalCredential
            ? 'Usuario: ${user.username ?? '-'}'
            : user.email;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: hasChanges ? AppColors.accentGold : roleColor,
        emphasized: hasChanges,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: AppDecorations.iconTile(roleColor),
                    child: Icon(_roleIcon(draft.role), color: roleColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loginLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (user.isInternalCredential) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Acesso interno por usuario e senha',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                        if (user.clientAccountName?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.clientAccountName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
              final action = TextButton.icon(
                onPressed: () => _toggleUserEditor(user.uid),
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.tune_rounded,
                ),
                label: Text(expanded ? 'Recolher' : 'Editar permissoes'),
              );
              final tags = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _buildTag(
                    label: draft.role.displayName,
                    icon: _roleIcon(draft.role),
                    color: roleColor,
                  ),
                  _buildTag(
                    label:
                        draft.permissions.length == 1
                            ? '1 permissao'
                            : '${draft.permissions.length} permissoes',
                    icon: Icons.key_rounded,
                    color: AppColors.accentBlue,
                  ),
                  if (user.isInternalCredential)
                    _buildTag(
                      label: 'Login interno',
                      icon: Icons.account_circle_outlined,
                      color: AppColors.accentGreen,
                    ),
                  if (hasChanges)
                    _buildTag(
                      label: 'Alterado',
                      icon: Icons.edit_note_rounded,
                      color: AppColors.accentGold,
                    ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 12),
                    tags,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: action),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: identity),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(alignment: Alignment.centerRight, child: tags),
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerRight, child: action),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.dividerColor.withValues(alpha: 0.72)),
            const SizedBox(height: 16),
            _buildUserAccessEditor(user, draft),
          ],
        ],
      ),
    );
  }

  Widget _buildUserAccessEditor(UserModel original, UserModel draft) {
    final hasChanges = _hasAccessChanged(original, draft);
    final groupedPermissions = _groupPermissionOptions(
      _permissionOptionsFor(draft),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < ResponsiveLayout.compact;
            final roleField = SizedBox(
              width: isNarrow ? double.infinity : 240,
              child: DropdownButtonFormField<UserRole>(
                key: ValueKey('${original.uid}-${draft.role.name}-role'),
                initialValue: draft.role,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de usuario'),
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
                  _stageUserAccess(original, draft.copyWith(role: role));
                },
              ),
            );
            final undoButton = OutlinedButton.icon(
              onPressed:
                  hasChanges
                      ? () {
                        setState(() {
                          _draftUsers.remove(original.uid);
                        });
                      }
                      : null,
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Desfazer'),
            );
            final resetPasswordButton = OutlinedButton.icon(
              onPressed:
                  original.isInternalCredential && !_isProvisioningInternalUser
                      ? () => _resetInternalUserPassword(original)
                      : null,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Redefinir senha'),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  roleField,
                  const SizedBox(height: 10),
                  if (original.isInternalCredential) ...[
                    SizedBox(
                      width: double.infinity,
                      child: resetPasswordButton,
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(width: double.infinity, child: undoButton),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                roleField,
                const Spacer(),
                if (original.isInternalCredential) ...[
                  resetPasswordButton,
                  const SizedBox(width: 10),
                ],
                undoButton,
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        for (final entry in groupedPermissions.entries) ...[
          _buildPermissionGroup(
            original: original,
            draft: draft,
            title: entry.key,
            permissions: entry.value,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPermissionGroup({
    required UserModel original,
    required UserModel draft,
    required String title,
    required List<_PermissionOption> permissions,
  }) {
    final selectedCount =
        permissions
            .where((permission) => draft.permissions.contains(permission.code))
            .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardInnerSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildTag(
                label: '$selectedCount/${permissions.length}',
                icon: Icons.check_circle_outline_rounded,
                color:
                    selectedCount == 0
                        ? AppColors.textMuted
                        : AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                permissions.map((permission) {
                  final selected = draft.permissions.contains(permission.code);
                  return Tooltip(
                    message:
                        '${permission.description}\nCodigo interno: ${permission.code}',
                    child: FilterChip(
                      label: Text(permission.label),
                      selected: selected,
                      onSelected: (value) {
                        final currentPermissions = draft.permissions.toSet();
                        if (value) {
                          currentPermissions.add(permission.code);
                        } else {
                          currentPermissions.remove(permission.code);
                        }
                        _stageUserAccess(
                          original,
                          draft.copyWith(
                            permissions: _normalizePermissions(
                              currentPermissions,
                            ),
                          ),
                        );
                      },
                      selectedColor: AppColors.accentBlue.withValues(
                        alpha: 0.18,
                      ),
                      backgroundColor: AppColors.surfaceDark.withValues(
                        alpha: 0.52,
                      ),
                      labelStyle: TextStyle(
                        color:
                            selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color:
                            selected
                                ? AppColors.accentBlue
                                : AppColors.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientAccountCard(ClientAccount client) {
    final inviteActionLabel = _getInviteActionLabel(client.portalAccessStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: _statusColor(client.portalAccessStatus),
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 640;
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: AppDecorations.iconTile(
                      _statusColor(client.portalAccessStatus),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: _statusColor(client.portalAccessStatus),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Conta do portal: ${client.ownerEmail}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (client.contactPhone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            client.contactPhone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
              final status = _PortalStatusChip(
                status: client.portalAccessStatus,
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identity, const SizedBox(height: 12), status],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  status,
                ],
              );
            },
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
                    _isSendingInvite ? null : () => _sendPortalInvite(client),
                icon: Icon(_getInviteActionIcon(client.portalAccessStatus)),
                label: Text(inviteActionLabel),
              );

              if (constraints.maxWidth < ResponsiveLayout.compact) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: editButton),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: inviteButton),
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
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accentBlue),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLoadErrorState({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.cardSurface(
          accent: AppColors.accentRed,
          radius: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accentRed,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUsersState() {
    return _buildNoMatchesState(
      icon: Icons.people_outline_rounded,
      title: 'Nenhum usuario cadastrado',
      message: 'Os usuarios aparecerao aqui quando forem criados no sistema.',
    );
  }

  Widget _buildNoMatchesState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onClear,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: AppDecorations.iconTile(AppColors.accentBlue),
            child: Icon(icon, color: AppColors.accentBlue),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton({
    required int visibleCount,
    required int totalCount,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.expand_more_rounded),
        label: Text('Mostrar mais ($visibleCount de $totalCount)'),
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.cardInnerSurface(accent: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 9),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Color color = AppColors.accentBlue,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.46),
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color:
            selected
                ? color.withValues(alpha: 0.7)
                : AppColors.borderColor.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.employee:
        return Icons.badge_rounded;
      case UserRole.client:
        return Icons.handshake_rounded;
    }
  }

  Color _statusColor(ClientPortalAccessStatus status) {
    switch (status) {
      case ClientPortalAccessStatus.pending:
        return AppColors.accentGold;
      case ClientPortalAccessStatus.invited:
        return AppColors.accentBlue;
      case ClientPortalAccessStatus.active:
        return AppColors.accentGreen;
    }
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

class _InternalUserDialogResult {
  final String username;
  final String displayName;
  final String password;
  final UserRole role;
  final String? employeeId;
  final String? employeeName;

  const _InternalUserDialogResult({
    required this.username,
    required this.displayName,
    required this.password,
    required this.role,
    this.employeeId,
    this.employeeName,
  });
}

class _InternalUserDialog extends StatefulWidget {
  final List<EmployeeAccessBinding> employees;

  const _InternalUserDialog({required this.employees});

  static Future<_InternalUserDialogResult?> show(
    BuildContext context, {
    required List<EmployeeAccessBinding> employees,
  }) {
    return showDialog<_InternalUserDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InternalUserDialog(employees: employees),
    );
  }

  @override
  State<_InternalUserDialog> createState() => _InternalUserDialogState();
}

class _InternalUserDialogState extends State<_InternalUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _role = UserRole.employee;
  EmployeeAccessBinding? _selectedEmployee;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final inset = size.width < 420 ? 8.0 : 24.0;
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 520.0);

    return AlertDialog(
      insetPadding: EdgeInsets.all(inset),
      title: const Text('Criar usuario interno'),
      content: SizedBox(
        width: dialogWidth.toDouble(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do colaborador',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o nome'
                              : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  validator: (value) => validateInternalUsername(value ?? ''),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de usuario',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items:
                      const [UserRole.employee, UserRole.admin]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.displayName),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _role = value ?? _role),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<EmployeeAccessBinding>(
                  initialValue: _selectedEmployee,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Colaborador vinculado',
                    prefixIcon: Icon(Icons.engineering_outlined),
                  ),
                  hint: const Text('Opcional, mas recomendado para o mobile'),
                  items:
                      widget.employees
                          .map(
                            (employee) => DropdownMenuItem(
                              value: employee,
                              child: Text(employee.displayLabel),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEmployee = value;
                      if (value != null &&
                          _displayNameController.text.trim().isEmpty) {
                        _displayNameController.text = value.name;
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha inicial',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 8) {
                      return 'Minimo de 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'As senhas nao conferem';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Criar usuario'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _InternalUserDialogResult(
        username: normalizeInternalUsername(_usernameController.text),
        displayName: _displayNameController.text.trim(),
        password: _passwordController.text,
        role: _role,
        employeeId: _selectedEmployee?.id,
        employeeName: _selectedEmployee?.name,
      ),
    );
  }
}

class _InternalPasswordResetDialog extends StatefulWidget {
  final UserModel user;

  const _InternalPasswordResetDialog({required this.user});

  static Future<String?> show(BuildContext context, UserModel user) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InternalPasswordResetDialog(user: user),
    );
  }

  @override
  State<_InternalPasswordResetDialog> createState() =>
      _InternalPasswordResetDialogState();
}

class _InternalPasswordResetDialogState
    extends State<_InternalPasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Redefinir senha de ${widget.user.username ?? 'usuario'}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 8) {
                    return 'Minimo de 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'As senhas nao conferem';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('Salvar senha'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_passwordController.text);
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
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile.adaptive(
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
