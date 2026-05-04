import 'package:flutter/material.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/services/job_role_service.dart';

class JobRoleController extends ChangeNotifier {
  final JobRoleService _service = JobRoleService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Lista local usada como estado inicial para visualizacao imediata.
  final List<JobRoleModel> _roles = [
    JobRoleModel(
      id: '1',
      title: 'Engenheiro Civil Júnior',
      sector: 'Engenharia',
      description:
          'Responsável pelo acompanhamento técnico de obras residenciais.',
      hourlyRate: 28.50,
      requirements: ['CREA Ativo', 'Experiência em Obras'],
      createdAt: DateTime.now(),
    ),
    JobRoleModel(
      id: '2',
      title: 'Mestre de Obras',
      sector: 'Obras',
      description: 'Liderança de equipes de campo e gestão de materiais.',
      hourlyRate: 35.00,
      requirements: ['Experiência comprovada'],
      createdAt: DateTime.now(),
    ),
    JobRoleModel(
      id: '3',
      title: 'Pedreiro',
      sector: 'Obras',
      description: 'Execução de alvenaria e acabamentos.',
      hourlyRate: 22.00,
      requirements: ['NR-18'],
      createdAt: DateTime.now(),
    ),
    JobRoleModel(
      id: '4',
      title: 'Auxiliar Administrativo',
      sector: 'Administrativo',
      description: 'Suporte às rotinas administrativas do escritório.',
      hourlyRate: 15.00,
      requirements: ['Ensino médio completo'],
      createdAt: DateTime.now(),
    ),
  ];

  List<JobRoleModel> get roles => List.unmodifiable(_roles);

  Future<void> addRole(JobRoleModel role) async {
    _setLoading(true);
    try {
      // Quando persistir: final id = await _service.addRole(role);
      await Future.delayed(const Duration(milliseconds: 300));
      _roles.add(role);
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar cargo: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRole(JobRoleModel updated) async {
    _setLoading(true);
    try {
      // Quando persistir: await _service.updateRole(updated);
      await Future.delayed(const Duration(milliseconds: 300));
      final idx = _roles.indexWhere((r) => r.id == updated.id);
      if (idx != -1) _roles[idx] = updated;
      _error = null;
    } catch (e) {
      _error = 'Erro ao atualizar cargo: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleActive(String id) async {
    final idx = _roles.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final role = _roles[idx];
    await updateRole(role.copyWith(isActive: !role.isActive));
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
