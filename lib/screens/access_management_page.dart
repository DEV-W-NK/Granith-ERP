import 'package:flutter/material.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/access_management_service.dart';
import 'package:project_granith/services/client_account_service.dart';
import 'package:project_granith/services/client_portal_access_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class AccessManagementPage extends StatefulWidget {
  final int initialTabIndex;

  const AccessManagementPage({super.key, this.initialTabIndex = 0});

  @override
  State<AccessManagementPage> createState() => _AccessManagementPageState();
}

class _AccessManagementPageState extends State<AccessManagementPage>
    with SingleTickerProviderStateMixin {
  final AccessManagementService _accessService = AccessManagementService();
  final ClientAccountService _clientAccountService = ClientAccountService();
  final ClientPortalAccessService _clientPortalAccessService =
      ClientPortalAccessService();

  final List<String> _availablePermissions = const [
    'projects.read',
    'projects.write',
    'budgets.read',
    'budgets.write',
    'financial.read',
    'inventory.read',
    'people.manage',
    'access.manage',
  ];

  late final TabController _tabController;
  bool _isLoading = true;
  bool _isSendingInvite = false;
  List<UserModel> _users = [];
  List<ClientAccount> _clients = [];

  @override
  void initState() {
    super.initState();
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
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUser(UserModel user) async {
    await _accessService.updateUserAccess(user);
    await _loadData();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Gerencie papeis internos e o fluxo de portal do cliente, desde o cadastro ate o convite de primeiro acesso.',
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
                  indicatorColor: AppColors.accentBlue,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Usuarios e Permissoes'),
                    Tab(text: 'Cadastro de Clientes'),
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
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.65),
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<UserRole>(
                      initialValue: user.role,
                      decoration: const InputDecoration(labelText: 'Papel'),
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
                        _saveUser(user.copyWith(role: role));
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
                    _availablePermissions.map((permission) {
                      final selected = user.permissions.contains(permission);
                      return FilterChip(
                        label: Text(permission),
                        selected: selected,
                        onSelected: (value) {
                          final permissions = List<String>.from(
                            user.permissions,
                          );
                          if (value) {
                            permissions.add(permission);
                          } else {
                            permissions.remove(permission);
                          }
                          _saveUser(user.copyWith(permissions: permissions));
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
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
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
              final isNarrow = constraints.maxWidth < 620;
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

                                if (constraints.maxWidth < 520) {
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

    return AlertDialog(
      title: Text(isEditing ? 'Editar cliente' : 'Cadastrar cliente'),
      content: SizedBox(
        width: 560,
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
