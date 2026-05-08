import 'dart:async';

import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/service_projetos.dart';

class FakeProjectService extends ServiceProjetos {
  FakeProjectService({List<Project>? initialProjects})
    : _projects = List<Project>.from(initialProjects ?? const <Project>[]);

  final List<Project> _projects;
  final StreamController<List<Project>> _projectStreamController =
      StreamController<List<Project>>.broadcast();
  Object? getProjectsError;
  Object? getProjectsByClientAccountError;
  Object? addProjectError;
  Object? updateProjectError;
  Object? deleteProjectError;
  String createdId = 'project-created';
  String? deletedProjectId;
  Project? lastAddedProject;
  Project? lastUpdatedProject;

  List<Project> _visibleProjects(String? clientAccountId) {
    if (clientAccountId == null || clientAccountId.trim().isEmpty) {
      return List<Project>.from(_projects);
    }

    return _projects
        .where((project) => project.clientAccountId == clientAccountId)
        .toList();
  }

  void _emitProjects() {
    if (!_projectStreamController.isClosed) {
      _projectStreamController.add(List<Project>.from(_projects));
    }
  }

  void emitProjects(List<Project> projects) {
    _projects
      ..clear()
      ..addAll(projects);
    _emitProjects();
  }

  Future<void> dispose() async {
    await _projectStreamController.close();
  }

  @override
  Future<List<Project>> getProjects({String? clientAccountId}) async {
    if (getProjectsError != null) {
      throw getProjectsError!;
    }

    return _visibleProjects(clientAccountId);
  }

  @override
  Stream<List<Project>> watchProjects({String? clientAccountId}) async* {
    yield _visibleProjects(clientAccountId);
    yield* _projectStreamController.stream.map(
      (_) => _visibleProjects(clientAccountId),
    );
  }

  @override
  Future<List<Project>> getProjectsByClientAccount(
    String clientAccountId,
  ) async {
    if (getProjectsByClientAccountError != null) {
      throw getProjectsByClientAccountError!;
    }

    return _projects
        .where((project) => project.clientAccountId == clientAccountId)
        .toList();
  }

  @override
  Future<String> addProject(Project project) async {
    if (addProjectError != null) {
      throw addProjectError!;
    }

    lastAddedProject = project;
    final created = project.copyWith(id: createdId);
    _projects.add(created);
    _emitProjects();
    return createdId;
  }

  @override
  Future<void> updateProject(Project project) async {
    if (updateProjectError != null) {
      throw updateProjectError!;
    }

    lastUpdatedProject = project;
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      _emitProjects();
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    if (deleteProjectError != null) {
      throw deleteProjectError!;
    }

    deletedProjectId = projectId;
    _projects.removeWhere((project) => project.id == projectId);
    _emitProjects();
  }

  @override
  Future<bool> projectExists({
    required String name,
    required String client,
    String? excludeId,
  }) async {
    return _projects.any(
      (project) =>
          project.name == name &&
          project.client == client &&
          (excludeId == null || project.id != excludeId),
    );
  }
}
