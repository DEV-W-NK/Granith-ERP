import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/budget_type_service.dart';
import 'package:project_granith/services/service_orcamentos.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/services/job_role_service.dart';
import 'package:project_granith/services/item_service.dart';
import 'package:project_granith/services/material_requisition_service.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/team_model.dart';

class DatabaseSeeder {
  final ServiceProjetos _projectService = ServiceProjetos();
  final SupplierService _supplierService = SupplierService();
  final BudgetTypeService _budgetTypeService = BudgetTypeService();
  final ServiceOrcamentos _budgetService = ServiceOrcamentos();
  final ItemService _itemService = ItemService();
  final MaterialRequisitionService _requisitionService = MaterialRequisitionService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  final List<String> _projectImages = [
    'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?q=80&w=2031&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1590486803833-1c5dc8ddd4c8?q=80&w=1887&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1535732759880-bbd5c7265e3f?q=80&w=1964&auto=format&fit=crop',
  ];

  final List<String> _locations = [
    'São Paulo - SP', 'Rio de Janeiro - RJ', 'Curitiba - PR',
    'Belo Horizonte - MG', 'Campinas - SP',
  ];

  final List<String> _projectNames = [
    'Residencial Alphaville',
    'Reforma Loja Shopping',
    'Edifício Comercial Horizon',
    'Casa de Praia - Guarujá',
    'Centro Logístico Norte',
  ];

  Future<bool> seed() async {
    print('🌱 SEEDER: Iniciando população completa...');
    try {
      print('📦 SEEDER: Tipos de Orçamento...');
      final budgetTypeIds = await _seedBudgetTypes();

      print('🧰 SEEDER: Cargos...');
      final jobRoleIds = await _seedJobRoles();

      print('🧱 SEEDER: Itens/Materiais...');
      final itemIds = await _seedItems();

      print('🚚 SEEDER: Fornecedores...');
      final supplierIds = await _seedSuppliers();

      print('👷 SEEDER: Funcionários...');
      final employeeIds = await _seedEmployees(jobRoleIds);

      print('👥 SEEDER: Equipes...');
      await _seedTeams(employeeIds);

      print('🏗️ SEEDER: Projetos...');
      final projects = await _seedProjects();

      print('💰 SEEDER: Orçamentos...');
      await _seedBudgets(projects, budgetTypeIds);

      print('🛒 SEEDER: Compras...');
      await _seedPurchases(projects, supplierIds, itemIds);

      print('📦 SEEDER: Estoque...');
      await _seedInventory(projects, itemIds);

      print('📋 SEEDER: Requisições...');
      await _seedRequisitions(projects, itemIds);

      print('📝 SEEDER: Diários de Obra...');
      await _seedDailyLogs(projects, employeeIds);

      print('💵 SEEDER: Transações Financeiras...');
      await _seedFinancials(projects, budgetTypeIds);

      print('🎉 DATABASE POPULADO COM SUCESSO!');
      return true;
    } catch (e, stack) {
      print('❌ SEEDER: Erro crítico: $e');
      print(stack);
      return false;
    }
  }

  // ─── Budget Types ──────────────────────────────────────────────────────────

  Future<List<String>> _seedBudgetTypes() async {
    final now = DateTime.now();
    final types = [
      BudgetType(id: '', name: 'Mão de Obra',   description: 'Serviços gerais',      category: 'Serviço',  isActive: true, createdAt: now, updatedAt: now, iconName: 'engineering',        color: '0xFFF44336'),
      BudgetType(id: '', name: 'Material Básico',description: 'Cimento, areia',       category: 'Material', isActive: true, createdAt: now, updatedAt: now, iconName: 'foundation',           color: '0xFF795548'),
      BudgetType(id: '', name: 'Acabamento',     description: 'Pisos e tintas',       category: 'Material', isActive: true, createdAt: now, updatedAt: now, iconName: 'format_paint',         color: '0xFF2196F3'),
      BudgetType(id: '', name: 'Instalações',    description: 'Elétrica/Hidráulica',  category: 'Serviço',  isActive: true, createdAt: now, updatedAt: now, iconName: 'electrical_services',  color: '0xFFFFC107'),
    ];

    List<String> ids = [];
    for (var type in types) {
      try {
        final exists = await _budgetTypeService.budgetTypeNameExists(type.name);
        if (!exists) {
          final id = await _budgetTypeService.createBudgetType(type);
          ids.add(id);
        } else {
          final snap = await _firestore.collection('budget_types').where('name', isEqualTo: type.name).get();
          if (snap.docs.isNotEmpty) ids.add(snap.docs.first.id);
        }
      } catch (e) { print('Erro BudgetType: $e'); }
    }
    return ids;
  }

