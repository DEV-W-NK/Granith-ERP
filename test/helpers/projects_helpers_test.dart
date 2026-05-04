import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/helpers/projects_helpers.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:provider/provider.dart';

import 'fake_project_service.dart';

void main() {
  Project sampleProject() {
    return Project(
      id: 'p1',
      name: 'Residencial Aurora',
      client: 'Cliente X',
      description: 'Projeto teste',
      status: ProjectStatus.inProgress,
      startDate: DateTime(2026, 5, 1),
      budget: 100000,
      currentCost: 15000,
      location: 'Sao Paulo',
      tags: const ['obra'],
      teamSize: 5,
    );
  }

  testWidgets('showDeleteDialog exclui projeto e mostra feedback', (
    tester,
  ) async {
    final service = FakeProjectService(initialProjects: [sampleProject()]);
    final controller = ProjectsController(
      service,
      deleteDebounceDelay: const Duration(milliseconds: 1),
      saveDebounceDelay: const Duration(milliseconds: 1),
      updateDebounceDelay: const Duration(milliseconds: 1),
      searchDebounceDelay: const Duration(milliseconds: 1),
    );

    late BuildContext pageContext;

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectsController>.value(
        value: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      ),
    );

    showDeleteDialog(pageContext, sampleProject());
    await tester.pumpAndSettle();

    expect(find.text('Excluir Projeto'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(service.deletedProjectId, 'p1');
    expect(find.textContaining('exclu'), findsOneWidget);
  });
}
