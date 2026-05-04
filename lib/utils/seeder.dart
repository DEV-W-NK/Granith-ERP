import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DatabaseSeeder {
  DatabaseSeeder();

  SupabaseClient get _supabase => AppSupabase.client;

  static const Uuid _uuid = Uuid();
  static const String _seedUuidNamespace =
      '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  static const String _clientAtlas = 'seed-client-atlas';
  static const String _clientVista = 'seed-client-vista';
  static const String _clientLogprime = 'seed-client-logprime';

  static const String _projectAtlas = 'seed-project-atlas-torre-b';
  static const String _projectVista = 'seed-project-vista-centro-cirurgico';
  static const String _projectLogprime = 'seed-project-logprime-galpao';
  static const String _projectCasaModelo = 'seed-project-atlas-casa-modelo';

  static const String _adminUser = 'seed-user-admin';
  static const String _engineerUser = 'seed-user-engineer';
  static const String _financeUser = 'seed-user-finance';
  static const String _buyerUser = 'seed-user-buyer';
  static const String _clientUser = 'seed-user-client-atlas';

  static const List<String> _requiredSupabaseTables = [
    'system_settings',
    'client_accounts',
    'users',
    'budget_types',
    'job_roles',
    'items',
    'suppliers',
    'employees',
    'projects',
    'project_measurements',
    'budgets',
    'teams',
    'benefits',
    'employee_benefits',
    'salary_history',
    'purchases',
    'inventory',
    'inventory_movements',
    'material_requisitions',
    'daily_logs',
    'financial_transactions',
    'talent_candidates',
    'usage_stats',
  ];

  Future<bool> seed() async {
    final now = DateTime.now().toUtc();

    print('SEEDER: iniciando base realista Granith ERP...');

    try {
      await _assertSupabaseSchemaReady();
      await _seedSupabase(now);
      print('SEEDER: base realista criada/atualizada com sucesso.');
      return true;
    } catch (error, stackTrace) {
      print('SEEDER: erro critico: $error');
      print(stackTrace);
      return false;
    }
  }

  Future<bool> ensureSyncedWithEmulator({int timeoutSeconds = 20}) async {
    return seed();
  }

  Future<void> _assertSupabaseSchemaReady() async {
    for (final table in _requiredSupabaseTables) {
      try {
        await _supabase.from(table).select('id').limit(1);
      } catch (error) {
        if (_isMissingTableError(error)) {
          throw Exception(
            'Schema Supabase incompleto: a tabela public.$table nao existe. '
            'Aplique as migrations do projeto antes de executar o seeder '
            '(ex.: npx supabase db push).',
          );
        }

        rethrow;
      }
    }
  }

  bool _isMissingTableError(Object error) {
    final message = error.toString();
    return message.contains('PGRST205') ||
        message.contains('Could not find the table');
  }

  Future<void> _seedSupabase(DateTime now) async {
    await _upsertSupabase('system_settings', _systemSettings(now));
    await _upsertSupabase('client_accounts', _clientAccounts(now));
    await _upsertSupabase('users', _users(now));
    await _upsertSupabase('budget_types', _budgetTypes(now));
    await _upsertSupabase('job_roles', _jobRoles(now));
    await _upsertSupabase('items', _items(now));
    await _upsertSupabase('suppliers', _suppliers(now));
    await _upsertSupabase('employees', _employees(now));
    await _upsertSupabase('projects', _projects(now));
    await _upsertSupabase('project_measurements', _projectMeasurements(now));
    await _upsertSupabase('budgets', _budgets(now));
    await _upsertSupabase('teams', _teams(now));
    await _upsertSupabase('benefits', _benefits(now));
    await _upsertSupabase('employee_benefits', _employeeBenefits(now));
    await _upsertSupabase('salary_history', _salaryHistory(now));
    await _upsertSupabase('purchases', _purchases(now));
    await _upsertSupabase('inventory', _inventory(now));
    await _upsertSupabase('inventory_movements', _inventoryMovements(now));
    await _upsertSupabase('material_requisitions', _materialRequisitions(now));
    await _upsertSupabase('daily_logs', _dailyLogs(now));
    await _upsertSupabase(
      'financial_transactions',
      _financialTransactions(now),
    );
    await _upsertSupabase('talent_candidates', _talentCandidates(now));
    await _upsertSupabase('usage_stats', _usageStats(now));
  }

  Future<void> _upsertSupabase(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    print('SEEDER: Supabase $table (${rows.length})');

    final payload = rows.map(_toSupabaseMap).map(DbValue.normalizeMap).toList();
    await _supabase.from(table).upsert(payload);
  }

  Map<String, dynamic> _toSupabaseMap(Map<String, dynamic> input) {
    return input.map((key, value) => MapEntry(key, _toSupabaseValue(value)));
  }

  // Seed data keeps readable IDs; Supabase receives stable UUIDs.
  dynamic _toSupabaseValue(dynamic value) {
    if (value is String && value.startsWith('seed-')) {
      return _uuid.v5(_seedUuidNamespace, value);
    }
    if (value is List) return value.map(_toSupabaseValue).toList();
    if (value is Map) {
      return value.map(
        (key, innerValue) =>
            MapEntry(key.toString(), _toSupabaseValue(innerValue)),
      );
    }
    return value;
  }

  int _ms(DateTime date) => date.millisecondsSinceEpoch;

  DateTime _daysAgo(DateTime now, int days) =>
      now.subtract(Duration(days: days));
  DateTime _daysFromNow(DateTime now, int days) =>
      now.add(Duration(days: days));

  List<Map<String, dynamic>> _systemSettings(DateTime now) {
    return [
      {
        'id': 'default',
        'workspace_name': 'GRANITH',
        'workspace_tagline': 'ERP de obras e contratos',
        'dashboard_greeting_title': 'Painel executivo',
        'dashboard_greeting_subtitle':
            'Base demonstrativa com operacao completa de cliente real.',
        'ai_assistant_preview_enabled': true,
        'compact_navigation': false,
        'support_email': 'suporte@granitherp.com.br',
        'support_phone': '(11) 4002-2026',
        'client_portal_welcome_message':
            'Acompanhe contratos, medicoes, propostas e custos das obras vinculadas a sua conta.',
        'client_portal_show_budgets': true,
        'client_portal_show_budget_values': true,
        'client_portal_show_current_costs': true,
        'updated_at': now,
      },
    ];
  }

  List<Map<String, dynamic>> _clientAccounts(DateTime now) {
    return [
      {
        'id': _clientAtlas,
        'name': 'Atlas Residencial SPE Ltda',
        'ownerEmail': 'marina.ferraz@atlasresidencial.com.br',
        'owner_email': 'marina.ferraz@atlasresidencial.com.br',
        'contactEmail': 'obras@atlasresidencial.com.br',
        'contact_email': 'obras@atlasresidencial.com.br',
        'contactPhone': '(11) 3020-4100',
        'contact_phone': '(11) 3020-4100',
        'status': 'ativo',
        'notes':
            'Cliente principal do seed. Possui obra ativa, obra concluida e portal habilitado.',
        'portalAccessStatus': 'active',
        'portal_access_status': 'active',
        'portalAuthUserId': _clientUser,
        'portal_auth_user_id': _clientUser,
        'portalInvitedAt': _daysAgo(now, 45),
        'portal_invited_at': _daysAgo(now, 45),
        'portalLastAccessAt': _daysAgo(now, 2),
        'portal_last_access_at': _daysAgo(now, 2),
        'created_at': _daysAgo(now, 120),
        'updated_at': now,
      },
      {
        'id': _clientVista,
        'name': 'Vista Saude Participacoes',
        'ownerEmail': 'renato.moura@vistasaude.com.br',
        'owner_email': 'renato.moura@vistasaude.com.br',
        'contactEmail': 'engenharia@vistasaude.com.br',
        'contact_email': 'engenharia@vistasaude.com.br',
        'contactPhone': '(21) 3555-0188',
        'contact_phone': '(21) 3555-0188',
        'status': 'ativo',
        'notes': 'Cliente hospitalar com reforma em ambiente critico.',
        'portalAccessStatus': 'invited',
        'portal_access_status': 'invited',
        'portalAuthUserId': null,
        'portal_auth_user_id': null,
        'portalInvitedAt': _daysAgo(now, 8),
        'portal_invited_at': _daysAgo(now, 8),
        'portalLastAccessAt': null,
        'portal_last_access_at': null,
        'created_at': _daysAgo(now, 80),
        'updated_at': now,
      },
      {
        'id': _clientLogprime,
        'name': 'LogPrime Armazens S.A.',
        'ownerEmail': 'contratos@logprime.com.br',
        'owner_email': 'contratos@logprime.com.br',
        'contactEmail': 'obras@logprime.com.br',
        'contact_email': 'obras@logprime.com.br',
        'contactPhone': '(41) 3300-9090',
        'contact_phone': '(41) 3300-9090',
        'status': 'ativo',
        'notes': 'Cliente de galpao logistico com contrato em fase inicial.',
        'portalAccessStatus': 'pending',
        'portal_access_status': 'pending',
        'portalAuthUserId': null,
        'portal_auth_user_id': null,
        'portalInvitedAt': null,
        'portal_invited_at': null,
        'portalLastAccessAt': null,
        'portal_last_access_at': null,
        'created_at': _daysAgo(now, 30),
        'updated_at': now,
      },
    ];
  }

  List<Map<String, dynamic>> _users(DateTime now) {
    return [
      {
        'id': _adminUser,
        'email': 'admin@granitherp.com.br',
        'displayName': 'Diretoria Granith',
        'display_name': 'Diretoria Granith',
        'photoUrl': '',
        'photo_url': '',
        'status': 'ativo',
        'permissions': ['admin', 'financeiro', 'obras', 'rh', 'suprimentos'],
        'role': 'admin',
        'clientAccountId': null,
        'client_account_id': null,
        'clientAccountName': null,
        'client_account_name': null,
        'lastLogin': _daysAgo(now, 1),
        'last_login': _daysAgo(now, 1),
        'created_at': _daysAgo(now, 200),
        'updated_at': now,
      },
      {
        'id': _engineerUser,
        'email': 'mariana.rocha@granitherp.com.br',
        'displayName': 'Mariana Rocha',
        'display_name': 'Mariana Rocha',
        'photoUrl': '',
        'photo_url': '',
        'status': 'ativo',
        'permissions': ['obras', 'diario', 'medicoes'],
        'role': 'employee',
        'clientAccountId': null,
        'client_account_id': null,
        'clientAccountName': null,
        'client_account_name': null,
        'lastLogin': _daysAgo(now, 1),
        'last_login': _daysAgo(now, 1),
        'created_at': _daysAgo(now, 180),
        'updated_at': now,
      },
      {
        'id': _financeUser,
        'email': 'camila.neves@granitherp.com.br',
        'displayName': 'Camila Neves',
        'display_name': 'Camila Neves',
        'photoUrl': '',
        'photo_url': '',
        'status': 'ativo',
        'permissions': ['financeiro', 'relatorios', 'medicoes'],
        'role': 'employee',
        'clientAccountId': null,
        'client_account_id': null,
        'clientAccountName': null,
        'client_account_name': null,
        'lastLogin': _daysAgo(now, 3),
        'last_login': _daysAgo(now, 3),
        'created_at': _daysAgo(now, 170),
        'updated_at': now,
      },
      {
        'id': _buyerUser,
        'email': 'ana.lima@granitherp.com.br',
        'displayName': 'Ana Lima',
        'display_name': 'Ana Lima',
        'photoUrl': '',
        'photo_url': '',
        'status': 'ativo',
        'permissions': ['suprimentos', 'estoque', 'compras'],
        'role': 'employee',
        'clientAccountId': null,
        'client_account_id': null,
        'clientAccountName': null,
        'client_account_name': null,
        'lastLogin': _daysAgo(now, 4),
        'last_login': _daysAgo(now, 4),
        'created_at': _daysAgo(now, 160),
        'updated_at': now,
      },
      {
        'id': _clientUser,
        'email': 'marina.ferraz@atlasresidencial.com.br',
        'displayName': 'Marina Ferraz',
        'display_name': 'Marina Ferraz',
        'photoUrl': '',
        'photo_url': '',
        'status': 'ativo',
        'permissions': ['portal_cliente'],
        'role': 'client',
        'clientAccountId': _clientAtlas,
        'client_account_id': _clientAtlas,
        'clientAccountName': 'Atlas Residencial SPE Ltda',
        'client_account_name': 'Atlas Residencial SPE Ltda',
        'lastLogin': _daysAgo(now, 2),
        'last_login': _daysAgo(now, 2),
        'created_at': _daysAgo(now, 45),
        'updated_at': now,
      },
    ];
  }

  List<Map<String, dynamic>> _budgetTypes(DateTime now) {
    return [
      _budgetType(
        id: 'seed-budget-type-labor',
        name: 'Mao de obra',
        description: 'Equipes proprias, empreiteiros e encargos.',
        category: 'Servico',
        iconName: 'engineering',
        color: '0xFFE53935',
        now: now,
      ),
      _budgetType(
        id: 'seed-budget-type-materials',
        name: 'Materiais basicos',
        description: 'Cimento, areia, brita, aco e blocos.',
        category: 'Material',
        iconName: 'foundation',
        color: '0xFF8D6E63',
        now: now,
      ),
      _budgetType(
        id: 'seed-budget-type-finishing',
        name: 'Acabamentos',
        description: 'Pisos, tintas, loucas, metais e revestimentos.',
        category: 'Material',
        iconName: 'format_paint',
        color: '0xFF1E88E5',
        now: now,
      ),
      _budgetType(
        id: 'seed-budget-type-installations',
        name: 'Instalacoes',
        description: 'Eletrica, hidraulica, dados e climatizacao.',
        category: 'Servico',
        iconName: 'electrical_services',
        color: '0xFFFDD835',
        now: now,
      ),
      _budgetType(
        id: 'seed-budget-type-equipment',
        name: 'Equipamentos',
        description: 'Locacao de maquinas, andaimes e ferramentas.',
        category: 'Equipamento',
        iconName: 'precision_manufacturing',
        color: '0xFF43A047',
        now: now,
      ),
      _budgetType(
        id: 'seed-budget-type-documents',
        name: 'Projetos e licencas',
        description: 'Projetos executivos, ART, alvaras e aprovacoes.',
        category: 'Administrativo',
        iconName: 'description',
        color: '0xFF7E57C2',
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _budgetType({
    required String id,
    required String name,
    required String description,
    required String category,
    required String iconName,
    required String color,
    required DateTime now,
  }) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'isActive': true,
      'createdAt': _daysAgo(now, 120),
      'updatedAt': now,
      'iconName': iconName,
      'color': color,
    };
  }

  List<Map<String, dynamic>> _jobRoles(DateTime now) {
    return [
      _jobRole(
        id: 'seed-role-engineer',
        title: 'Engenheiro Civil',
        sector: 'Tecnico',
        description: 'Responsavel tecnico, planejamento e medicoes.',
        hourlyRate: 92,
        requirements: ['CREA ativo', 'Experiencia em obras verticais'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-master-builder',
        title: 'Mestre de Obras',
        sector: 'Operacional',
        description: 'Coordenacao diaria do canteiro.',
        hourlyRate: 48,
        requirements: ['Experiencia minima de 5 anos'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-bricklayer',
        title: 'Pedreiro',
        sector: 'Operacional',
        description: 'Execucao de alvenaria, reboco e concretagem.',
        hourlyRate: 31,
        requirements: ['Leitura basica de projeto'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-helper',
        title: 'Servente',
        sector: 'Operacional',
        description: 'Apoio geral de obra, limpeza e transporte interno.',
        hourlyRate: 20,
        requirements: ['Disponibilidade para campo'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-electrician',
        title: 'Eletricista',
        sector: 'Instalacoes',
        description: 'Infraestrutura eletrica e quadros.',
        hourlyRate: 42,
        requirements: ['NR-10', 'Experiencia com baixa tensao'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-plumber',
        title: 'Encanador',
        sector: 'Instalacoes',
        description: 'Redes hidraulicas, esgoto e testes de estanqueidade.',
        hourlyRate: 39,
        requirements: ['Experiencia em PVC/PPR'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-buyer',
        title: 'Comprador',
        sector: 'Suprimentos',
        description: 'Cotacoes, pedidos e follow-up de fornecedores.',
        hourlyRate: 36,
        requirements: ['Negociacao', 'Controle de estoque'],
        now: now,
      ),
      _jobRole(
        id: 'seed-role-financial',
        title: 'Analista Financeiro',
        sector: 'Financeiro',
        description: 'Contas a pagar/receber e conciliacao gerencial.',
        hourlyRate: 44,
        requirements: ['Excel avancado', 'Fluxo de caixa'],
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _jobRole({
    required String id,
    required String title,
    required String sector,
    required String description,
    required double hourlyRate,
    required List<String> requirements,
    required DateTime now,
  }) {
    return {
      'id': id,
      'title': title,
      'sector': sector,
      'description': description,
      'hourlyRate': hourlyRate,
      'requirements': requirements,
      'isActive': true,
      'createdAt': _daysAgo(now, 180),
    };
  }

  List<Map<String, dynamic>> _items(DateTime now) {
    return [
      _item(
        'seed-item-cement',
        'Cimento CP-II 50kg',
        'Saco 50kg',
        'sac',
        50,
        null,
        null,
        null,
        now,
      ),
      _item(
        'seed-item-sand',
        'Areia media lavada',
        'Metro cubico',
        'm3',
        1500,
        null,
        null,
        null,
        now,
      ),
      _item(
        'seed-item-gravel',
        'Brita 1',
        'Metro cubico',
        'm3',
        1450,
        null,
        null,
        null,
        now,
      ),
      _item(
        'seed-item-block',
        'Bloco de concreto 14x19x39',
        'Bloco estrutural',
        'un',
        12,
        14,
        19,
        39,
        now,
      ),
      _item(
        'seed-item-rebar',
        'Vergalhao CA-50 3/8',
        'Barra 12m',
        'br',
        8,
        null,
        null,
        1200,
        now,
      ),
      _item(
        'seed-item-paint',
        'Tinta acrilica premium 18L',
        'Lata 18L',
        'lat',
        18,
        null,
        null,
        null,
        now,
      ),
      _item(
        'seed-item-wire',
        'Cabo flexivel 2.5mm',
        'Rolo 100m',
        'rl',
        6,
        null,
        null,
        10000,
        now,
      ),
      _item(
        'seed-item-pipe',
        'Tubo PVC esgoto 100mm',
        'Barra 6m',
        'br',
        4.8,
        null,
        null,
        600,
        now,
      ),
      _item(
        'seed-item-porcelain',
        'Porcelanato cimento 90x90',
        'Caixa 2,43m2',
        'cx',
        44,
        90,
        1,
        90,
        now,
      ),
      _item(
        'seed-item-drywall',
        'Chapa drywall RU 12,5mm',
        'Chapa resistente a umidade',
        'un',
        26,
        120,
        1.25,
        180,
        now,
      ),
    ];
  }

  Map<String, dynamic> _item(
    String id,
    String name,
    String description,
    String unit,
    double weight,
    double? width,
    double? height,
    double? length,
    DateTime now,
  ) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit': unit,
      'weight': weight,
      'width': width,
      'height': height,
      'length': length,
      'createdAt': _daysAgo(now, 90),
      'updatedAt': now,
    };
  }

  List<Map<String, dynamic>> _suppliers(DateTime now) {
    return [
      _supplier(
        'seed-supplier-construmax',
        'Construmax Materiais Ltda',
        '11222333000181',
        now,
      ),
      _supplier(
        'seed-supplier-aco-forte',
        'Aco Forte Distribuidora',
        '22333444000172',
        now,
      ),
      _supplier(
        'seed-supplier-eletrica-luz',
        'Eletrica Luz & Energia',
        '33444555000163',
        now,
      ),
      _supplier(
        'seed-supplier-hidrasul',
        'HidraSul Tubos e Conexoes',
        '44555666000154',
        now,
      ),
      _supplier(
        'seed-supplier-locamaq',
        'Locamaq Equipamentos',
        '55666777000145',
        now,
      ),
      _supplier(
        'seed-supplier-prime-acabamentos',
        'Prime Acabamentos',
        '66777888000136',
        now,
      ),
    ];
  }

  Map<String, dynamic> _supplier(
    String id,
    String name,
    String cnpj,
    DateTime now,
  ) {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'isActive': true,
      'createdAt': _daysAgo(now, 160),
      'updatedAt': now,
    };
  }

  List<Map<String, dynamic>> _employees(DateTime now) {
    return [
      _employee(
        id: 'seed-employee-mariana',
        name: 'Mariana Rocha',
        email: 'mariana.rocha@granitherp.com.br',
        phone: '(11) 99111-0101',
        jobTitle: 'Engenheiro Civil',
        jobRoleId: 'seed-role-engineer',
        sector: 'Tecnico',
        role: 'coordenador',
        admissionDaysAgo: 420,
        cpf: '28495163040',
        ctps: '1020304-001',
        baseSalary: 11800,
        educationLevel: 'Superior completo',
        courses: 'Gestao de obras; Lean Construction; BIM 4D',
        now: now,
      ),
      _employee(
        id: 'seed-employee-carlos',
        name: 'Carlos Nascimento',
        email: 'carlos.nascimento@granitherp.com.br',
        phone: '(11) 99222-0202',
        jobTitle: 'Mestre de Obras',
        jobRoleId: 'seed-role-master-builder',
        sector: 'Operacional',
        role: 'supervisor',
        admissionDaysAgo: 620,
        cpf: '37841295003',
        ctps: '2040608-002',
        baseSalary: 7200,
        educationLevel: 'Ensino medio',
        courses: 'NR-18; Lideranca de equipes',
        now: now,
      ),
      _employee(
        id: 'seed-employee-joao',
        name: 'Joao Almeida',
        email: 'joao.almeida@granitherp.com.br',
        phone: '(11) 99333-0303',
        jobTitle: 'Pedreiro',
        jobRoleId: 'seed-role-bricklayer',
        sector: 'Operacional',
        role: 'funcionario',
        admissionDaysAgo: 250,
        cpf: '52901738012',
        ctps: '3090807-003',
        baseSalary: 3900,
        educationLevel: 'Ensino fundamental',
        courses: 'Alvenaria estrutural',
        now: now,
      ),
      _employee(
        id: 'seed-employee-paulo',
        name: 'Paulo Silva',
        email: 'paulo.silva@granitherp.com.br',
        phone: '(11) 99444-0404',
        jobTitle: 'Servente',
        jobRoleId: 'seed-role-helper',
        sector: 'Operacional',
        role: 'funcionario',
        admissionDaysAgo: 180,
        cpf: '16098724018',
        ctps: '4060801-004',
        baseSalary: 2450,
        educationLevel: 'Ensino fundamental',
        courses: 'Seguranca em canteiro',
        now: now,
      ),
      _employee(
        id: 'seed-employee-ricardo',
        name: 'Ricardo Mendes',
        email: 'ricardo.mendes@granitherp.com.br',
        phone: '(11) 99555-0505',
        jobTitle: 'Eletricista',
        jobRoleId: 'seed-role-electrician',
        sector: 'Instalacoes',
        role: 'funcionario',
        admissionDaysAgo: 310,
        cpf: '73054198025',
        ctps: '5010203-005',
        baseSalary: 5200,
        educationLevel: 'Tecnico',
        courses: 'NR-10; Comandos eletricos',
        now: now,
      ),
      _employee(
        id: 'seed-employee-lucas',
        name: 'Lucas Prado',
        email: 'lucas.prado@granitherp.com.br',
        phone: '(11) 99666-0606',
        jobTitle: 'Encanador',
        jobRoleId: 'seed-role-plumber',
        sector: 'Instalacoes',
        role: 'funcionario',
        admissionDaysAgo: 140,
        cpf: '95160427079',
        ctps: '6020405-006',
        baseSalary: 4900,
        educationLevel: 'Tecnico',
        courses: 'Instalacoes hidrossanitarias',
        now: now,
      ),
      _employee(
        id: 'seed-employee-camila',
        name: 'Camila Neves',
        email: 'camila.neves@granitherp.com.br',
        phone: '(11) 99777-0707',
        jobTitle: 'Analista Financeiro',
        jobRoleId: 'seed-role-financial',
        sector: 'Financeiro',
        role: 'funcionario',
        admissionDaysAgo: 500,
        cpf: '64230981052',
        ctps: '7080901-007',
        baseSalary: 6400,
        educationLevel: 'Superior completo',
        courses: 'Controladoria; Fluxo de caixa',
        now: now,
      ),
      _employee(
        id: 'seed-employee-ana',
        name: 'Ana Lima',
        email: 'ana.lima@granitherp.com.br',
        phone: '(11) 99888-0808',
        jobTitle: 'Comprador',
        jobRoleId: 'seed-role-buyer',
        sector: 'Suprimentos',
        role: 'funcionario',
        admissionDaysAgo: 360,
        cpf: '40718592066',
        ctps: '8090102-008',
        baseSalary: 5900,
        educationLevel: 'Superior completo',
        courses: 'Negociacao estrategica; Estoque',
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _employee({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String jobTitle,
    required String jobRoleId,
    required String sector,
    required String role,
    required int admissionDaysAgo,
    required String cpf,
    required String ctps,
    required double baseSalary,
    required String educationLevel,
    required String courses,
    required DateTime now,
  }) {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': '',
      'jobTitle': jobTitle,
      'jobRoleId': jobRoleId,
      'sector': sector,
      'role': role,
      'status': 'ativo',
      'admissionDate': _daysAgo(now, admissionDaysAgo),
      'dismissalDate': null,
      'cpf': cpf,
      'ctps': ctps,
      'baseSalary': baseSalary,
      'educationLevel': educationLevel,
      'courses': courses,
      'createdAt': _daysAgo(now, admissionDaysAgo),
      'updatedAt': now,
    };
  }

  List<Map<String, dynamic>> _projects(DateTime now) {
    return [
      _project(
        id: _projectAtlas,
        name: 'Torre B - Residencial Atlas',
        client: 'Atlas Residencial SPE Ltda',
        description:
            'Execucao da torre B com 18 pavimentos, areas comuns e urbanizacao.',
        status: 'inProgress',
        startDate: _daysAgo(now, 112),
        endDate: _daysFromNow(now, 210),
        budget: 1850000,
        currentCost: 846000,
        location: 'Sao Paulo - SP',
        tags: ['Residencial', 'Obra ativa', 'Portal cliente'],
        teamSize: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1503387762-592deb58ef4e?q=80&w=1600&auto=format&fit=crop',
        clientAccountId: _clientAtlas,
        clientAccountName: 'Atlas Residencial SPE Ltda',
        estimatedProgress: 46.486,
        measuredAmount: 860000,
        measurementCount: 3,
        lastMeasurementAt: _daysAgo(now, 5),
        createdBy: _engineerUser,
        now: now,
      ),
      _project(
        id: _projectVista,
        name: 'Reforma Centro Cirurgico Vista',
        client: 'Vista Saude Participacoes',
        description:
            'Reforma hospitalar em area critica com fases noturnas e controle de poeira.',
        status: 'inProgress',
        startDate: _daysAgo(now, 70),
        endDate: _daysFromNow(now, 95),
        budget: 920000,
        currentCost: 282500,
        location: 'Rio de Janeiro - RJ',
        tags: ['Hospitalar', 'Reforma', 'Prazo critico'],
        teamSize: 11,
        imageUrl:
            'https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=1600&auto=format&fit=crop',
        clientAccountId: _clientVista,
        clientAccountName: 'Vista Saude Participacoes',
        estimatedProgress: 20.109,
        measuredAmount: 185000,
        measurementCount: 1,
        lastMeasurementAt: _daysAgo(now, 12),
        createdBy: _engineerUser,
        now: now,
      ),
      _project(
        id: _projectLogprime,
        name: 'Galpao Logistico LogPrime',
        client: 'LogPrime Armazens S.A.',
        description:
            'Galpao de armazenagem com piso industrial, docas e area administrativa.',
        status: 'planning',
        startDate: _daysAgo(now, 18),
        endDate: _daysFromNow(now, 300),
        budget: 2480000,
        currentCost: 192000,
        location: 'Curitiba - PR',
        tags: ['Logistica', 'Contrato novo', 'Planejamento'],
        teamSize: 8,
        imageUrl:
            'https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=1600&auto=format&fit=crop',
        clientAccountId: _clientLogprime,
        clientAccountName: 'LogPrime Armazens S.A.',
        estimatedProgress: 5.04,
        measuredAmount: 125000,
        measurementCount: 1,
        lastMeasurementAt: _daysAgo(now, 3),
        createdBy: _engineerUser,
        now: now,
      ),
      _project(
        id: _projectCasaModelo,
        name: 'Casa Modelo Atlas',
        client: 'Atlas Residencial SPE Ltda',
        description:
            'Unidade modelo concluida para vendas e validacao de acabamentos.',
        status: 'completed',
        startDate: _daysAgo(now, 260),
        endDate: _daysAgo(now, 25),
        budget: 420000,
        currentCost: 398500,
        location: 'Sao Paulo - SP',
        tags: ['Residencial', 'Concluido', 'Acabamento'],
        teamSize: 7,
        imageUrl:
            'https://images.unsplash.com/photo-1535732759880-bbd5c7265e3f?q=80&w=1600&auto=format&fit=crop',
        clientAccountId: _clientAtlas,
        clientAccountName: 'Atlas Residencial SPE Ltda',
        estimatedProgress: 100,
        measuredAmount: 420000,
        measurementCount: 2,
        lastMeasurementAt: _daysAgo(now, 30),
        createdBy: _engineerUser,
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _project({
    required String id,
    required String name,
    required String client,
    required String description,
    required String status,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    required double currentCost,
    required String location,
    required List<String> tags,
    required int teamSize,
    required String imageUrl,
    required String clientAccountId,
    required String clientAccountName,
    required double estimatedProgress,
    required double measuredAmount,
    required int measurementCount,
    required DateTime lastMeasurementAt,
    required String createdBy,
    required DateTime now,
  }) {
    final projectKey =
        '${name.trim().toLowerCase()}_${client.trim().toLowerCase()}';

    return {
      'id': id,
      'name': name,
      'client': client,
      'description': description,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'currentCost': currentCost,
      'location': location,
      'tags': tags,
      'teamSize': teamSize,
      'imageUrl': imageUrl,
      'projectKey': projectKey,
      'contentHash': '$projectKey-$budget-$currentCost'.hashCode.toString(),
      'sourceBudgetId': null,
      'creationTimestamp': startDate,
      'createdAt': startDate,
      'created_at': startDate,
      'createdBy': createdBy,
      'created_by': createdBy,
      'updatedAt': now,
      'updated_at': now,
      'updatedBy': _adminUser,
      'updated_by': _adminUser,
      'clientAccountId': clientAccountId,
      'client_account_id': clientAccountId,
      'clientAccountName': clientAccountName,
      'client_account_name': clientAccountName,
      'estimatedProgress': estimatedProgress,
      'estimated_progress': estimatedProgress,
      'measuredAmount': measuredAmount,
      'measured_amount': measuredAmount,
      'measurementCount': measurementCount,
      'measurement_count': measurementCount,
      'lastMeasurementAt': lastMeasurementAt,
      'last_measurement_at': lastMeasurementAt,
    };
  }

  List<Map<String, dynamic>> _projectMeasurements(DateTime now) {
    final rows = <Map<String, dynamic>>[];

    void addMeasurement({
      required String id,
      required String projectId,
      required String projectName,
      required String projectClient,
      required int sequence,
      required String title,
      required String status,
      required DateTime date,
      required double contractValue,
      required double grossAmount,
      required double discountAmount,
      required double previousAccumulated,
      required String notes,
    }) {
      final netAmount = grossAmount - discountAmount;
      final accumulatedGross = previousAccumulated + grossAmount;
      rows.add({
        'id': id,
        'projectId': projectId,
        'project_id': projectId,
        'projectName': projectName,
        'project_name': projectName,
        'projectClient': projectClient,
        'project_client': projectClient,
        'title': title,
        'sequence': sequence,
        'status': status,
        'measurementDate': date,
        'measurement_date': date,
        'grossAmount': grossAmount,
        'gross_amount': grossAmount,
        'discountAmount': discountAmount,
        'discount_amount': discountAmount,
        'netAmount': netAmount,
        'net_amount': netAmount,
        'accumulatedGrossAmount': accumulatedGross,
        'accumulated_gross_amount': accumulatedGross,
        'measurementPercentage': grossAmount / contractValue * 100,
        'measurement_percentage': grossAmount / contractValue * 100,
        'accumulatedPercentage': accumulatedGross / contractValue * 100,
        'accumulated_percentage': accumulatedGross / contractValue * 100,
        'contractBalance': contractValue - accumulatedGross,
        'contract_balance': contractValue - accumulatedGross,
        'notes': notes,
        'createdBy': _engineerUser,
        'created_by': _engineerUser,
        'createdAt': date,
        'created_at': date,
        'updatedAt': now,
        'updated_at': now,
      });
    }

    addMeasurement(
      id: 'seed-measurement-atlas-01',
      projectId: _projectAtlas,
      projectName: 'Torre B - Residencial Atlas',
      projectClient: 'Atlas Residencial SPE Ltda',
      sequence: 1,
      title: 'Medicao 01 - fundacao e canteiro',
      status: 'paid',
      date: _daysAgo(now, 72),
      contractValue: 1850000,
      grossAmount: 320000,
      discountAmount: 0,
      previousAccumulated: 0,
      notes: 'Liberada apos validacao de fundacoes e mobilizacao.',
    );
    addMeasurement(
      id: 'seed-measurement-atlas-02',
      projectId: _projectAtlas,
      projectName: 'Torre B - Residencial Atlas',
      projectClient: 'Atlas Residencial SPE Ltda',
      sequence: 2,
      title: 'Medicao 02 - estrutura ate 6o pavimento',
      status: 'paid',
      date: _daysAgo(now, 35),
      contractValue: 1850000,
      grossAmount: 280000,
      discountAmount: 0,
      previousAccumulated: 320000,
      notes: 'Estrutura conferida e medicao paga no prazo contratual.',
    );
    addMeasurement(
      id: 'seed-measurement-atlas-03',
      projectId: _projectAtlas,
      projectName: 'Torre B - Residencial Atlas',
      projectClient: 'Atlas Residencial SPE Ltda',
      sequence: 3,
      title: 'Medicao 03 - alvenaria e shafts',
      status: 'approved',
      date: _daysAgo(now, 5),
      contractValue: 1850000,
      grossAmount: 260000,
      discountAmount: 0,
      previousAccumulated: 600000,
      notes: 'Aprovada pelo cliente, aguardando pagamento.',
    );
    addMeasurement(
      id: 'seed-measurement-vista-01',
      projectId: _projectVista,
      projectName: 'Reforma Centro Cirurgico Vista',
      projectClient: 'Vista Saude Participacoes',
      sequence: 1,
      title: 'Medicao 01 - demoliccoes e infraestrutura',
      status: 'paid',
      date: _daysAgo(now, 12),
      contractValue: 920000,
      grossAmount: 185000,
      discountAmount: 0,
      previousAccumulated: 0,
      notes: 'Fase noturna concluida sem impacto assistencial.',
    );
    addMeasurement(
      id: 'seed-measurement-logprime-01',
      projectId: _projectLogprime,
      projectName: 'Galpao Logistico LogPrime',
      projectClient: 'LogPrime Armazens S.A.',
      sequence: 1,
      title: 'Medicao 01 - projetos executivos e mobilizacao',
      status: 'pending',
      date: _daysAgo(now, 3),
      contractValue: 2480000,
      grossAmount: 125000,
      discountAmount: 0,
      previousAccumulated: 0,
      notes: 'Documentacao enviada para validacao inicial do cliente.',
    );
    addMeasurement(
      id: 'seed-measurement-casa-01',
      projectId: _projectCasaModelo,
      projectName: 'Casa Modelo Atlas',
      projectClient: 'Atlas Residencial SPE Ltda',
      sequence: 1,
      title: 'Medicao 01 - obra civil',
      status: 'paid',
      date: _daysAgo(now, 110),
      contractValue: 420000,
      grossAmount: 260000,
      discountAmount: 0,
      previousAccumulated: 0,
      notes: 'Obra civil finalizada.',
    );
    addMeasurement(
      id: 'seed-measurement-casa-02',
      projectId: _projectCasaModelo,
      projectName: 'Casa Modelo Atlas',
      projectClient: 'Atlas Residencial SPE Ltda',
      sequence: 2,
      title: 'Medicao 02 - acabamentos finais',
      status: 'paid',
      date: _daysAgo(now, 30),
      contractValue: 420000,
      grossAmount: 160000,
      discountAmount: 0,
      previousAccumulated: 260000,
      notes: 'Termo de entrega emitido.',
    );

    return rows;
  }

  List<Map<String, dynamic>> _budgets(DateTime now) {
    return [
      _budget(
        id: 'seed-budget-atlas-main',
        clientName: 'Atlas Residencial SPE Ltda',
        projectName: 'Torre B - Residencial Atlas',
        totalValue: 1850000,
        creationDate: _daysAgo(now, 125),
        expirationDate: _daysAgo(now, 95),
        status: 1,
        description: 'Contrato aprovado para execucao da torre B.',
        items: [
          _budgetItem('Fundacoes e estrutura', 1, 720000),
          _budgetItem('Alvenaria e vedacoes', 1, 360000),
          _budgetItem('Instalacoes', 1, 310000),
          _budgetItem('Acabamentos e areas comuns', 1, 460000),
        ],
        projectId: _projectAtlas,
        budgetTypeId: 'seed-budget-type-materials',
        clientAccountId: _clientAtlas,
        clientAccountName: 'Atlas Residencial SPE Ltda',
        now: now,
      ),
      _budget(
        id: 'seed-budget-vista-main',
        clientName: 'Vista Saude Participacoes',
        projectName: 'Reforma Centro Cirurgico Vista',
        totalValue: 920000,
        creationDate: _daysAgo(now, 82),
        expirationDate: _daysAgo(now, 54),
        status: 1,
        description: 'Reforma hospitalar faseada com operacao assistida.',
        items: [
          _budgetItem('Demolicoes controladas', 1, 110000),
          _budgetItem('Instalacoes hospitalares', 1, 450000),
          _budgetItem('Acabamento tecnico', 1, 280000),
          _budgetItem('Comissionamento', 1, 80000),
        ],
        projectId: _projectVista,
        budgetTypeId: 'seed-budget-type-installations',
        clientAccountId: _clientVista,
        clientAccountName: 'Vista Saude Participacoes',
        now: now,
      ),
      _budget(
        id: 'seed-budget-logprime-main',
        clientName: 'LogPrime Armazens S.A.',
        projectName: 'Galpao Logistico LogPrime',
        totalValue: 2480000,
        creationDate: _daysAgo(now, 35),
        expirationDate: _daysFromNow(now, 25),
        status: 1,
        description: 'Contrato aprovado para mobilizacao e projetos.',
        items: [
          _budgetItem('Terraplenagem e piso industrial', 1, 920000),
          _budgetItem('Estrutura metalica e cobertura', 1, 980000),
          _budgetItem('Docas e administracao', 1, 420000),
          _budgetItem('Sistemas preventivos', 1, 160000),
        ],
        projectId: _projectLogprime,
        budgetTypeId: 'seed-budget-type-equipment',
        clientAccountId: _clientLogprime,
        clientAccountName: 'LogPrime Armazens S.A.',
        now: now,
      ),
      _budget(
        id: 'seed-budget-atlas-addendum',
        clientName: 'Atlas Residencial SPE Ltda',
        projectName: 'Torre B - Residencial Atlas - Area gourmet',
        totalValue: 185000,
        creationDate: _daysAgo(now, 6),
        expirationDate: _daysFromNow(now, 12),
        status: 0,
        description: 'Aditivo em avaliacao para area gourmet e pergolado.',
        items: [
          _budgetItem('Pergolado metalico', 1, 76000),
          _budgetItem('Bancadas e revestimentos', 1, 69000),
          _budgetItem('Iluminacao decorativa', 1, 40000),
        ],
        projectId: _projectAtlas,
        budgetTypeId: 'seed-budget-type-finishing',
        clientAccountId: _clientAtlas,
        clientAccountName: 'Atlas Residencial SPE Ltda',
        now: now,
      ),
      _budget(
        id: 'seed-budget-casa-modelo',
        clientName: 'Atlas Residencial SPE Ltda',
        projectName: 'Casa Modelo Atlas',
        totalValue: 420000,
        creationDate: _daysAgo(now, 270),
        expirationDate: _daysAgo(now, 240),
        status: 1,
        description: 'Unidade modelo concluida.',
        items: [
          _budgetItem('Obra civil', 1, 260000),
          _budgetItem('Acabamentos', 1, 160000),
        ],
        projectId: _projectCasaModelo,
        budgetTypeId: 'seed-budget-type-finishing',
        clientAccountId: _clientAtlas,
        clientAccountName: 'Atlas Residencial SPE Ltda',
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _budget({
    required String id,
    required String clientName,
    required String projectName,
    required double totalValue,
    required DateTime creationDate,
    required DateTime expirationDate,
    required int status,
    required String description,
    required List<Map<String, dynamic>> items,
    required String projectId,
    required String budgetTypeId,
    required String clientAccountId,
    required String clientAccountName,
    required DateTime now,
  }) {
    return {
      'id': id,
      'clientName': clientName,
      'projectName': projectName,
      'totalValue': totalValue,
      'creationDate': _ms(creationDate),
      'expirationDate': _ms(expirationDate),
      'status': status,
      'description': description,
      'items': items,
      'projectId': projectId,
      'budgetTypeId': budgetTypeId,
      'clientAccountId': clientAccountId,
      'client_account_id': clientAccountId,
      'clientAccountName': clientAccountName,
      'client_account_name': clientAccountName,
      'created_at': creationDate,
    };
  }

  Map<String, dynamic> _budgetItem(
    String description,
    int quantity,
    double unitPrice,
  ) {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': quantity * unitPrice,
    };
  }

  List<Map<String, dynamic>> _teams(DateTime now) {
    return [
      {
        'id': 'seed-team-atlas-estrutura',
        'name': 'Equipe Atlas - Estrutura',
        'description': 'Nucleo de estrutura e alvenaria da Torre B.',
        'memberIds': [
          'seed-employee-mariana',
          'seed-employee-carlos',
          'seed-employee-joao',
          'seed-employee-paulo',
        ],
        'leaderId': 'seed-employee-carlos',
        'projectId': _projectAtlas,
        'isActive': true,
        'createdAt': _daysAgo(now, 100),
        'updatedAt': now,
      },
      {
        'id': 'seed-team-vista-instalacoes',
        'name': 'Equipe Vista - Instalacoes',
        'description': 'Equipe de eletrica, hidraulica e acabamento tecnico.',
        'memberIds': [
          'seed-employee-mariana',
          'seed-employee-ricardo',
          'seed-employee-lucas',
        ],
        'leaderId': 'seed-employee-mariana',
        'projectId': _projectVista,
        'isActive': true,
        'createdAt': _daysAgo(now, 70),
        'updatedAt': now,
      },
      {
        'id': 'seed-team-suprimentos',
        'name': 'Suprimentos e Almoxarifado',
        'description': 'Compras, recebimento e controle de estoque.',
        'memberIds': ['seed-employee-ana', 'seed-employee-camila'],
        'leaderId': 'seed-employee-ana',
        'projectId': null,
        'isActive': true,
        'createdAt': _daysAgo(now, 160),
        'updatedAt': now,
      },
    ];
  }

  List<Map<String, dynamic>> _benefits(DateTime now) {
    return [
      _benefit(
        'seed-benefit-vt',
        'Vale Transporte',
        'vt',
        'Credito mensal para deslocamento.',
        now,
      ),
      _benefit(
        'seed-benefit-vr',
        'Vale Refeicao',
        'vr',
        'Beneficio diario para refeicao em campo.',
        now,
      ),
      _benefit(
        'seed-benefit-health',
        'Plano de Saude',
        'health',
        'Plano empresarial com coparticipacao.',
        now,
      ),
      _benefit(
        'seed-benefit-dental',
        'Plano Odontologico',
        'dental',
        'Cobertura odontologica basica.',
        now,
      ),
      _benefit(
        'seed-benefit-life',
        'Seguro de Vida',
        'lifeInsurance',
        'Seguro obrigatorio para equipes de campo.',
        now,
      ),
    ];
  }

  Map<String, dynamic> _benefit(
    String id,
    String name,
    String type,
    String description,
    DateTime now,
  ) {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'isActive': true,
      'createdAt': _daysAgo(now, 180),
    };
  }

  List<Map<String, dynamic>> _employeeBenefits(DateTime now) {
    final rows = <Map<String, dynamic>>[];
    for (final employeeId in [
      'seed-employee-mariana',
      'seed-employee-carlos',
      'seed-employee-joao',
      'seed-employee-paulo',
      'seed-employee-ricardo',
      'seed-employee-lucas',
      'seed-employee-camila',
      'seed-employee-ana',
    ]) {
      rows.addAll([
        _employeeBenefit(
          employeeId,
          'seed-benefit-vr',
          'Vale Refeicao',
          690,
          now,
        ),
        _employeeBenefit(
          employeeId,
          'seed-benefit-vt',
          'Vale Transporte',
          240,
          now,
        ),
        _employeeBenefit(
          employeeId,
          'seed-benefit-life',
          'Seguro de Vida',
          38,
          now,
        ),
      ]);
    }
    rows.addAll([
      _employeeBenefit(
        'seed-employee-mariana',
        'seed-benefit-health',
        'Plano de Saude',
        510,
        now,
      ),
      _employeeBenefit(
        'seed-employee-carlos',
        'seed-benefit-health',
        'Plano de Saude',
        430,
        now,
      ),
      _employeeBenefit(
        'seed-employee-camila',
        'seed-benefit-health',
        'Plano de Saude',
        430,
        now,
      ),
      _employeeBenefit(
        'seed-employee-ana',
        'seed-benefit-dental',
        'Plano Odontologico',
        55,
        now,
      ),
    ]);
    return rows;
  }

  Map<String, dynamic> _employeeBenefit(
    String employeeId,
    String benefitId,
    String benefitName,
    double monthlyValue,
    DateTime now,
  ) {
    return {
      'id': 'seed-emp-benefit-$employeeId-$benefitId',
      'employeeId': employeeId,
      'benefitId': benefitId,
      'benefitName': benefitName,
      'monthlyValue': monthlyValue,
      'startDate': _daysAgo(now, 150),
      'endDate': null,
      'isActive': true,
      'history': [
        {
          'previousValue': monthlyValue * 0.92,
          'newValue': monthlyValue,
          'changedAt': _daysAgo(now, 45),
          'changedBy': _adminUser,
          'reason': 'Reajuste anual de beneficios',
        },
      ],
    };
  }

  List<Map<String, dynamic>> _salaryHistory(DateTime now) {
    return [
      _salary(
        'seed-salary-mariana-2026',
        'seed-employee-mariana',
        10500,
        11800,
        'Promocao para coordenacao tecnica',
        now,
      ),
      _salary(
        'seed-salary-carlos-2026',
        'seed-employee-carlos',
        6600,
        7200,
        'Reajuste por desempenho em campo',
        now,
      ),
      _salary(
        'seed-salary-camila-2026',
        'seed-employee-camila',
        5900,
        6400,
        'Reajuste anual financeiro',
        now,
      ),
      _salary(
        'seed-salary-ana-2026',
        'seed-employee-ana',
        5400,
        5900,
        'Reajuste anual suprimentos',
        now,
      ),
    ];
  }

  Map<String, dynamic> _salary(
    String id,
    String employeeId,
    double previousSalary,
    double newSalary,
    String reason,
    DateTime now,
  ) {
    return {
      'id': id,
      'employeeId': employeeId,
      'previousSalary': previousSalary,
      'newSalary': newSalary,
      'effectiveDate': _daysAgo(now, 35),
      'reason': reason,
      'updatedBy': _adminUser,
      'createdAt': _daysAgo(now, 35),
    };
  }

  List<Map<String, dynamic>> _purchases(DateTime now) {
    return [
      _purchase(
        id: 'seed-purchase-atlas-cement',
        itemId: 'seed-item-cement',
        itemName: 'Cimento CP-II 50kg',
        supplierId: 'seed-supplier-construmax',
        supplierName: 'Construmax Materiais Ltda',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        requisitionId: 'seed-req-atlas-estrutura',
        financialTransactionId: 'seed-ft-atlas-cement',
        deliveryAddress: 'Rua das Acacias, 1800 - Sao Paulo - SP',
        quantity: 420,
        totalValue: 17640,
        status: 3,
        purchaseDate: _daysAgo(now, 28),
        deliveryDate: _daysAgo(now, 24),
        receivedBy: 'seed-employee-ana',
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 27),
      ),
      _purchase(
        id: 'seed-purchase-atlas-rebar',
        itemId: 'seed-item-rebar',
        itemName: 'Vergalhao CA-50 3/8',
        supplierId: 'seed-supplier-aco-forte',
        supplierName: 'Aco Forte Distribuidora',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        requisitionId: 'seed-req-atlas-estrutura',
        financialTransactionId: 'seed-ft-atlas-rebar',
        deliveryAddress: 'Rua das Acacias, 1800 - Sao Paulo - SP',
        quantity: 280,
        totalValue: 39200,
        status: 3,
        purchaseDate: _daysAgo(now, 22),
        deliveryDate: _daysAgo(now, 18),
        receivedBy: 'seed-employee-carlos',
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 21),
      ),
      _purchase(
        id: 'seed-purchase-vista-wire',
        itemId: 'seed-item-wire',
        itemName: 'Cabo flexivel 2.5mm',
        supplierId: 'seed-supplier-eletrica-luz',
        supplierName: 'Eletrica Luz & Energia',
        projectId: _projectVista,
        projectName: 'Reforma Centro Cirurgico Vista',
        requisitionId: 'seed-req-vista-eletrica',
        financialTransactionId: 'seed-ft-vista-wire',
        deliveryAddress: 'Av. Atlantica, 450 - Rio de Janeiro - RJ',
        quantity: 35,
        totalValue: 18550,
        status: 3,
        purchaseDate: _daysAgo(now, 16),
        deliveryDate: _daysAgo(now, 12),
        receivedBy: 'seed-employee-ricardo',
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 15),
      ),
      _purchase(
        id: 'seed-purchase-logprime-locamaq',
        itemId: 'seed-item-gravel',
        itemName: 'Brita 1',
        supplierId: 'seed-supplier-locamaq',
        supplierName: 'Locamaq Equipamentos',
        projectId: _projectLogprime,
        projectName: 'Galpao Logistico LogPrime',
        requisitionId: 'seed-req-logprime-mobilizacao',
        financialTransactionId: null,
        deliveryAddress: 'BR-376, km 122 - Curitiba - PR',
        quantity: 80,
        totalValue: 12400,
        status: 2,
        purchaseDate: _daysAgo(now, 4),
        deliveryDate: null,
        receivedBy: null,
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 4),
      ),
      _purchase(
        id: 'seed-purchase-atlas-porcelain',
        itemId: 'seed-item-porcelain',
        itemName: 'Porcelanato cimento 90x90',
        supplierId: 'seed-supplier-prime-acabamentos',
        supplierName: 'Prime Acabamentos',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        requisitionId: null,
        financialTransactionId: null,
        deliveryAddress: 'Rua das Acacias, 1800 - Sao Paulo - SP',
        quantity: 160,
        totalValue: 60800,
        status: 0,
        purchaseDate: _daysAgo(now, 2),
        deliveryDate: null,
        receivedBy: null,
        approvedBy: null,
        approvedByName: null,
        approvedAt: null,
      ),
    ];
  }

  Map<String, dynamic> _purchase({
    required String id,
    required String itemId,
    required String itemName,
    required String supplierId,
    required String supplierName,
    required String projectId,
    required String projectName,
    required String? requisitionId,
    required String? financialTransactionId,
    required String deliveryAddress,
    required double quantity,
    required double totalValue,
    required int status,
    required DateTime purchaseDate,
    required DateTime? deliveryDate,
    required String? receivedBy,
    required String? approvedBy,
    required String? approvedByName,
    required DateTime? approvedAt,
  }) {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'projectId': projectId,
      'projectName': projectName,
      'requisitionId': requisitionId,
      'financialTransactionId': financialTransactionId,
      'deliveryAddress': deliveryAddress,
      'quantity': quantity,
      'totalValue': totalValue,
      'status': status,
      'purchaseDate': purchaseDate,
      'deliveryDate': deliveryDate,
      'receivedBy': receivedBy,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt,
      'rejectionReason': null,
    };
  }

  List<Map<String, dynamic>> _inventory(DateTime now) {
    return [
      _inventoryItem(
        'seed-inv-cement',
        'Cimento CP-II 50kg',
        'sac',
        280,
        120,
        'seed-purchase-atlas-cement',
        now,
      ),
      _inventoryItem(
        'seed-inv-sand',
        'Areia media lavada',
        'm3',
        95,
        40,
        null,
        now,
      ),
      _inventoryItem('seed-inv-gravel', 'Brita 1', 'm3', 62, 35, null, now),
      _inventoryItem(
        'seed-inv-block',
        'Bloco de concreto 14x19x39',
        'un',
        5200,
        1800,
        null,
        now,
      ),
      _inventoryItem(
        'seed-inv-rebar',
        'Vergalhao CA-50 3/8',
        'br',
        190,
        90,
        'seed-purchase-atlas-rebar',
        now,
      ),
      _inventoryItem(
        'seed-inv-paint',
        'Tinta acrilica premium 18L',
        'lat',
        32,
        18,
        null,
        now,
      ),
      _inventoryItem(
        'seed-inv-wire',
        'Cabo flexivel 2.5mm',
        'rl',
        21,
        8,
        'seed-purchase-vista-wire',
        now,
      ),
      _inventoryItem(
        'seed-inv-pipe',
        'Tubo PVC esgoto 100mm',
        'br',
        74,
        25,
        null,
        now,
      ),
      _inventoryItem(
        'seed-inv-porcelain',
        'Porcelanato cimento 90x90',
        'cx',
        14,
        30,
        null,
        now,
      ),
      _inventoryItem(
        'seed-inv-drywall',
        'Chapa drywall RU 12,5mm',
        'un',
        80,
        35,
        null,
        now,
      ),
    ];
  }

  Map<String, dynamic> _inventoryItem(
    String id,
    String name,
    String unit,
    double quantity,
    double minQuantity,
    String? lastPurchaseId,
    DateTime now,
  ) {
    return {
      'id': id,
      'name': name,
      'name_normalized': name.trim().toLowerCase(),
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'updatedAt': now,
      'lastEntryDate': lastPurchaseId == null ? null : _daysAgo(now, 12),
      'lastPurchaseId': lastPurchaseId,
      'createdAt': _daysAgo(now, 90),
    };
  }

  List<Map<String, dynamic>> _inventoryMovements(DateTime now) {
    return [
      _movement(
        id: 'seed-mov-cement-in',
        itemId: 'seed-inv-cement',
        itemName: 'Cimento CP-II 50kg',
        quantity: 420,
        type: 'inbound',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        purchaseId: 'seed-purchase-atlas-cement',
        referenceId: 'seed-purchase-atlas-cement',
        date: _daysAgo(now, 24),
        notes: 'Entrada por compra entregue.',
        userId: 'seed-employee-ana',
      ),
      _movement(
        id: 'seed-mov-rebar-in',
        itemId: 'seed-inv-rebar',
        itemName: 'Vergalhao CA-50 3/8',
        quantity: 280,
        type: 'inbound',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        purchaseId: 'seed-purchase-atlas-rebar',
        referenceId: 'seed-purchase-atlas-rebar',
        date: _daysAgo(now, 18),
        notes: 'Entrada por compra entregue.',
        userId: 'seed-employee-carlos',
      ),
      _movement(
        id: 'seed-mov-wire-in',
        itemId: 'seed-inv-wire',
        itemName: 'Cabo flexivel 2.5mm',
        quantity: 35,
        type: 'inbound',
        projectId: _projectVista,
        projectName: 'Reforma Centro Cirurgico Vista',
        purchaseId: 'seed-purchase-vista-wire',
        referenceId: 'seed-purchase-vista-wire',
        date: _daysAgo(now, 12),
        notes: 'Entrada por compra entregue.',
        userId: 'seed-employee-ricardo',
      ),
      _movement(
        id: 'seed-mov-cement-out-atlas',
        itemId: 'seed-inv-cement',
        itemName: 'Cimento CP-II 50kg',
        quantity: 140,
        type: 'outbound',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        purchaseId: null,
        referenceId: 'seed-log-atlas-01',
        date: _daysAgo(now, 6),
        notes: 'Baixa para concretagem do 7o pavimento.',
        userId: 'seed-employee-carlos',
      ),
      _movement(
        id: 'seed-mov-porcelain-adjust',
        itemId: 'seed-inv-porcelain',
        itemName: 'Porcelanato cimento 90x90',
        quantity: 16,
        type: 'adjustment',
        projectId: null,
        projectName: null,
        purchaseId: null,
        referenceId: null,
        date: _daysAgo(now, 1),
        notes: 'Inventario apontou saldo abaixo do minimo.',
        userId: 'seed-employee-ana',
      ),
    ];
  }

  Map<String, dynamic> _movement({
    required String id,
    required String itemId,
    required String itemName,
    required double quantity,
    required String type,
    required String? projectId,
    required String? projectName,
    required String? purchaseId,
    required String? referenceId,
    required DateTime date,
    required String notes,
    required String userId,
  }) {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'type': type,
      'projectId': projectId,
      'projectName': projectName,
      'purchaseId': purchaseId,
      'referenceId': referenceId,
      'date': date,
      'notes': notes,
      'userId': userId,
    };
  }

  List<Map<String, dynamic>> _materialRequisitions(DateTime now) {
    return [
      _requisition(
        id: 'seed-req-atlas-estrutura',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        requesterName: 'Carlos Nascimento',
        requesterId: 'seed-employee-carlos',
        requestDate: _daysAgo(now, 30),
        status: 'delivered',
        priority: 'Alta',
        items: [
          _requisitionItem(
            'Cimento CP-II 50kg',
            420,
            'sac',
            'Concretagem e argamassa da estrutura.',
          ),
          _requisitionItem(
            'Vergalhao CA-50 3/8',
            280,
            'br',
            'Armadura dos pilares e vigas.',
          ),
        ],
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 29),
        rejectionReason: null,
        purchaseId: 'seed-purchase-atlas-cement',
        createdAt: _daysAgo(now, 30),
      ),
      _requisition(
        id: 'seed-req-vista-eletrica',
        projectId: _projectVista,
        projectName: 'Reforma Centro Cirurgico Vista',
        requesterName: 'Ricardo Mendes',
        requesterId: 'seed-employee-ricardo',
        requestDate: _daysAgo(now, 18),
        status: 'delivered',
        priority: 'Alta',
        items: [
          _requisitionItem(
            'Cabo flexivel 2.5mm',
            35,
            'rl',
            'Circuitos novos de iluminacao e tomadas.',
          ),
        ],
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 17),
        rejectionReason: null,
        purchaseId: 'seed-purchase-vista-wire',
        createdAt: _daysAgo(now, 18),
      ),
      _requisition(
        id: 'seed-req-logprime-mobilizacao',
        projectId: _projectLogprime,
        projectName: 'Galpao Logistico LogPrime',
        requesterName: 'Mariana Rocha',
        requesterId: 'seed-employee-mariana',
        requestDate: _daysAgo(now, 5),
        status: 'purchased',
        priority: 'Media',
        items: [
          _requisitionItem(
            'Brita 1',
            80,
            'm3',
            'Regularizacao inicial de acesso e canteiro.',
          ),
        ],
        approvedBy: _adminUser,
        approvedByName: 'Diretoria Granith',
        approvedAt: _daysAgo(now, 4),
        rejectionReason: null,
        purchaseId: 'seed-purchase-logprime-locamaq',
        createdAt: _daysAgo(now, 5),
      ),
      _requisition(
        id: 'seed-req-atlas-acabamento',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        requesterName: 'Mariana Rocha',
        requesterId: 'seed-employee-mariana',
        requestDate: _daysAgo(now, 2),
        status: 'pending',
        priority: 'Media',
        items: [
          _requisitionItem(
            'Porcelanato cimento 90x90',
            160,
            'cx',
            'Compra aguardando aprovacao CEO.',
          ),
        ],
        approvedBy: null,
        approvedByName: null,
        approvedAt: null,
        rejectionReason: null,
        purchaseId: null,
        createdAt: _daysAgo(now, 2),
      ),
    ];
  }

  Map<String, dynamic> _requisition({
    required String id,
    required String projectId,
    required String projectName,
    required String requesterName,
    required String requesterId,
    required DateTime requestDate,
    required String status,
    required String priority,
    required List<Map<String, dynamic>> items,
    required String? approvedBy,
    required String? approvedByName,
    required DateTime? approvedAt,
    required String? rejectionReason,
    required String? purchaseId,
    required DateTime createdAt,
  }) {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'requesterName': requesterName,
      'requesterId': requesterId,
      'requestDate': requestDate,
      'status': status,
      'items': items,
      'priority': priority,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
      'purchaseId': purchaseId,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> _requisitionItem(
    String itemName,
    double quantity,
    String unit,
    String observation,
  ) {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'observation': observation,
    };
  }

  List<Map<String, dynamic>> _dailyLogs(DateTime now) {
    return [
      _dailyLog(
        id: 'seed-log-atlas-01',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        date: _daysAgo(now, 6),
        weatherMorning: 'sol',
        weatherAfternoon: 'nublado',
        manpower: {
          'Mestre de Obras': 1,
          'Pedreiro': 6,
          'Servente': 5,
          'Eletricista': 1,
        },
        activitiesDescription:
            'Concretagem parcial do 7o pavimento, montagem de formas e conferencia de prumadas.',
        impediments: 'Aguardando liberacao de grua para turno da tarde.',
        status: 'finalized',
        createdByUserId: 'seed-employee-carlos',
        now: now,
      ),
      _dailyLog(
        id: 'seed-log-atlas-02',
        projectId: _projectAtlas,
        projectName: 'Torre B - Residencial Atlas',
        date: _daysAgo(now, 2),
        weatherMorning: 'nublado',
        weatherAfternoon: 'chuvoso',
        manpower: {
          'Mestre de Obras': 1,
          'Pedreiro': 5,
          'Servente': 4,
          'Eletricista': 2,
        },
        activitiesDescription:
            'Execucao de alvenaria do 5o pavimento e passagem de eletrodutos nos shafts.',
        impediments: 'Chuva reduziu produtividade externa no fim do dia.',
        status: 'draft',
        createdByUserId: 'seed-employee-mariana',
        now: now,
      ),
      _dailyLog(
        id: 'seed-log-vista-01',
        projectId: _projectVista,
        projectName: 'Reforma Centro Cirurgico Vista',
        date: _daysAgo(now, 4),
        weatherMorning: 'sol',
        weatherAfternoon: 'sol',
        manpower: {
          'Engenheiro Civil': 1,
          'Eletricista': 2,
          'Encanador': 2,
          'Servente': 3,
        },
        activitiesDescription:
            'Infraestrutura eletrica da sala 2, teste hidraulico e fechamento de shafts.',
        impediments: 'Janela de trabalho limitada pela operacao hospitalar.',
        status: 'finalized',
        createdByUserId: 'seed-employee-ricardo',
        now: now,
      ),
    ];
  }

  Map<String, dynamic> _dailyLog({
    required String id,
    required String projectId,
    required String projectName,
    required DateTime date,
    required String weatherMorning,
    required String weatherAfternoon,
    required Map<String, int> manpower,
    required String activitiesDescription,
    required String impediments,
    required String status,
    required String createdByUserId,
    required DateTime now,
  }) {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'date': date,
      'weatherMorning': weatherMorning,
      'weatherAfternoon': weatherAfternoon,
      'manpower': manpower,
      'activitiesDescription': activitiesDescription,
      'impediments': impediments,
      'photoUrls': <String>[],
      'createdByUserId': createdByUserId,
      'status': status,
      'createdAt': date,
      'updatedAt': now,
    };
  }

  List<Map<String, dynamic>> _financialTransactions(DateTime now) {
    return [
      _transaction(
        id: 'seed-ft-atlas-med-01',
        description: 'Recebimento medicao 01 - Torre B',
        amount: 320000,
        type: 'income',
        status: 'paid',
        origin: 'budget',
        category: 'measurement',
        dueDate: _daysAgo(now, 65),
        paymentDate: _daysAgo(now, 63),
        projectId: _projectAtlas,
        supplierId: null,
        referenceId: 'seed-measurement-atlas-01',
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 72),
        notes: 'Pagamento cliente Atlas referente a fundacao.',
      ),
      _transaction(
        id: 'seed-ft-atlas-med-02',
        description: 'Recebimento medicao 02 - Torre B',
        amount: 280000,
        type: 'income',
        status: 'paid',
        origin: 'budget',
        category: 'measurement',
        dueDate: _daysAgo(now, 30),
        paymentDate: _daysAgo(now, 29),
        projectId: _projectAtlas,
        supplierId: null,
        referenceId: 'seed-measurement-atlas-02',
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 35),
        notes: 'Medicao quitada sem glosa.',
      ),
      _transaction(
        id: 'seed-ft-atlas-med-03',
        description: 'Medicao 03 a receber - Torre B',
        amount: 260000,
        type: 'income',
        status: 'pending',
        origin: 'budget',
        category: 'measurement',
        dueDate: _daysFromNow(now, 10),
        paymentDate: null,
        projectId: _projectAtlas,
        supplierId: null,
        referenceId: 'seed-measurement-atlas-03',
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 5),
        notes: 'Aguardando ciclo de pagamento do cliente.',
      ),
      _transaction(
        id: 'seed-ft-vista-med-01',
        description: 'Recebimento medicao 01 - Vista',
        amount: 185000,
        type: 'income',
        status: 'paid',
        origin: 'budget',
        category: 'measurement',
        dueDate: _daysAgo(now, 8),
        paymentDate: _daysAgo(now, 7),
        projectId: _projectVista,
        supplierId: null,
        referenceId: 'seed-measurement-vista-01',
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 12),
        notes: 'Pagamento da primeira fase hospitalar.',
      ),
      _transaction(
        id: 'seed-ft-atlas-cement',
        description: 'Compra cimento - Torre B',
        amount: 17640,
        type: 'expense',
        status: 'paid',
        origin: 'purchase',
        category: 'material',
        dueDate: _daysAgo(now, 24),
        paymentDate: _daysAgo(now, 23),
        projectId: _projectAtlas,
        supplierId: 'seed-supplier-construmax',
        referenceId: 'seed-purchase-atlas-cement',
        createdBy: _buyerUser,
        createdAt: _daysAgo(now, 28),
        notes: 'NF 81233 recebida com a entrega.',
      ),
      _transaction(
        id: 'seed-ft-atlas-rebar',
        description: 'Compra vergalhao - Torre B',
        amount: 39200,
        type: 'expense',
        status: 'paid',
        origin: 'purchase',
        category: 'material',
        dueDate: _daysAgo(now, 18),
        paymentDate: _daysAgo(now, 16),
        projectId: _projectAtlas,
        supplierId: 'seed-supplier-aco-forte',
        referenceId: 'seed-purchase-atlas-rebar',
        createdBy: _buyerUser,
        createdAt: _daysAgo(now, 22),
        notes: 'Compra vinculada a requisicao estrutural.',
      ),
      _transaction(
        id: 'seed-ft-vista-wire',
        description: 'Cabos eletricos - Centro Cirurgico',
        amount: 18550,
        type: 'expense',
        status: 'paid',
        origin: 'purchase',
        category: 'material',
        dueDate: _daysAgo(now, 12),
        paymentDate: _daysAgo(now, 11),
        projectId: _projectVista,
        supplierId: 'seed-supplier-eletrica-luz',
        referenceId: 'seed-purchase-vista-wire',
        createdBy: _buyerUser,
        createdAt: _daysAgo(now, 16),
        notes: 'Material instalado em area critica.',
      ),
      _transaction(
        id: 'seed-ft-atlas-labor-april',
        description: 'Folha alocada abril - Torre B',
        amount: 126000,
        type: 'expense',
        status: 'paid',
        origin: 'laborCost',
        category: 'labor',
        dueDate: _daysAgo(now, 3),
        paymentDate: _daysAgo(now, 2),
        projectId: _projectAtlas,
        supplierId: null,
        referenceId: 'seed-log-atlas-02',
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 3),
        notes: 'Custo de mao de obra apropriado pelo diario.',
      ),
      _transaction(
        id: 'seed-ft-vista-equipment',
        description: 'Locacao exaustores e filtros HEPA',
        amount: 28400,
        type: 'expense',
        status: 'pending',
        origin: 'manual',
        category: 'equipment',
        dueDate: _daysFromNow(now, 6),
        paymentDate: null,
        projectId: _projectVista,
        supplierId: 'seed-supplier-locamaq',
        referenceId: null,
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 4),
        notes: 'Locacao necessaria para controle de particulas.',
      ),
      _transaction(
        id: 'seed-ft-office-tax',
        description: 'ISS retido sobre medicoes do mes',
        amount: 14800,
        type: 'expense',
        status: 'overdue',
        origin: 'manual',
        category: 'tax',
        dueDate: _daysAgo(now, 4),
        paymentDate: null,
        projectId: null,
        supplierId: null,
        referenceId: null,
        createdBy: _financeUser,
        createdAt: _daysAgo(now, 12),
        notes: 'Pendencia administrativa destacada no painel financeiro.',
      ),
    ];
  }

  Map<String, dynamic> _transaction({
    required String id,
    required String description,
    required double amount,
    required String type,
    required String status,
    required String origin,
    required String category,
    required DateTime dueDate,
    required DateTime? paymentDate,
    required String? projectId,
    required String? supplierId,
    required String? referenceId,
    required String createdBy,
    required DateTime createdAt,
    required String notes,
  }) {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'status': status,
      'origin': origin,
      'category': category,
      'dueDate': dueDate,
      'paymentDate': paymentDate,
      'projectId': projectId,
      'supplierId': supplierId,
      'referenceId': referenceId,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': null,
      'notes': notes,
    };
  }

  List<Map<String, dynamic>> _talentCandidates(DateTime now) {
    return [
      _candidate(
        'seed-candidate-fernanda',
        'Fernanda Costa',
        'fernanda.costa@email.com',
        '(11) 98111-4455',
        'reviewing',
        'seed-role-engineer',
        'Experiencia em planejamento de obras hospitalares. Curriculo aprovado para entrevista tecnica.',
        now,
      ),
      _candidate(
        'seed-candidate-roberto',
        'Roberto Lima',
        'roberto.lima@email.com',
        '(11) 98222-7766',
        'pending',
        'seed-role-master-builder',
        'Indicado por fornecedor. Aguardando triagem de campo.',
        now,
      ),
      _candidate(
        'seed-candidate-tatiane',
        'Tatiane Freitas',
        'tatiane.freitas@email.com',
        '(11) 98333-8899',
        'approved',
        'seed-role-buyer',
        'Perfil aderente para compras tecnicas e follow-up de entregas.',
        now,
      ),
    ];
  }

  Map<String, dynamic> _candidate(
    String id,
    String name,
    String email,
    String phone,
    String status,
    String jobRoleId,
    String notes,
    DateTime now,
  ) {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'jobRoleId': jobRoleId,
      'notes': notes,
      'createdAt': _daysAgo(now, 20),
      'updatedAt': now,
    };
  }

  List<Map<String, dynamic>> _usageStats(DateTime now) {
    final start = DateTime.utc(now.year, now.month, 1);
    final end = DateTime.utc(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));

    return [
      {
        'id': 'seed-usage-current-month',
        'tenantId': 'granith-demo',
        'totalReads': 18420,
        'totalWrites': 3420,
        'projectRef': 'granith-demo-supabase',
        'totalApiRequests': 29850,
        'totalRestRequests': 22110,
        'totalAuthRequests': 820,
        'totalStorageRequests': 360,
        'totalRealtimeRequests': 6560,
        'databaseUsedMB': 128.45,
        'storageUsedMB': 842.30,
        'aiRequests': 74,
        'periodStart': start,
        'periodEnd': end,
        'dailyOperations': {
          '2026-05-01': {'reads': 910, 'writes': 132},
          '2026-05-02': {'reads': 1040, 'writes': 176},
          '2026-05-03': {'reads': 870, 'writes': 118},
        },
        'peakDayOperations': 1216,
        'sourceLabel': 'Snapshot demonstrativo do ERP',
        'lastSyncedAt': now,
      },
    ];
  }
}