  // ─── Job Roles ─────────────────────────────────────────────────────────────
  // FIX: baseSalary removido — cargos usam hourlyRate (valor/hora para M.O.)

  Future<List<String>> _seedJobRoles() async {
    final now = DateTime.now();
    final roles = [
      JobRoleModel(id: '', title: 'Mestre de Obras', sector: 'Operacional', description: 'Gestão de canteiro',    hourlyRate: 35.00, requirements: ['Exp 5 anos'], createdAt: now),
      JobRoleModel(id: '', title: 'Pedreiro',         sector: 'Operacional', description: 'Execução de alvenaria', hourlyRate: 22.00, requirements: [],             createdAt: now),
      JobRoleModel(id: '', title: 'Servente',         sector: 'Operacional', description: 'Auxiliar geral',        hourlyRate: 14.50, requirements: [],             createdAt: now),
      JobRoleModel(id: '', title: 'Engenheiro Civil', sector: 'Técnico',     description: 'RT da obra',            hourlyRate: 65.00, requirements: ['CREA Ativo'], createdAt: now),
    ];

    List<String> ids = [];
    for (final role in roles) {
      try {
        final query = await _firestore.collection('job_roles').where('title', isEqualTo: role.title).get();
        if (query.docs.isEmpty) {
          final docRef = await _firestore.collection('job_roles').add(role.toMap());
          await docRef.update({'id': docRef.id});
          ids.add(docRef.id);
        } else {
          ids.add(query.docs.first.id);
        }
      } catch (e) { print('Erro JobRole: $e'); }
    }
    return ids;
  }

  // ─── Items ─────────────────────────────────────────────────────────────────

  Future<List<String>> _seedItems() async {
    final now = DateTime.now();
    final items = [
      Item(id: '', name: 'Cimento CP-II',  description: 'Saco 50kg',    unit: 'sac', weight: 50.0,   createdAt: now, updatedAt: now),
      Item(id: '', name: 'Areia Média',    description: 'Metro cúbico', unit: 'm³',  weight: 1500.0, createdAt: now, updatedAt: now),
      Item(id: '', name: 'Tijolo 8 Furos', description: 'Milheiro',     unit: 'mil', weight: 2000.0, createdAt: now, updatedAt: now),
      Item(id: '', name: 'Vergalhão 3/8',  description: 'Barra 12m',    unit: 'br',  weight: 8.0,    createdAt: now, updatedAt: now),
      Item(id: '', name: 'Tinta Acrílica', description: 'Lata 18L',     unit: 'lat', weight: 18.0,   createdAt: now, updatedAt: now),
    ];

    List<String> ids = [];
    for (final it in items) {
      try {
        final query = await _firestore.collection('items').where('name', isEqualTo: it.name).get();
        if (query.docs.isEmpty) {
          final docRef = await _firestore.collection('items').add(it.toMap());
          await docRef.update({'id': docRef.id});
          ids.add(docRef.id);
        } else {
          ids.add(query.docs.first.id);
        }
      } catch (e) { print('Erro Item: $e'); }
    }
    return ids;
  }

  // ─── Suppliers ─────────────────────────────────────────────────────────────

