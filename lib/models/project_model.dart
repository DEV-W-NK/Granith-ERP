import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ProjectStatus { planning, inProgress, completed }

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planejamento';
      case ProjectStatus.inProgress:
        return 'Em Progresso';
      case ProjectStatus.completed:
        return 'Concluído';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return Colors.orange;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.completed:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectStatus.planning:
        return Icons.schedule;
      case ProjectStatus.inProgress:
        return Icons.work;
      case ProjectStatus.completed:
        return Icons.check_circle;
    }
  }
}

class Project {
  final String id;
  final String name;
  final String client;
  final String description;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double budget;
  final double currentCost;
  final String location;
  final List<String> tags;
  final int teamSize;
  final String? imageUrl;

  Project({
    this.id = '', // Permitir ID vazio para novos projetos
    required this.name,
    required this.client,
    required this.description,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.budget,
    required this.currentCost,
    required this.location,
    required this.tags,
    required this.teamSize,
    this.imageUrl,
  });

  // Computed properties
  double get progressPercentage {
    if (budget == 0) return 0;
    return (currentCost / budget * 100).clamp(0, 100);
  }

  String get formattedBudget => 'R\$ ${budget.toStringAsFixed(2)}';
  String get formattedCurrentCost => 'R\$ ${currentCost.toStringAsFixed(2)}';

  // NOVA: Formatação do progresso como string
  String get formattedProgress => '${progressPercentage.toStringAsFixed(1)}%';

  // NOVA: Valor restante do orçamento
  double get remainingBudget =>
      (budget - currentCost).clamp(0, double.infinity);
  String get formattedRemainingBudget =>
      'R\$ ${remainingBudget.toStringAsFixed(2)}';

  // NOVA: Verificações de estado
  bool get isOverBudget => currentCost > budget;
  bool get isCompleted => status == ProjectStatus.completed;
  bool get isInProgress => status == ProjectStatus.inProgress;
  bool get isPlanning => status == ProjectStatus.planning;

  // NOVA: Verificação de prazo
  bool get isOverdue {
    if (endDate == null || isCompleted) return false;
    return DateTime.now().isAfter(endDate!);
  }

  // NOVA: Dias restantes até o prazo
  int? get daysUntilDeadline {
    if (endDate == null || isCompleted) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0; // Já passou
    return endDate!.difference(now).inDays;
  }

  // NOVA: Duração total do projeto em dias
  int get totalDurationDays {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays.abs();
  }

  // NOVA: Chave única para identificação (usada pelo sistema de controle de duplicatas)
  String get uniqueKey {
    return '${name.trim().toLowerCase()}_${client.trim().toLowerCase()}';
  }

  // NOVA: Hash code baseado no conteúdo (útil para comparações)
  String get contentHash {
    return '$name$client$description${status.name}$budget$location${tags.join(',')}$teamSize'
        .hashCode
        .toString();
  }

  // NOVA: Validação básica do projeto
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Nome do projeto é obrigatório');
    }

    if (client.trim().isEmpty) {
      errors.add('Cliente é obrigatório');
    }

    if (budget < 0) {
      errors.add('Orçamento não pode ser negativo');
    }

    if (currentCost < 0) {
      errors.add('Custo atual não pode ser negativo');
    }

    if (teamSize < 0) {
      errors.add('Tamanho da equipe não pode ser negativo');
    }

    if (endDate != null && endDate!.isBefore(startDate)) {
      errors.add('Data de término não pode ser anterior à data de início');
    }

    if (name.length > 100) {
      errors.add('Nome do projeto muito longo (máximo 100 caracteres)');
    }

    if (client.length > 100) {
      errors.add('Nome do cliente muito longo (máximo 100 caracteres)');
    }

    return errors;
  }

  // NOVA: Verificar se o projeto é válido
  bool get isValid => validate().isEmpty;

  Project copyWith({
    String? id,
    String? name,
    String? client,
    String? description,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double? currentCost,
    String? location,
    List<String>? tags,
    int? teamSize,
    String? imageUrl,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      client: client ?? this.client,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      currentCost: currentCost ?? this.currentCost,
      location: location ?? this.location,
      tags: tags ?? List.from(this.tags),
      teamSize: teamSize ?? this.teamSize,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // NOVA: Factory para criar projeto vazio
  factory Project.empty() {
    return Project(
      name: '',
      client: '',
      description: '',
      status: ProjectStatus.planning,
      startDate: DateTime.now(),
      budget: 0,
      currentCost: 0,
      location: '',
      tags: [],
      teamSize: 0,
    );
  }

  // NOVA: Factory para criar projeto a partir de Map (Firebase)
  factory Project.fromMap(String id, Map<String, dynamic> data) {
    return Project(
      id: id,
      name: data['name'] ?? '',
      client: data['client'] ?? '',
      description: data['description'] ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'planning'),
        orElse: () => ProjectStatus.planning,
      ),
      startDate:
          data['startDate'] != null
              ? (data['startDate'] as Timestamp).toDate()
              : DateTime.now(),
      endDate:
          data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : null,
      budget: (data['budget'] ?? 0).toDouble(),
      currentCost: (data['currentCost'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      tags: data['tags'] != null ? List<String>.from(data['tags']) : <String>[],
      teamSize: data['teamSize'] ?? 0,
      imageUrl: data['imageUrl']?.isEmpty == true ? null : data['imageUrl'],
    );
  }

  // NOVA: Converter para Map (para Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'client': client.trim(),
      'description': description.trim(),
      'status': status.name,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'currentCost': currentCost,
      'location': location.trim(),
      'tags': tags.map((tag) => tag.trim()).toList(),
      'teamSize': teamSize,
      'imageUrl': imageUrl,
      'projectKey': uniqueKey,
      'contentHash': contentHash,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.client == client &&
        other.description == description &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.budget == budget &&
        other.currentCost == currentCost &&
        other.location == location &&
        other.tags.length == tags.length &&
        other.tags.every((tag) => tags.contains(tag)) &&
        other.teamSize == teamSize &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      client,
      description,
      status,
      startDate,
      endDate,
      budget,
      currentCost,
      location,
      tags,
      teamSize,
      imageUrl,
    ]);
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, client: $client, status: $status)';
  }
}

