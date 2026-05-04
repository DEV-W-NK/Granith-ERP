import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/widgets/project_measurements/project_measurement_form_dialog.dart';

class _MeasurementDialogHarness extends StatelessWidget {
  const _MeasurementDialogHarness({
    required this.projects,
    required this.onResult,
  });

  final List<Project> projects;
  final ValueChanged<ProjectMeasurement?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder:
              (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await showDialog<ProjectMeasurement>(
                      context: context,
                      builder:
                          (_) =>
                              ProjectMeasurementFormDialog(projects: projects),
                    );
                    onResult(result);
                  },
                  child: const Text('abrir'),
                ),
              ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('retorna medicao preenchida ao registrar formulario valido', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    ProjectMeasurement? captured;
    final projects = [
      Project(
        id: 'p-1',
        name: 'Obra Ponte',
        client: 'Cliente Delta',
        description: '',
        status: ProjectStatus.inProgress,
        startDate: DateTime(2026, 1, 1),
        budget: 80000,
        currentCost: 10000,
        location: 'SP',
        tags: const [],
        teamSize: 5,
      ),
    ];

    await tester.pumpWidget(
      _MeasurementDialogHarness(
        projects: projects,
        onResult: (result) => captured = result,
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '1a medicao');
    await tester.enterText(find.byType(TextFormField).at(1), '15000');
    await tester.enterText(find.byType(TextFormField).at(2), '1200');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Concretagem da etapa 1',
    );
    await tester.ensureVisible(find.text('Registrar'));
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.projectId, 'p-1');
    expect(captured!.grossAmount, 15000);
    expect(captured!.discountAmount, 1200);
    expect(captured!.status, ProjectMeasurementStatus.pending);
    expect(captured!.notes, 'Concretagem da etapa 1');
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('valida projeto e valor bruto obrigatorios', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    ProjectMeasurement? captured;
    final projects = [
      Project(
        id: 'p-1',
        name: 'Obra Alfa',
        client: 'Cliente Alfa',
        description: '',
        status: ProjectStatus.planning,
        startDate: DateTime(2026, 1, 1),
        budget: 50000,
        currentCost: 0,
        location: 'SP',
        tags: const [],
        teamSize: 2,
      ),
      Project(
        id: 'p-2',
        name: 'Obra Beta',
        client: 'Cliente Beta',
        description: '',
        status: ProjectStatus.planning,
        startDate: DateTime(2026, 1, 1),
        budget: 50000,
        currentCost: 0,
        location: 'SP',
        tags: const [],
        teamSize: 2,
      ),
    ];

    await tester.pumpWidget(
      _MeasurementDialogHarness(
        projects: projects,
        onResult: (result) => captured = result,
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Registrar'));
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione um projeto.'), findsOneWidget);
    expect(find.text('Informe um valor bruto maior que zero.'), findsOneWidget);
    expect(captured, isNull);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
