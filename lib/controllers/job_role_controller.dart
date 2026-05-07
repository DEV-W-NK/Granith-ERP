import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/services/job_role_service.dart';

class JobRoleController extends ChangeNotifier {
  final JobRoleService _service;

  JobRoleController({JobRoleService? service})
    : _service = service ?? JobRoleService();

  final List<JobRoleModel> _roles = [];
  StreamSubscription<List<JobRoleModel>>? _rolesSub;
  bool _initialized = false;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<JobRoleModel> get roles => List.unmodifiable(_roles);

  void init() {
    if (_initialized) return;
    _initialized = true;

    _rolesSub = _service.getJobRoles().listen(
      (roles) {
        _roles
          ..clear()
          ..addAll(roles);
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Erro ao carregar cargos: $error';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _rolesSub?.cancel();
    super.dispose();
  }

  Future<void> addRole(JobRoleModel role) async {
    _setLoading(true);
    try {
      await _service.saveJobRole(role);
      _error = null;
    } catch (error) {
      _error = 'Erro ao adicionar cargo: $error';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRole(JobRoleModel updated) async {
    _setLoading(true);
    try {
      await _service.saveJobRole(updated);
      _error = null;
    } catch (error) {
      _error = 'Erro ao atualizar cargo: $error';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleActive(String id) async {
    final index = _roles.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    final role = _roles[index];
    await updateRole(role.copyWith(isActive: !role.isActive));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