  Future<List<String>> _seedSuppliers() async {
    final now = DateTime.now();
    final suppliers = [
      Supplier(id: '', name: 'ConstruMax Materiais', cnpj: '12345678000190', isActive: true, createdAt: now, updatedAt: now),
      Supplier(id: '', name: 'Depósito do Zé',       cnpj: '98765432000110', isActive: true, createdAt: now, updatedAt: now),
      Supplier(id: '', name: 'Aço Forte S.A.',        cnpj: '45678901000123', isActive: true, createdAt: now, updatedAt: now),
    ];

    List<String> ids = [];
    for (var s in suppliers) {
      try {
        final available = await _supplierService.isCnpjAvailable(s.cnpj);
        if (available) await _supplierService.createSupplier(s);
        final query = await _firestore.collection('suppliers').where('cnpj', isEqualTo: s.cnpj).get();
        if (query.docs.isNotEmpty) ids.add(query.docs.first.id);
      } catch (e) { print('Erro Supplier: $e'); }
    }
    return ids;
  }

  // ─── Employees ─────────────────────────────────────────────────────────────
  // FIX: salary → baseSalary + updatedAt obrigatório

  Future<List<String>> _seedEmployees(List<String> roleIds) async {
    if (roleIds.isEmpty) return [];
    final now = DateTime.now();

    final employees = [
      {'name': 'Carlos Silva',   'jobTitle': 'Mestre de Obras', 'sector': 'Operacional', 'role': EmployeeRole.supervisor,  'education': 'Ensino Médio'},
      {'name': 'João Santos',    'jobTitle': 'Pedreiro',         'sector': 'Operacional', 'role': EmployeeRole.funcionario, 'education': 'Ensino Fundamental'},
      {'name': 'Maria Oliveira', 'jobTitle': 'Engenheiro Civil', 'sector': 'Técnico',     'role': EmployeeRole.coordenador, 'education': 'Superior Completo'},
      {'name': 'Pedro Souza',    'jobTitle': 'Servente',         'sector': 'Operacional', 'role': EmployeeRole.funcionario, 'education': 'Ensino Fundamental'},
      {'name': 'Ana Lima',       'jobTitle': 'Engenheiro Civil', 'sector': 'Técnico',     'role': EmployeeRole.coordenador, 'education': 'Superior Completo'},
    ];

    // Salários individuais — pertencem ao funcionário, não ao cargo
    final salaries = [5000.0, 2800.0, 8500.0, 1600.0, 8500.0];

    List<String> ids = [];
    for (var i = 0; i < employees.length; i++) {
      try {
        final data  = employees[i];
        final email = 'func$i@granith.com';

        final query = await _firestore.collection('employees').where('email', isEqualTo: email).get();
        if (query.docs.isNotEmpty) {
          ids.add(query.docs.first.id);
          continue;
        }

        final employee = EmployeeModel(
          id:             '',
          name:           data['name']      as String,
          email:          email,
          phone:          '(11) 99999-000$i',
          jobTitle:       data['jobTitle']  as String,
          sector:         data['sector']    as String,
          baseSalary:     salaries[i],           // FIX: salary → baseSalary
          role:           data['role']      as EmployeeRole,
          admissionDate:  now.subtract(Duration(days: _random.nextInt(365))),
          educationLevel: data['education'] as String,
          createdAt:      now,
          updatedAt:      now,                   // FIX: campo obrigatório adicionado
        );

        final docRef = await _firestore.collection('employees').add(employee.toMap());
        await docRef.update({'id': docRef.id});
        ids.add(docRef.id);
      } catch (e) { print('Erro Employee: $e'); }
    }
    return ids;
  }

  // ─── Teams ─────────────────────────────────────────────────────────────────

