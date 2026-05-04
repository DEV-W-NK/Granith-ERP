import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/widgets/projects/projects_page_widgets.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_project_budget_service.dart';
import '../helpers/fake_service_projetos.dart';

void main() {
  group('ProjectsPageView', () {
    Project project({
      required String id,
      required String name,
      required String client,
      required ProjectStatus status,
    }) {
      return Project(
        id: id,
        name: name,
        client: client,
        startDate: DateTime(2026, 5, 1),
        budget: 100000,
        currentCost: 35000,
        teamSize: 12,
        status: status,
        location: 'Sao Paulo',
        description: 'Projeto $name',
        tags: const ['obra'],
      );
    }

    Future<void> pumpPage(
      WidgetTester tester, {
      required ProjectsController controller,
      Size size = const Size(1400, 900),
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider<ProjectsController>.value(
          value: controller,
          child: MaterialApp(
            home: ProjectsPageView(budgetService: FakeProjectBudgetService()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets(
      'renderiza projetos carregados, alterna visualizacao e abre exportacao',
      (tester) async {
        final controller = ProjectsController(
          FakeServiceProjetos(
            projects: [
              project(
                id: 'p-1',
                name: 'Torre Norte',
                client: 'Acme',
                status: ProjectStatus.inProgress,
              ),
              project(
                id: 'p-2',
                name: 'Retrofit Sul',
                client: 'Beta',
                status: ProjectStatus.planning,
              ),
            ],
          ),
          searchDebounceDelay: Duration.zero,
        );
        await controller.loadProjects();
        controller.setViewMode(false);

        await pumpPage(tester, controller: controller);

        expect(find.text('Projetos'), findsOneWidget);
        expect(find.text('2 projetos'), findsOneWidget);
        expect(find.text('Torre Norte'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.download_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Exportar Projetos'), findsWidgets);
        expect(find.textContaining('CSV'), findsOneWidget);
      },
    );

    testWidgets('mostra estado vazio filtrado e permite limpar filtros', (
      tester,
    ) async {
      final controller = ProjectsController(
        FakeServiceProjetos(
          projects: [
            project(
              id: 'p-1',
              name: 'Torre Norte',
              client: 'Acme',
              status: ProjectStatus.inProgress,
            ),
          ],
        ),
        searchDebounceDelay: Duration.zero,
      );
      await controller.loadProjects();
      controller.setViewMode(false);
      controller.updateSearchQuery('inexistente');

      await pumpPage(tester, controller: controller);
      await tester.pump();

      expect(find.textContaining('Nenhum projeto encontrado'), findsOneWidget);
      expect(find.text('Limpar Filtros'), findsOneWidget);

      await tester.tap(find.text('Limpar Filtros'));
      await tester.pump();

      expect(controller.searchQuery, isEmpty);
      expect(find.text('Torre Norte'), findsOneWidget);
    });
  });
}
