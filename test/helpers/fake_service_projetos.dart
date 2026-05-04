import 'dart:io';
import 'dart:typed_data';

import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/service_projetos.dart';

class FakeServiceProjetos extends ServiceProjetos {
  FakeServiceProjetos({List<Project>? projects})
    : _projects = List<Project>.from(projects ?? const <Project>[]);

  final List<Project> _projects;
  Project? lastAddedProject;
  Project? lastUpdatedProject;
  String? uploadImageUrl;
  Object? uploadError;

  @override
  Future<List<Project>> getProjects({String? clientAccountId}) async {
    if (clientAccountId == null || clientAccountId.trim().isEmpty) {
      return List<Project>.from(_projects);
    }

    return _projects
        .where((project) => project.clientAccountId == clientAccountId)
        .toList();
  }

  @override
  Future<String> addProject(Project project) async {
    lastAddedProject = project;
    _projects.add(project);
    return project.id.isEmpty ? 'generated-project-id' : project.id;
  }

  @override
  Future<void> updateProject(Project project) async {
    lastUpdatedProject = project;
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    }
  }

  @override
  Future<String?> uploadProjectImage({
    File? file,
    Uint8List? webData,
    required String projectId,
    bool replaceExisting = true,
  }) async {
    if (uploadError != null) {
      throw uploadError!;
    }
    return uploadImageUrl;
  }
}
