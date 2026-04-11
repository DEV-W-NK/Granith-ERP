import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum ProjectStatus { planning, inProgress, completed }

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planejamento';
      case ProjectStatus.inProgress:
        return 'Em Progresso';
      case ProjectStatus.completed:
        return 'Concluido';
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
  final String? clientAccountId;
  final String? clientAccountName;

  const Project({
    this.id = '',
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
    this.clientAccountId,
    this.clientAccountName,
  });

  double get progressPercentage {
    if (budget == 0) return 0;
    return (currentCost / budget * 100).clamp(0, 100);
  }

  String get formattedBudget => 'R\$ ${budget.toStringAsFixed(2)}';
  String get formattedCurrentCost => 'R\$ ${currentCost.toStringAsFixed(2)}';
  String get formattedProgress => '${progressPercentage.toStringAsFixed(1)}%';
  double get remainingBudget => (budget - currentCost).clamp(0, double.infinity);
  String get formattedRemainingBudget =>
      'R\$ ${remainingBudget.toStringAsFixed(2)}';
  bool get isOverBudget => currentCost > budget;
  bool get isCompleted => status == ProjectStatus.completed;
  bool get isInProgress => status == ProjectStatus.inProgress;
  bool get isPlanning => status == ProjectStatus.planning;

  bool get isOverdue {
    if (endDate == null || isCompleted) return false;
    return DateTime.now().isAfter(endDate!);
  }

  int? get daysUntilDeadline {
    if (endDate == null || isCompleted) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  int get totalDurationDays {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays.abs();
  }

  String get uniqueKey => '${name.trim().toLowerCase()}_${client.trim().toLowerCase()}';

  String get contentHash =>
      '$name$client$description${status.name}$budget$location${tags.join(',')}$teamSize$clientAccountId'
          .hashCode
          .toString();

  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) errors.add('Nome do projeto e obrigatorio');
    if (client.trim().isEmpty) errors.add('Cliente e obrigatorio');
    if (budget < 0) errors.add('Orcamento nao pode ser negativo');
    if (currentCost < 0) errors.add('Custo atual nao pode ser negativo');
    if (teamSize < 0) errors.add('Tamanho da equipe nao pode ser negativo');
    if (endDate != null && endDate!.isBefore(startDate)) {
      errors.add('Data de termino nao pode ser anterior a data de inicio');
    }

    return errors;
  }

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
    String? clientAccountId,
    String? clientAccountName,
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
      tags: tags ?? List<String>.from(this.tags),
      teamSize: teamSize ?? this.teamSize,
      imageUrl: imageUrl ?? this.imageUrl,
      clientAccountId: clientAccountId ?? this.clientAccountId,
      clientAccountName: clientAccountName ?? this.clientAccountName,
    );
  }

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
      tags: const [],
      teamSize: 0,
    );
  }

  factory Project.fromMap(String id, Map<String, dynamic> data) {
    return Project(
      id: id.isNotEmpty ? id : (data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      client: (data['client'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'planning'),
        orElse: () => ProjectStatus.planning,
      ),
      startDate: DbValue.toDateTime(data['startDate']) ??
          DbValue.toDateTime(data['createdAt']) ??
          DateTime.now(),
      endDate: DbValue.toDateTime(data['endDate']),
      budget: (data['budget'] ?? 0).toDouble(),
      currentCost: (data['currentCost'] ?? 0).toDouble(),
      location: (data['location'] ?? '').toString(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : <String>[],
      teamSize: (data['teamSize'] ?? 0) as int,
      imageUrl: data['imageUrl']?.toString().isEmpty == true
          ? null
          : data['imageUrl']?.toString(),
      clientAccountId:
          data['clientAccountId']?.toString() ?? data['client_account_id']?.toString(),
      clientAccountName: data['clientAccountName']?.toString() ??
          data['client_account_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'clientAccountId': clientAccountId,
      'client_account_id': clientAccountId,
      'clientAccountName': clientAccountName,
      'client_account_name': clientAccountName,
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
        other.teamSize == teamSize &&
        other.imageUrl == imageUrl &&
        other.clientAccountId == clientAccountId &&
        other.clientAccountName == clientAccountName;
  }

  @override
  int get hashCode => Object.hash(
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
        teamSize,
        imageUrl,
        clientAccountId,
        clientAccountName,
      );

  @override
  String toString() =>
      'Project(id: $id, name: $name, client: $client, status: $status)';
}

extension ProjectListExtension on List<Project> {
  List<Project> whereStatus(ProjectStatus status) =>
      where((project) => project.status == status).toList();

  List<Project> whereClient(String client) => where(
        (project) => project.client.toLowerCase().contains(client.toLowerCase()),
      ).toList();

  List<Project> get overdue => where((project) => project.isOverdue).toList();

  List<Project> get overBudget =>
      where((project) => project.isOverBudget).toList();

  Map<String, dynamic> get statistics {
    if (isEmpty) return {'total': 0};

    final totalBudget = fold(0.0, (sum, project) => sum + project.budget);
    final totalCost = fold(0.0, (sum, project) => sum + project.currentCost);
    final avgTeamSize = fold(0, (sum, project) => sum + project.teamSize) / length;

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

class ProjectModel {
  static List<Project> get sampleProjects => [
        Project(
          id: '1',
          name: 'Sistema de Gestao Empresarial',
          client: 'TechCorp Ltda',
          description: 'Desenvolvimento de sistema completo de gestao empresarial.',
          status: ProjectStatus.inProgress,
          startDate: DateTime.now().subtract(const Duration(days: 15)),
          endDate: DateTime.now().add(const Duration(days: 45)),
          budget: 150000.0,
          currentCost: 45000.0,
          location: 'Sao Paulo - SP',
          tags: const ['Urgente', 'Alto Valor', 'Estrategico'],
          teamSize: 8,
        ),
        Project(
          id: '2',
          name: 'Aplicativo de Delivery',
          client: 'FoodExpress SA',
          description: 'Aplicativo mobile para delivery com pagamentos.',
          status: ProjectStatus.planning,
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 90)),
          budget: 80000.0,
          currentCost: 12000.0,
          location: 'Rio de Janeiro - RJ',
          tags: const ['Mobile', 'Inovacao', 'B2C'],
          teamSize: 5,
        ),
      ];

  static Project createTestProject({
    String suffix = '',
    ProjectStatus status = ProjectStatus.planning,
  }) {
    final now = DateTime.now();
    return Project(
      name: 'Projeto Teste$suffix',
      client: 'Cliente Teste$suffix',
      description: 'Descricao do projeto de teste para validacao do sistema',
      status: status,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      budget: 10000.0,
      currentCost: 2500.0,
      location: 'Teste - SP',
      tags: const ['Teste', 'Validacao'],
      teamSize: 3,
    );
  }

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
