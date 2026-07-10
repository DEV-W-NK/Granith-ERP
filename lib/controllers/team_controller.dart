import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/services/team_service.dart';

class TeamController extends ChangeNotifier {
  final TeamService _service;
  final ServiceProjetos? _projectService;

  TeamController({TeamService? service, ServiceProjetos? projectService})
    : _service = service ?? TeamService(),
      _projectService = projectService;

  List<EmployeeModel> _employees = [];
  List<TeamModel> _teams = [];
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  StreamSubscription<List<EmployeeModel>>? _employeeSub;
  StreamSubscription<List<TeamModel>>? _teamSub;
  StreamSubscription<List<Project>>? _projectSub;

  List<EmployeeModel> get employees => _employees;
  List<TeamModel> get teams => _teams;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void init() {
    if (_initialized) return;
    _initialized = true;

    _employeeSub = _service.getEmployees().listen(
      (list) {
        _employees = list;
        _clearError();
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar funcionarios: $e';
        notifyListeners();
      },
    );

    _teamSub = _service.getTeams().listen(
      (list) {
        _teams = list;
        _clearError();
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar equipes: $e';
        notifyListeners();
      },
    );

    if (_projectService != null) {
      _projectSub = _projectService.watchProjects().listen(
        (list) {
          _projects = list;
          _clearError();
          notifyListeners();
        },
        onError: (e) {
          _error = 'Erro ao carregar obras/projetos: $e';
          notifyListeners();
        },
      );
    }
  }

  Future<void> refresh() async {
    await _employeeSub?.cancel();
    await _teamSub?.cancel();
    await _projectSub?.cancel();
    _employeeSub = null;
    _teamSub = null;
    _projectSub = null;
    _initialized = false;
    init();
  }

  @override
  void dispose() {
    _employeeSub?.cancel();
    _teamSub?.cancel();
    _projectSub?.cancel();
    super.dispose();
  }

  List<EmployeeModel> getMembersOfTeam(TeamModel team) {
    return _employees.where((e) => team.memberIds.contains(e.id)).toList();
  }

  List<EmployeeModel> getAvailableEmployees(TeamModel team) {
    return _employees.where((e) => !team.memberIds.contains(e.id)).toList();
  }

  Project? getProjectById(String? projectId) {
    if (projectId == null || projectId.trim().isEmpty) return null;
    for (final project in _projects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  Future<String> saveEmployee(EmployeeModel employee) async {
    _setLoading(true);
    try {
      final id = await _service.saveEmployee(employee);
      _clearError();
      return id;
    } catch (e) {
      _error = 'Erro ao salvar funcionario: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEmployee(String id) async {
    _setLoading(true);
    try {
      await _service.deleteEmployee(id);
      _clearError();
    } catch (e) {
      _error = 'Erro ao excluir funcionario: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> dismissEmployee(String id) async {
    _setLoading(true);
    try {
      await _service.dismissEmployee(id);
      _clearError();
    } catch (e) {
      _error = 'Erro ao registrar desligamento: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<TeamModel?> createTeam({
    required String name,
    String description = '',
    List<String> memberIds = const [],
    String? leaderId,
    String? projectId,
  }) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final team = TeamModel(
        id: '',
        name: name,
        description: description,
        memberIds: memberIds,
        leaderId: leaderId,
        projectId: projectId,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _service.createTeam(team);
      _clearError();
      return team.copyWith(id: id);
    } catch (e) {
      _error = 'Erro ao criar equipe: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTeam(TeamModel team) async {
    _setLoading(true);
    try {
      await _service.updateTeam(team.copyWith(updatedAt: DateTime.now()));
      _clearError();
    } catch (e) {
      _error = 'Erro ao atualizar equipe: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    _setLoading(true);
    try {
      await _service.deleteTeam(teamId);
      _clearError();
    } catch (e) {
      _error = 'Erro ao excluir equipe: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMember(String teamId, String employeeId) async {
    try {
      await _service.addMemberToTeam(teamId, employeeId);
      _clearError();
    } catch (e) {
      _error = 'Erro ao adicionar membro: $e';
      notifyListeners();
    }
  }

  Future<void> removeMember(String teamId, String employeeId) async {
    try {
      await _service.removeMemberFromTeam(teamId, employeeId);
      _clearError();
    } catch (e) {
      _error = 'Erro ao remover membro: $e';
      notifyListeners();
    }
  }

  Future<void> setLeader(String teamId, String? employeeId) async {
    try {
      await _service.setTeamLeader(teamId, employeeId);
      _clearError();
    } catch (e) {
      _error = 'Erro ao definir lider: $e';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
