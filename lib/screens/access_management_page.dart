import 'package:flutter/material.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/access_management_service.dart';
import 'package:project_granith/services/client_account_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class AccessManagementPage extends StatefulWidget {
  const AccessManagementPage({super.key});

  @override
  State<AccessManagementPage> createState() => _AccessManagementPageState();
}

class _AccessManagementPageState extends State<AccessManagementPage>
    with SingleTickerProviderStateMixin {
  final AccessManagementService _accessService = AccessManagementService();
  final ClientAccountService _clientAccountService = ClientAccountService();
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
  List<UserModel> _users = [];
  List<ClientAccount> _clients = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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
    final result = await showDialog<ClientAccount>(
      context: context,
      builder: (_) => _ClientAccountDialog(client: client),
    );

    if (result == null) return;
    await _clientAccountService.saveClientAccount(result);
    await _loadData();
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
                'Gerencie papeis de acesso e cadastre clientes que terao portal proprio.',
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentBlue,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUsersTab(),
                          _buildClientsTab(),
                        ],
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
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<UserRole>(
                      initialValue: user.role,
                      decoration: const InputDecoration(labelText: 'Papel'),
                      items: UserRole.values
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
                children: _availablePermissions.map((permission) {
                  final selected = user.permissions.contains(permission);
                  return FilterChip(
                    label: Text(permission),
                    selected: selected,
                    onSelected: (value) {
                      final permissions = List<String>.from(user.permissions);
                      if (value) {
                        permissions.add(permission);
                      } else {
                        permissions.remove(permission);
                      }
                      _saveUser(user.copyWith(permissions: permissions));
                    },
                    selectedColor: AppColors.accentBlue.withValues(alpha: 0.18),
                    backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.5),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.accentBlue
                          : AppColors.borderColor.withValues(alpha: 0.65),
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
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _openClientDialog(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Cadastrar cliente'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _clients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final client = _clients[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openClientDialog(client),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderColor.withValues(alpha: 0.65),
                    ),
                    boxShadow: AppColors.glowShadows(),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentBlue.withValues(alpha: 0.12),
                          boxShadow: AppColors.auraShadows(AppColors.accentBlue),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
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

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _ownerEmailController = TextEditingController(text: client?.ownerEmail ?? '');
    _contactEmailController =
        TextEditingController(text: client?.contactEmail ?? '');
    _contactPhoneController =
        TextEditingController(text: client?.contactPhone ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');
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
    return AlertDialog(
      title: Text(widget.client == null ? 'Cadastrar cliente' : 'Editar cliente'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do cliente'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ownerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail da conta do portal',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o e-mail da conta'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(labelText: 'E-mail comercial'),
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
              base.copyWith(
                id: base.id.isEmpty
                    ? DateTime.now().millisecondsSinceEpoch.toString()
                    : base.id,
                name: _nameController.text,
                ownerEmail: _ownerEmailController.text,
                contactEmail: _contactEmailController.text,
                contactPhone: _contactPhoneController.text,
                notes: _notesController.text,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
