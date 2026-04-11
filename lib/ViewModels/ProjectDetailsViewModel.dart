import 'package:flutter/material.dart';
import 'package:project_granith/models/project_model.dart';

class ProjectDetailsViewModel extends ChangeNotifier {
  final Project project;

  ProjectDetailsViewModel({required this.project});

  // Aqui poderias adicionar lógica para atualizar o status do projeto,
  // calcular métricas em tempo real ou disparar notificações.
  
  bool get isOverBudget => project.isOverBudget;
  bool get isOverdue => project.isOverdue;
  bool get isCompleted => project.isCompleted;

  void refreshData() {
    // Lógica para recarregar dados do Firestore se necessário
    notifyListeners();
  }
}