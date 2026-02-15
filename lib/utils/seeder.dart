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

class DatabaseSeeder {
  final ServiceProjetos _projectService = ServiceProjetos();
  final SupplierService _supplierService = SupplierService();
  final BudgetTypeService _budgetTypeService = BudgetTypeService();
  final ServiceOrcamentos _budgetService = ServiceOrcamentos();

  final Random _random = Random();

  final List<String> _locations = [
    'São Paulo - SP',
    'Rio de Janeiro - RJ',
    'Curitiba - PR',
    'Belo Horizonte - MG',
    'Campinas - SP'
  ];

  final List<String> _projectNames = [
    'Residencial Alphaville',
    'Reforma Loja Shopping',
    'Edifício Comercial Horizon',
    'Casa de Praia - Guarujá',
    'Centro Logístico Norte'
  ];

  Future<void> seed() async {
    print('🌱 Iniciando Seeder Corrigido...');

    try {
      // 1. Tipos de Orçamento
      print('📦 Semeando Tipos de Orçamento...');
      final budgetTypes = await _seedBudgetTypes();

      // 2. Fornecedores
      print('🚚 Semeando Fornecedores...');
      // Nota: Fornecedores são criados, mas não vinculados diretamente ao Budget
      // no modelo atual, pois o modelo Budget não possui supplierId.
      await _seedSuppliers();

      // 3. Projetos
      print('🏗️ Semeando Projetos...');
      final projects = await _seedProjects();

      // 4. Orçamentos
      print('💰 Semeando Orçamentos...');
      await _seedBudgets(projects, budgetTypes);

      print('✅ Database populado com sucesso!');
    } catch (e) {
      print('❌ Erro crítico no seeder: $e');
    }
  }

  Future<List<String>> _seedBudgetTypes() async {
    final now = DateTime.now();
    
    final types = [
      BudgetType(
        id: '', // O ID será gerado pelo Firestore no createBudgetType
        name: 'Mão de Obra',
        description: 'Serviços gerais de pedreiro, pintor, etc.',
        category: 'Serviço', 
        isActive: true,
        createdAt: now,
        updatedAt: now,
        iconName: 'engineering',
        color: 'F44336', // Colors.red hex
      ),
      BudgetType(
        id: '',
        name: 'Material Básico',
        description: 'Cimento, areia, tijolo, pedra.',
        category: 'Material',
        isActive: true,
        createdAt: now,
        updatedAt: now,
        iconName: 'foundation',
        color: '795548', // Colors.brown hex
      ),
      BudgetType(
        id: '',
        name: 'Acabamento',
        description: 'Pisos, revestimentos, louças e metais.',
        category: 'Material',
        isActive: true,
        createdAt: now,
        updatedAt: now,
        iconName: 'format_paint',
        color: '2196F3', // Colors.blue hex
      ),
    ];

    List<String> ids = [];
    
    for (var type in types) {
       try {
         // Verifica se já existe pelo nome para evitar duplicatas
         final exists = await _budgetTypeService.budgetTypeNameExists(type.name);
         if (!exists) {
           final id = await _budgetTypeService.createBudgetType(type);
           ids.add(id);
           print('   -> Criado Tipo: ${type.name}');
         } else {
           print('   -> Tipo já existe: ${type.name}');
         }
       } catch (e) {
         print('   -> Erro ao criar tipo ${type.name}: $e');
       }
    }
    
    // Recupera todos os IDs para usar nos orçamentos
    if (ids.isEmpty) {
      final existing = await _budgetTypeService.getBudgetTypes();
      ids = existing.map((e) => e.id).toList();
    } else {
      // Se acabou de criar alguns, vamos pegar todos para garantir
      final all = await _budgetTypeService.getBudgetTypes();
      ids = all.map((e) => e.id).toList();
    }
    
    return ids;
  }

