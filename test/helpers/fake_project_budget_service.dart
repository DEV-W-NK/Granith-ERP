import 'dart:async';

import 'package:project_granith/services/ProjectBudgetService.dart';

class FakeProjectBudgetService extends ProjectBudgetService {
  FakeProjectBudgetService({ProjectBudgetSnapshot? initialSnapshot})
    : _snapshot =
          initialSnapshot ?? ProjectBudgetSnapshot.empty('project-1', 0),
      super();

  final StreamController<ProjectBudgetSnapshot> _controller =
      StreamController<ProjectBudgetSnapshot>.broadcast();
  ProjectBudgetSnapshot _snapshot;
  String? lastSyncedProjectId;
  Object? syncError;

  void emit(ProjectBudgetSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  @override
  Stream<ProjectBudgetSnapshot> watchProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) {
    return _controller.stream;
  }

  @override
  Future<ProjectBudgetSnapshot> getProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) async {
    return _snapshot;
  }

  @override
  Future<void> syncProjectCurrentCost(String projectId) async {
    lastSyncedProjectId = projectId;
    if (syncError != null) {
      throw syncError!;
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