  Future<void> _seedTeams(List<String> employeeIds) async {
    if (employeeIds.isEmpty) return;
    final now = DateTime.now();

    final teamsData = [
      {'name': 'Equipe Alfa',  'description': 'Equipe de execução de obras estruturais',      'memberIndices': [0, 1, 3], 'leaderIndex': 0},
      {'name': 'Equipe Beta',  'description': 'Equipe técnica de engenharia e planejamento',  'memberIndices': [2, 4],    'leaderIndex': 2},
      {'name': 'Equipe Gamma', 'description': 'Equipe multidisciplinar de acabamento',        'memberIndices': [0, 2, 3], 'leaderIndex': 2},
    ];

    for (final data in teamsData) {
      try {
        final query = await _firestore.collection('teams')
            .where('name', isEqualTo: data['name'])
            .where('isActive', isEqualTo: true)
            .get();
        if (query.docs.isNotEmpty) {
          print('   -> Equipe "${data['name']}" já existe, pulando.');
          continue;
        }

        final indices     = data['memberIndices'] as List<int>;
        final leaderIndex = data['leaderIndex']   as int;

        final memberIds = indices
            .where((i) => i < employeeIds.length)
            .map((i) => employeeIds[i])
            .toList();

        final leaderId = leaderIndex < employeeIds.length
            ? employeeIds[leaderIndex]
            : null;

        final team = TeamModel(
          id:          '',
          name:        data['name']        as String,
          description: data['description'] as String,
          memberIds:   memberIds,
          leaderId:    leaderId,
          isActive:    true,
          createdAt:   now,
          updatedAt:   now,
        );

        final docRef = await _firestore.collection('teams').add(team.toMap());
        await docRef.update({'id': docRef.id});
        print('   -> Equipe criada: ${data['name']} (${memberIds.length} membros)');
      } catch (e) { print('Erro Team: $e'); }
    }
  }

  // ─── Projects ──────────────────────────────────────────────────────────────

  Future<List<Project>> _seedProjects() async {
    List<Project> createdProjects = [];
    final existing = await _projectService.getProjects();
    if (existing.length >= _projectNames.length) return existing;

    for (var i = 0; i < _projectNames.length; i++) {
      final name = _projectNames[i];
      if (existing.any((p) => p.name == name)) {
        createdProjects.add(existing.firstWhere((p) => p.name == name));
        continue;
      }

      final status   = ProjectStatus.values[_random.nextInt(ProjectStatus.values.length)];
      final budget   = 100000.0 + _random.nextDouble() * 900000.0;
      final imageUrl = _projectImages[i % _projectImages.length];

      final project = Project(
        id:          '',
        name:        name,
        client:      'Cliente ${String.fromCharCode(65 + i)}',
        description: 'Projeto completo de construção civil.',
        status:      status,
        startDate:   DateTime.now().subtract(Duration(days: _random.nextInt(100))),
        endDate:     DateTime.now().add(Duration(days: 60 + _random.nextInt(300))),
        budget:      double.parse(budget.toStringAsFixed(2)),
        currentCost: 0.0,
        location:    _locations[_random.nextInt(_locations.length)],
        tags:        ['Obra', 'Civil'],
        teamSize:    5 + _random.nextInt(20),
      );

      final Map<String, dynamic> projectMap = project.toMap();
      projectMap['imageUrl'] = imageUrl;

      try {
        final docRef     = await _firestore.collection('projects').add(projectMap);
        await docRef.update({'id': docRef.id});
        final savedProject = Project.fromMap(projectMap as String, docRef.id as Map<String, dynamic>);
        createdProjects.add(savedProject);
        print('   -> Projeto criado: $name');
      } catch (e) { print('Erro criar projeto: $e'); }
    }
    return createdProjects;
  }

  // ─── Budgets ───────────────────────────────────────────────────────────────

  Future<void> _seedBudgets(List<Project> projects, List<String> budgetTypeIds) async {
    if (projects.isEmpty) return;
    for (var project in projects) {
      if (_random.nextBool()) continue;
      final newId  = _firestore.collection('budgets').doc().id;
      final typeId = budgetTypeIds.isNotEmpty ? budgetTypeIds[_random.nextInt(budgetTypeIds.length)] : null;
      final budget = Budget(
        id:             newId,
        clientName:     project.client,
        projectName:    project.name,
        projectId:      project.id,
        budgetTypeId:   typeId,
        description:    'Orçamento Executivo',
        totalValue:     project.budget * 0.8,
        creationDate:   DateTime.now(),
        status:         BudgetStatus.approved,
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        items: [
          BudgetItem(description: 'Fase 1', quantity: 1, unitPrice: project.budget * 0.3),
          BudgetItem(description: 'Fase 2', quantity: 1, unitPrice: project.budget * 0.5),
        ],
      );
      try {
        await _budgetService.addBudget(budget);
      } catch (e) { print('Erro Orçamento: $e'); }
    }
  }

