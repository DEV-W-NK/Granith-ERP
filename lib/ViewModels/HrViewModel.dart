import 'package:flutter/material.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/services/HrService.dart';

class HrViewModel extends ChangeNotifier {
  final HrService _hrService;
  
  HrViewModel(this._hrService);

  // Estados de busca e filtro
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // No seu código original, você usa EmployeeStatus? para o filtro
  // Mas no StreamBuilder você usa employee.status. 
  // Vou manter a lógica de filtros reativos aqui.
  
  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  // Lógica de Insights ou processamento de dados para o Header
  Map<String, int> getEmployeeStats(List<EmployeeModel> employees) {
    return {
      'ativos': employees.where((e) => e.isActive).length,
      'ferias': employees.where((e) => e.isOnLeave).length,
      'desligados': employees.where((e) => e.isDismissed).length,
    };
  }
}