  Future<void> _seedSuppliers() async {
    final now = DateTime.now();

    // Nota: O seu SupplierModel é simples (apenas nome e CNPJ).
    // Dados como email, telefone e endereço não serão salvos pois não existem no model.
    final suppliersData = [
      Supplier(
        id: '', 
        name: 'ConstruMax Materiais',
        cnpj: '12345678000190',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Supplier(
        id: '',
        name: 'Elétrica & Cia',
        cnpj: '98765432000110',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Supplier(
        id: '',
        name: 'Tintas Arco-Íris',
        cnpj: '45678901000123',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
       Supplier(
        id: '',
        name: 'Empreiteira Fortes',
        cnpj: '33444555000167',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (var s in suppliersData) {
      try {
        final available = await _supplierService.isCnpjAvailable(s.cnpj);
        if (available) {
          await _supplierService.createSupplier(s);
          print('   -> Criado Fornecedor: ${s.name}');
        } else {
           print('   -> Fornecedor já existe: ${s.name}');
        }
      } catch (e) {
         print('   -> Erro fornecedor ${s.name}: $e');
      }
    }
  }

  Future<List<Project>> _seedProjects() async {
    List<Project> createdProjects = [];
    
    // Tenta buscar existentes primeiro
    try {
      final existing = await _projectService.getProjects();
      if (existing.isNotEmpty) {
        createdProjects.addAll(existing);
      }
    } catch (e) {
      print('Erro ao buscar projetos existentes: $e');
    }

    // Se tiver poucos projetos, cria mais
    if (createdProjects.length < 3) {
      for (var i = 0; i < _projectNames.length; i++) {
        final name = _projectNames[i];
        
        // Evita duplicar pelo nome (verificação simples local)
        if (createdProjects.any((p) => p.name == name)) continue;

        final status = ProjectStatus.values[_random.nextInt(ProjectStatus.values.length)];
        final budget = 50000.0 + _random.nextDouble() * 450000.0;
        final currentCost = budget * (0.1 + _random.nextDouble() * 0.8);

        final project = Project(
          id: '', // Service gera ID
          name: name,
          client: 'Cliente ${String.fromCharCode(65 + i)}',
          description: 'Projeto completo de reforma e construção.',
          status: status,
          startDate: DateTime.now().subtract(Duration(days: _random.nextInt(100))),
          endDate: DateTime.now().add(Duration(days: 30 + _random.nextInt(200))),
          budget: double.parse(budget.toStringAsFixed(2)),
          currentCost: double.parse(currentCost.toStringAsFixed(2)),
          location: _locations[_random.nextInt(_locations.length)],
          tags: ['Obra', status == ProjectStatus.inProgress ? 'Andamento' : 'Planejamento'],
          teamSize: 3 + _random.nextInt(15),
        );

        try {
          final id = await _projectService.addProject(project);
          // O addProject retorna String, precisamos recriar o objeto com ID para retornar
          createdProjects.add(project.copyWith(id: id));
          print('   -> Criado Projeto: $name');
        } catch (e) {
          print('   -> Erro projeto $name: $e');
        }
      }
    }

    return createdProjects;
  }

  Future<void> _seedBudgets(List<Project> projects, List<String> budgetTypeIds) async {
    if (projects.isEmpty) return;

    for (var project in projects) {
      // Cria 2 a 5 orçamentos por projeto
      final budgetsCount = 2 + _random.nextInt(4);

      for (var i = 0; i < budgetsCount; i++) {
        // Gera um ID manualmente pois o ServiceOrcamentos.addBudget usa .set()
        final newId = FirebaseFirestore.instance.collection('budgets').doc().id;
        
        final typeId = budgetTypeIds.isNotEmpty 
            ? budgetTypeIds[_random.nextInt(budgetTypeIds.length)] 
            : null;
        
        final valueBase = 1000.0 + _random.nextDouble() * 20000.0;
        
        // Cria itens do orçamento
        final items = [
          BudgetItem(
            description: 'Item Material 1', 
            quantity: 1, 
            unitPrice: valueBase * 0.6
          ),
          BudgetItem(
            description: 'Item Serviço 1', 
            quantity: 2, 
            unitPrice: valueBase * 0.2
          ),
        ];

        final totalValue = items.fold(0.0, (sum, item) => sum + item.total);
        
        final budget = Budget(
          id: newId,
          clientName: project.client, // Vincula ao cliente do projeto
          projectName: project.name,  // Vincula ao nome do projeto
          projectId: project.id,
          budgetTypeId: typeId,
          description: 'Orçamento #${i + 1} referente à etapa inicial',
          totalValue: double.parse(totalValue.toStringAsFixed(2)),
          creationDate: DateTime.now().subtract(Duration(days: _random.nextInt(60))),
          status: BudgetStatus.values[_random.nextInt(BudgetStatus.values.length)],
          expirationDate: DateTime.now().add(Duration(days: 15)),
          items: items,
        );

        try {
          await _budgetService.addBudget(budget);
          print('   -> Criado Orçamento para: ${project.name}');
        } catch (e) {
          print('   -> Erro ao criar orçamento: $e');
        }
      }
    }
  }
}