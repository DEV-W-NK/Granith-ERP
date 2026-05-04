import 'dart:async';

import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/services/team_service.dart';

class FakeTeamService extends TeamService {
  FakeTeamService({
    List<EmployeeModel>? employees,
    List<TeamModel>? teams,
  }) : _employees = List<EmployeeModel>.from(employees ?? const []),
       _teams = List<TeamModel>.from(teams ?? const []),
       _employeeController = StreamController<List<EmployeeModel>>.broadcast(),
       _teamController = StreamController<List<TeamModel>>.broadcast();

  final List<EmployeeModel> _employees;
  final List<TeamModel> _teams;
  final StreamController<List<EmployeeModel>> _employeeController;
  final StreamController<List<TeamModel>> _teamController;

  Object? employeeStreamError;
  Object? teamStreamError;
  Object? saveEmployeeError;
  Object? deleteEmployeeError;
  Object? dismissEmployeeError;
  Object? createTeamError;
  Object? updateTeamError;
  Object? deleteTeamError;
  Object? addMemberError;
  Object? removeMemberError;
  Object? setLeaderError;

  EmployeeModel? lastSavedEmployee;
  String? lastDeletedEmployeeId;
  String? lastDismissedEmployeeId;
  TeamModel? lastCreatedTeam;
  TeamModel? lastUpdatedTeam;
  String? lastDeletedTeamId;
  String? lastMemberTeamId;
  String? lastMemberEmployeeId;
  String? lastLeaderTeamId;
  String? lastLeaderEmployeeId;
  String createdTeamId = 'team-created';

  @override
  Stream<List<EmployeeModel>> getEmployees() {
    if (employeeStreamError != null) {
      return Stream<List<EmployeeModel>>.error(employeeStreamError!);
    }

    Future<void>.microtask(() {
      if (!_employeeController.isClosed) {
        _employeeController.add(List<EmployeeModel>.from(_employees));
      }
    });
    return _employeeController.stream;
  }

  @override
  Stream<List<TeamModel>> getTeams() {
    if (teamStreamError != null) {
      return Stream<List<TeamModel>>.error(teamStreamError!);
    }

    Future<void>.microtask(() {
      if (!_teamController.isClosed) {
        _teamController.add(List<TeamModel>.from(_teams));
      }
    });
    return _teamController.stream;
  }

  void emitEmployees(List<EmployeeModel> employees) {
    _employees
      ..clear()
      ..addAll(employees);
    if (!_employeeController.isClosed) {
      _employeeController.add(List<EmployeeModel>.from(_employees));
    }
  }

  void emitTeams(List<TeamModel> teams) {
    _teams
      ..clear()
      ..addAll(teams);
    if (!_teamController.isClosed) {
      _teamController.add(List<TeamModel>.from(_teams));
    }
  }

  @override
  Future<String> saveEmployee(EmployeeModel employee) async {
    if (saveEmployeeError != null) {
      throw saveEmployeeError!;
    }

    lastSavedEmployee = employee;
    final index = _employees.indexWhere((entry) => entry.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee;
    } else {
      _employees.add(employee.copyWith());
    }
    emitEmployees(_employees);
    return employee.id.isEmpty ? 'employee-created' : employee.id;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    if (deleteEmployeeError != null) {
      throw deleteEmployeeError!;
    }

    lastDeletedEmployeeId = id;
    _employees.removeWhere((entry) => entry.id == id);
    emitEmployees(_employees);
  }

  @override
  Future<void> dismissEmployee(String id) async {
    if (dismissEmployeeError != null) {
      throw dismissEmployeeError!;
    }

    lastDismissedEmployeeId = id;
  }

  @override
  Future<String> createTeam(TeamModel team) async {
    if (createTeamError != null) {
      throw createTeamError!;
    }

    lastCreatedTeam = team;
    final created = team.copyWith(id: createdTeamId);
    _teams.add(created);
    emitTeams(_teams);
    return createdTeamId;
  }

  @override
  Future<void> updateTeam(TeamModel team) async {
    if (updateTeamError != null) {
      throw updateTeamError!;
    }

    lastUpdatedTeam = team;
    final index = _teams.indexWhere((entry) => entry.id == team.id);
    if (index >= 0) {
      _teams[index] = team;
    }
    emitTeams(_teams);
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    if (deleteTeamError != null) {
      throw deleteTeamError!;
    }

    lastDeletedTeamId = teamId;
  }

  @override
  Future<void> addMemberToTeam(String teamId, String employeeId) async {
    if (addMemberError != null) {
      throw addMemberError!;
    }

    lastMemberTeamId = teamId;
    lastMemberEmployeeId = employeeId;
  }

  @override
  Future<void> removeMemberFromTeam(String teamId, String employeeId) async {
    if (removeMemberError != null) {
      throw removeMemberError!;
    }

    lastMemberTeamId = teamId;
    lastMemberEmployeeId = employeeId;
  }

  @override
  Future<void> setTeamLeader(String teamId, String? employeeId) async {
    if (setLeaderError != null) {
      throw setLeaderError!;
    }

    lastLeaderTeamId = teamId;
    lastLeaderEmployeeId = employeeId;
  }

  Future<void> disposeControllers() async {
    await _employeeController.close();
    await _teamController.close();
  }
}