// NOVA: Extensão para listas de projetos
extension ProjectListExtension on List<Project> {
  // Filtrar por status
  List<Project> whereStatus(ProjectStatus status) {
    return where((project) => project.status == status).toList();
  }

  // Filtrar por cliente
  List<Project> whereClient(String client) {
    return where(
      (project) => project.client.toLowerCase().contains(client.toLowerCase()),
    ).toList();
  }

  // Filtrar projetos em atraso
  List<Project> get overdue {
    return where((project) => project.isOverdue).toList();
  }

  // Filtrar projetos com orçamento estourado
  List<Project> get overBudget {
    return where((project) => project.isOverBudget).toList();
  }

  // Calcular estatísticas
  Map<String, dynamic> get statistics {
    if (isEmpty) return {'total': 0};

    final totalBudget = fold(0.0, (sum, project) => sum + project.budget);
    final totalCost = fold(0.0, (sum, project) => sum + project.currentCost);
    final avgTeamSize =
        fold(0, (sum, project) => sum + project.teamSize) / length;

    final statusCounts = <String, int>{};
    for (final project in this) {
      statusCounts[project.status.name] =
          (statusCounts[project.status.name] ?? 0) + 1;
    }

    return {
      'total': length,
      'totalBudget': totalBudget,
      'totalCost': totalCost,
      'averageTeamSize': avgTeamSize,
      'statusCounts': statusCounts,
      'overdueCount': overdue.length,
      'overBudgetCount': overBudget.length,
    };
  }
}

// Classe para dados de exemplo e testes
class ProjectModel {
  // ATUALIZADO: Projetos de exemplo melhorados
  static List<Project> get sampleProjects => [
    Project(
      id: '1',
      name: 'Sistema de Gestão Empresarial',
      client: 'TechCorp Ltda',
      description:
          'Desenvolvimento de sistema completo de gestão empresarial com módulos de vendas, estoque, financeiro e recursos humanos.',
      status: ProjectStatus.inProgress,
      startDate: DateTime.now().subtract(const Duration(days: 15)),
      endDate: DateTime.now().add(const Duration(days: 45)),
      budget: 150000.0,
      currentCost: 45000.0,
      location: 'São Paulo - SP',
      tags: ['Urgente', 'Alto Valor', 'Estratégico'],
      teamSize: 8,
    ),
    Project(
      id: '2',
      name: 'Aplicativo de Delivery',
      client: 'FoodExpress SA',
      description:
          'Aplicativo mobile para delivery de comida com sistema de pagamento integrado e rastreamento em tempo real.',
      status: ProjectStatus.planning,
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 90)),
      budget: 80000.0,
      currentCost: 12000.0,
      location: 'Rio de Janeiro - RJ',
      tags: ['Mobile', 'Inovação', 'B2C'],
      teamSize: 5,
    ),
    Project(
      id: '3',
      name: 'Portal Educacional',
      client: 'Escola Digital Ltda',
      description:
          'Plataforma web para ensino à distância com videoconferência, gamificação e acompanhamento de progresso.',
      status: ProjectStatus.completed,
      startDate: DateTime.now().subtract(const Duration(days: 120)),
      endDate: DateTime.now().subtract(const Duration(days: 30)),
      budget: 60000.0,
      currentCost: 58000.0,
      location: 'Belo Horizonte - MG',
      tags: ['Educação', 'Web', 'Concluído'],
      teamSize: 6,
    ),
    Project(
      id: '4',
      name: 'Sistema de Monitoramento IoT',
      client: 'IndustrialTech Corp',
      description:
          'Sistema para monitoramento de equipamentos industriais usando sensores IoT e análise de dados em tempo real.',
      status: ProjectStatus.inProgress,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 15)), // Próximo do prazo
      budget: 200000.0,
      currentCost: 180000.0, // Próximo do orçamento
      location: 'Porto Alegre - RS',
      tags: ['IoT', 'Big Data', 'Crítico'],
      teamSize: 10,
    ),
  ];

  // NOVA: Criar projeto de teste para validação
  static Project createTestProject({
    String suffix = '',
    ProjectStatus status = ProjectStatus.planning,
  }) {
    final now = DateTime.now();
    return Project(
      name: 'Projeto Teste$suffix',
      client: 'Cliente Teste$suffix',
      description: 'Descrição do projeto de teste para validação do sistema',
      status: status,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      budget: 10000.0,
      currentCost: 2500.0,
      location: 'Teste - SP',
      tags: ['Teste', 'Validação'],
      teamSize: 3,
    );
  }

  // NOVA: Validar integridade dos dados de exemplo
  static List<String> validateSampleData() {
    final errors = <String>[];

    for (final project in sampleProjects) {
      final projectErrors = project.validate();
      if (projectErrors.isNotEmpty) {
        errors.addAll(projectErrors.map((error) => '${project.name}: $error'));
      }
    }

    return errors;
  }
}
