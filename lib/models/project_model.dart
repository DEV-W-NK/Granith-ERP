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
    required this.id,
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

  double get progressPercentage {
    if (budget == 0) return 0;
    return (currentCost / budget * 100).clamp(0, 100);
  }

  String get formattedBudget => 'R\$ ${budget.toStringAsFixed(2)}';
  String get formattedCurrentCost => 'R\$ ${currentCost.toStringAsFixed(2)}';

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
}

// Exemplo de projetos de teste
class ProjectModel {
  static List<Project> sampleProjects = [
    Project(
      id: '1',
      name: 'Projeto A',
      client: 'Cliente X',
      description: 'Descrição do Projeto A',
      status: ProjectStatus.planning,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 30)),
      budget: 10000,
      currentCost: 2000,
      location: 'São Paulo',
      tags: ['Urgente', 'Alto Impacto'],
      teamSize: 5,
    ),
    Project(
      id: '2',
      name: 'Projeto B',
      client: 'Cliente Y',
      description: 'Descrição do Projeto B',
      status: ProjectStatus.inProgress,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 60)),
      budget: 20000,
      currentCost: 8000,
      location: 'Rio de Janeiro',
      tags: ['Médio', 'Importante'],
      teamSize: 8,
    ),
  ];
}
