import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/services/team_service.dart';

class TeamController extends ChangeNotifier {
  final TeamService _service;

  TeamController({TeamService? service})
      : _service = service ?? TeamService();

  // ─── Estado ─────────────────────────────────────────────────────────────────
  List<EmployeeModel> _employees = [];
  List<TeamModel> _teams = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<EmployeeModel>>? _employeeSub;
  StreamSubscription<List<TeamModel>>? _teamSub;

  List<EmployeeModel> get employees => _employees;
  List<TeamModel> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Inicialização ──────────────────────────────────────────────────────────

  /// Chame no initState da página para iniciar as streams.
  void init() {
    _employeeSub = _service.getEmployees().listen(
      (list) {
        _employees = list;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar funcionários: $e';
        notifyListeners();
      },
    );

    _teamSub = _service.getTeams().listen(
      (list) {
        _teams = list;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar equipes: $e';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _employeeSub?.cancel();
    _teamSub?.cancel();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Retorna os EmployeeModel de uma equipe específica.
  List<EmployeeModel> getMembersOfTeam(TeamModel team) {
    return _employees.where((e) => team.memberIds.contains(e.id)).toList();
  }

  /// Retorna funcionários que NÃO pertencem a uma equipe específica.
  List<EmployeeModel> getAvailableEmployees(TeamModel team) {
    return _employees.where((e) => !team.memberIds.contains(e.id)).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EMPLOYEES
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> saveEmployee(EmployeeModel employee) async {
    _setLoading(true);
    try {
      await _service.saveEmployee(employee);
      _clearError();
    } catch (e) {
      _error = 'Erro ao salvar funcionário: $e';
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
      _error = 'Erro ao excluir funcionário: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Registra desligamento: altera status para [desligado] sem excluir do banco.
  /// Remove o funcionário de todas as equipes automaticamente (via service).
  Future<void> dismissEmployee(String id) async {
    _setLoading(true);
    try {
      await _service.dismissEmployee(id);
      _clearError();
    } catch (e) {
      _error = 'Erro ao registrar desligamento: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TEAMS
  // ════════════════════════════════════════════════════════════════════════════

  Future<TeamModel?> createTeam({
    required String name,
    String description = '',
    String? projectId,
  }) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final team = TeamModel(
        id: '',
        name: name,
        description: description,
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
      _error = 'Erro ao definir líder: $e';
      notifyListeners();
    }
  }

  // ─── Privados ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}