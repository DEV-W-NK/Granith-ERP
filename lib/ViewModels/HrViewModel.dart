import 'package:flutter/material.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/services/HrService.dart';

class HrViewModel extends ChangeNotifier {
  final HrService _hrService;

  HrViewModel(this._hrService);

  HrService get hrService => _hrService;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  EmployeeStatus? _statusFilter;
  EmployeeStatus? get statusFilter => _statusFilter;

  void updateSearch(String value) {
    final next = value.trim();
    if (_searchQuery == next) return;
    _searchQuery = next;
    notifyListeners();
  }

  void updateStatusFilter(EmployeeStatus? value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  List<EmployeeModel> filterEmployees(List<EmployeeModel> employees) {
    final query = _searchQuery.toLowerCase();
    final filtered =
        employees.where((employee) {
          final matchesStatus =
              _statusFilter == null || employee.status == _statusFilter;
          if (!matchesStatus) return false;
          if (query.isEmpty) return true;

          final searchable =
              [
                employee.name,
                employee.email,
                employee.phone,
                employee.jobTitle,
                employee.sector,
                employee.role.label,
                employee.status.name,
              ].join(' ').toLowerCase();

          return searchable.contains(query);
        }).toList();

    filtered.sort((a, b) {
      final statusOrder = _statusOrder(
        a.status,
      ).compareTo(_statusOrder(b.status));
      if (statusOrder != 0) return statusOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  Map<String, int> getEmployeeStats(List<EmployeeModel> employees) {
    return {
      'ativos': employees.where((e) => e.isActive).length,
      'ferias': employees.where((e) => e.isOnLeave).length,
      'desligados': employees.where((e) => e.isDismissed).length,
    };
  }

  int _statusOrder(EmployeeStatus status) => switch (status) {
    EmployeeStatus.ativo => 0,
    EmployeeStatus.ferias => 1,
    EmployeeStatus.afastado => 1,
    EmployeeStatus.desligado => 2,
  };
}