  // ─── Purchases ─────────────────────────────────────────────────────────────

  Future<void> _seedPurchases(List<Project> projects, List<String> supplierIds, List<String> itemIds) async {
    if (projects.isEmpty || supplierIds.isEmpty || itemIds.isEmpty) return;
    for (var project in projects) {
      final count = 1 + _random.nextInt(3);
      for (int i = 0; i < count; i++) {
        try {
          final supplierId   = supplierIds[_random.nextInt(supplierIds.length)];
          final itemId       = itemIds[_random.nextInt(itemIds.length)];
          final itemDoc      = await _firestore.collection('items').doc(itemId).get();
          final itemName     = itemDoc.data()?['name']     ?? 'Material';
          final supplierDoc  = await _firestore.collection('suppliers').doc(supplierId).get();
          final supplierName = supplierDoc.data()?['name'] ?? 'Fornecedor';
          final price        = 20.0 + _random.nextDouble() * 100.0;
          final qty          = 10 + _random.nextInt(50);
          final total        = qty * price;
          final date         = DateTime.now().subtract(Duration(days: _random.nextInt(30)));

          final purchase = Purchase(
            id:              '',
            projectId:       project.id,
            projectName:     project.name,
            supplierId:      supplierId,
            supplierName:    supplierName,
            itemId:          itemId,
            itemName:        itemName,
            purchaseDate:    date,
            deliveryAddress: project.location,
            totalValue:      double.parse(total.toStringAsFixed(2)),
            status:          PurchaseStatus.delivered,
          );

          final docRef = await _firestore.collection('purchases').add(purchase.toMap());
          await docRef.update({'id': docRef.id});
        } catch (e) { print('Erro Purchase: $e'); }
      }
    }
  }

  // ─── Inventory ─────────────────────────────────────────────────────────────

  Future<void> _seedInventory(List<Project> projects, List<String> itemIds) async {
    if (itemIds.isEmpty) return;
    for (var itemId in itemIds) {
      try {
        final itemDoc  = await _firestore.collection('items').doc(itemId).get();
        final itemName = itemDoc.data()?['name'] ?? 'Item';
        final unit     = itemDoc.data()?['unit']  ?? 'un';

        final inventory = InventoryItem(
          id:          '',
          name:        itemName,
          quantity:    (100 + _random.nextInt(500)).toDouble(),
          minQuantity: 50.0,
          unit:        unit,
          updatedAt:   DateTime.now(),
        );

        final query = await _firestore.collection('inventory').where('name', isEqualTo: itemName).get();
        if (query.docs.isEmpty) {
          final docRef = await _firestore.collection('inventory').add(inventory.toMap());
          await docRef.update({'id': docRef.id});
        }
      } catch (e) { print('Erro Inventory: $e'); }
    }
  }

  // ─── Requisitions ──────────────────────────────────────────────────────────

  Future<void> _seedRequisitions(List<Project> projects, List<String> itemIds) async {
    if (projects.isEmpty) return;
    for (var project in projects) {
      try {
        final req = MaterialRequisitionModel(
          id:            '',
          projectId:     project.id,
          projectName:   project.name,
          requesterName: 'Mestre de Obras',
          requestDate:   DateTime.now(),
          status:        RequisitionStatus.pending,
          priority:      'Alta',
          items:         [RequisitionItem(itemName: 'Cimento CP-II', quantity: 5, unit: 'sac')],
          createdAt:     DateTime.now(),
        );
        await _requisitionService.addRequisition(req);
      } catch (e) { print('Erro Requisição: $e'); }
    }
  }

  // ─── Daily Logs ────────────────────────────────────────────────────────────

