import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/widgets/project_measurements/project_measurements_page_widgets.dart';
import 'package:provider/provider.dart';
import '../helpers/fake_project_measurement_service.dart';
import '../helpers/fake_project_service.dart';

Widget _buildHarness({
  required FakeProjectService projectService,
  required FakeProjectMeasurementService measurementService,
}) {
  return ChangeNotifierProvider(
    create:
        (_) => ProjectsController(
          projectService,
          saveDebounceDelay: Duration.zero,
          updateDebounceDelay: Duration.zero,
          deleteDebounceDelay: Duration.zero,
          searchDebounceDelay: Duration.zero,
        ),
    child: MaterialApp(
      home: ProjectMeasurementsPageView(
        projectService: projectService,
        measurementService: measurementService,
      ),
    ),
  );
}

void main() {
  group('ProjectMeasurementsPageView', () {
    late List<Project> projects;

    setUp(() {
      projects = [
        Project(
          id: 'project-1',
          name: 'Obra Alfa',
          client: 'Cliente Norte',
          description: 'Obra A',
          status: ProjectStatus.inProgress,
          startDate: DateTime(2026, 1, 1),
          budget: 80000,
          currentCost: 12000,
          location: 'SP',
          tags: const [],
          teamSize: 6,
        ),
        Project(
          id: 'project-2',
          name: 'Obra Beta',
          client: 'Cliente Sul',
          description: 'Obra B',
          status: ProjectStatus.inProgress,
          startDate: DateTime(2026, 2, 1),
          budget: 120000,
          currentCost: 40000,
          location: 'RJ',
          tags: const [],
          teamSize: 8,
        ),
      ];
    });

    testWidgets('carrega resumo executivo e cards de medicao', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeProjectService(initialProjects: projects);
      final measurementService = FakeProjectMeasurementService(
        initialMeasurements: [
          ProjectMeasurement(
            id: 'measurement-1',
            projectId: 'project-1',
            projectName: 'Obra Alfa',
            projectClient: 'Cliente Norte',
            title: '1a medicao',
            sequence: 1,
            status: ProjectMeasurementStatus.approved,
            measurementDate: DateTime(2026, 4, 15),
            grossAmount: 20000,
            discountAmount: 1000,
            netAmount: 19000,
            accumulatedGrossAmount: 20000,
            measurementPercentage: 25,
            accumulatedPercentage: 25,
            contractBalance: 60000,
            notes: 'Estrutura finalizada',
          ),
          ProjectMeasurement(
            id: 'measurement-2',
            projectId: 'project-2',
            projectName: 'Obra Beta',
            projectClient: 'Cliente Sul',
            title: '2a medicao',
            sequence: 1,
            status: ProjectMeasurementStatus.paid,
            measurementDate: DateTime(2026, 4, 20),
            grossAmount: 40000,
            discountAmount: 2000,
            netAmount: 38000,
            accumulatedGrossAmount: 40000,
            measurementPercentage: 33.3,
            accumulatedPercentage: 95,
            contractBalance: 80000,
            notes: 'Fachada e cobertura',
          ),
        ],
      );

      await tester.pumpWidget(
        _buildHarness(
          projectService: projectService,
          measurementService: measurementService,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('MEDICOES DE OBRA'), findsOneWidget);
      expect(find.text('1a medicao'), findsOneWidget);
      expect(find.text('2a medicao'), findsOneWidget);
      expect(find.text('Avanco medio'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
      expect(
        find.text(
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(57000),
        ),
        findsOneWidget,
      );
    });

    testWidgets('filtra medicoes pela busca de projeto', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeProjectService(initialProjects: projects);
      final measurementService = FakeProjectMeasurementService(
        initialMeasurements: [
          ProjectMeasurement(
            id: 'measurement-1',
            projectId: 'project-1',
            projectName: 'Obra Alfa',
            projectClient: 'Cliente Norte',
            title: '1a medicao',
            sequence: 1,
            status: ProjectMeasurementStatus.approved,
            measurementDate: DateTime(2026, 4, 15),
            grossAmount: 20000,
            discountAmount: 1000,
            netAmount: 19000,
            accumulatedGrossAmount: 20000,
            measurementPercentage: 25,
            accumulatedPercentage: 25,
            contractBalance: 60000,
            notes: 'Estrutura finalizada',
          ),
          ProjectMeasurement(
            id: 'measurement-2',
            projectId: 'project-2',
            projectName: 'Obra Beta',
            projectClient: 'Cliente Sul',
            title: '2a medicao',
            sequence: 1,
            status: ProjectMeasurementStatus.paid,
            measurementDate: DateTime(2026, 4, 20),
            grossAmount: 40000,
            discountAmount: 2000,
            netAmount: 38000,
            accumulatedGrossAmount: 40000,
            measurementPercentage: 33.3,
            accumulatedPercentage: 95,
            contractBalance: 80000,
            notes: 'Fachada e cobertura',
          ),
        ],
      );

      await tester.pumpWidget(
        _buildHarness(
          projectService: projectService,
          measurementService: measurementService,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pump();

      expect(find.text('1a medicao'), findsNothing);
      expect(find.text('2a medicao'), findsOneWidget);
      expect(find.text('1 medicoes encontradas'), findsOneWidget);

      await tester.tap(find.byTooltip('Limpar busca'));
      await tester.pump();

      expect(find.text('1a medicao'), findsOneWidget);
      expect(find.text('2a medicao'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando nao existem medicoes', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeProjectService(initialProjects: projects);
      final measurementService = FakeProjectMeasurementService();

      await tester.pumpWidget(
        _buildHarness(
          projectService: projectService,
          measurementService: measurementService,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma medicao registrada'), findsOneWidget);
      expect(
        find.textContaining(
          'Cadastre a primeira medicao para transformar valor executado',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mostra falha amigavel quando o carregamento explode', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeProjectService(initialProjects: projects);
      final measurementService =
          FakeProjectMeasurementService()
            ..getMeasurementsError = Exception('Supabase indisponivel');

      await tester.pumpWidget(
        _buildHarness(
          projectService: projectService,
          measurementService: measurementService,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Falha ao consultar medicoes'), findsOneWidget);
      expect(
        find.text('Nao foi possivel carregar as medicoes das obras.'),
        findsOneWidget,
      );
    });
  });
}