  Future<void> _seedDailyLogs(List<Project> projects, List<String> employeeIds) async {
    if (projects.isEmpty) return;
    for (var project in projects) {
      try {
        for (int i = 0; i < 2; i++) {
          final weather = i == 0 ? WeatherCondition.sol : WeatherCondition.chuvoso;
          final log = DailyLogModel(
            id:                   '',
            projectId:            project.id,
            projectName:          project.name,
            date:                 DateTime.now().subtract(Duration(days: i)),
            weatherMorning:       weather,
            weatherAfternoon:     weather,
            manpower:             {'Pedreiro': 3, 'Servente': 2},
            activitiesDescription: 'Reboco e pintura da parede norte.',
            impediments:          i == 1 ? 'Atraso na entrega de areia.' : '',
            createdByUserId:      employeeIds.isNotEmpty ? employeeIds.first : 'admin',
          );
          final docRef = await _firestore.collection('daily_logs').add(log.toMap());
          await docRef.update({'id': docRef.id});
        }
      } catch (e) { print('Erro DailyLog: $e'); }
    }
  }

  // ─── Financials ────────────────────────────────────────────────────────────

  Future<void> _seedFinancials(List<Project> projects, List<String> budgetTypeIds) async {
    if (projects.isEmpty) return;
    final now = DateTime.now();

    for (var project in projects) {
      try {
        final transactions = [
          FinancialTransactionModel(
            id: '', description: 'Pagamento Diárias — ${project.name}',
            amount: 1500.00, type: TransactionType.expense, status: TransactionStatus.paid,
            origin: TransactionOrigin.manual, category: TransactionCategory.labor,
            dueDate: now.subtract(const Duration(days: 5)),
            paymentDate: now.subtract(const Duration(days: 4)),
            projectId: project.id, createdBy: 'seeder', createdAt: now,
          ),
          FinancialTransactionModel(
            id: '', description: 'Compra de Material — ${project.name}',
            amount: 3200.00, type: TransactionType.expense, status: TransactionStatus.paid,
            origin: TransactionOrigin.purchase, category: TransactionCategory.material,
            dueDate: now.subtract(const Duration(days: 10)),
            paymentDate: now.subtract(const Duration(days: 9)),
            projectId: project.id, createdBy: 'seeder', createdAt: now,
          ),
          FinancialTransactionModel(
            id: '', description: 'Aluguel Equipamento — ${project.name}',
            amount: 800.00, type: TransactionType.expense, status: TransactionStatus.pending,
            origin: TransactionOrigin.manual, category: TransactionCategory.equipment,
            dueDate: now.add(const Duration(days: 10)),
            projectId: project.id, createdBy: 'seeder', createdAt: now,
          ),
          FinancialTransactionModel(
            id: '', description: 'Fornecedor Pendente — ${project.name}',
            amount: 1200.00, type: TransactionType.expense, status: TransactionStatus.overdue,
            origin: TransactionOrigin.purchase, category: TransactionCategory.material,
            dueDate: now.subtract(const Duration(days: 8)),
            projectId: project.id, createdBy: 'seeder', createdAt: now,
          ),
          FinancialTransactionModel(
            id: '', description: 'Aporte Cliente — 1ª Parcela — ${project.name}',
            amount: 20000.00, type: TransactionType.income, status: TransactionStatus.paid,
            origin: TransactionOrigin.budget, category: TransactionCategory.measurement,
            dueDate: now.subtract(const Duration(days: 10)),
            paymentDate: now.subtract(const Duration(days: 10)),
            projectId: project.id, createdBy: 'seeder', createdAt: now,
          ),
          FinancialTransactionModel(
            id: '', description: 'Medição #2 — ${project.name}',
            amount: 15000.00, type: TransactionType.income, status: TransactionStatus.pending,
            origin: TransactionOrigin.budget, category: TransactionCategory.measurement,
            dueDate: now.add(const Duration(days: 15)),
            projectId: project.id, createdBy: 'seeder', createdAt: now,
          ),
        ];

        for (final t in transactions) {
          final ref = await _firestore.collection('financial_transactions').add(t.toMap());
          await ref.update({'id': ref.id});
        }
        print('   -> Financeiro seeded: ${project.name} (${transactions.length} transações)');
      } catch (e) { print('Erro Financial (${project.name}): $e'); }
    }
  }

  Future<bool> ensureSyncedWithEmulator({int timeoutSeconds = 20}) async {
    print('🔁 SEEDER: Iniciando verificação...');
    try {
      return await seed();
    } catch (e) {
      print('❌ SEEDER: Erro na verificação: $e');
      return false;
    }
  }
}