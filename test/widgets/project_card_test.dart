import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/widgets/projects/project_card.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 840, height: 320, child: child)),
  );
}

void main() {
  group('ProjectCard', () {
    testWidgets('renderiza progresso medido e delega abrir/editar', (
      tester,
    ) async {
      var opened = false;
      var edited = false;

      final project = Project(
        id: '',
        name: 'Obra Horizonte',
        client: 'Cliente Azul',
        description: 'Estrutura principal',
        status: ProjectStatus.inProgress,
        startDate: DateTime(2026, 5, 1),
        budget: 0,
        currentCost: 0,
        location: 'Campinas',
        tags: const ['estrutura'],
        teamSize: 8,
        estimatedProgress: 62.5,
        measuredAmount: 62500,
        measurementCount: 3,
      );

      await tester.pumpWidget(
        _buildHarness(
          ProjectCard(
            project: project,
            onTap: () => opened = true,
            onEdit: () => edited = true,
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Obra Horizonte'), findsOneWidget);
      expect(find.text('Cliente Azul'), findsOneWidget);
      expect(find.text('Avanco medido'), findsOneWidget);
      expect(find.text('62.5%'), findsOneWidget);

      await tester.tap(find.text('Obra Horizonte'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);
    });

    testWidgets('lista mostra alertas de atraso e estouro quando presentes', (
      tester,
    ) async {
      final project = Project(
        id: '',
        name: 'Obra Sul',
        client: 'Cliente Leste',
        description: 'Acabamento',
        status: ProjectStatus.inProgress,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 2, 1),
        budget: 1000,
        currentCost: 1500,
        location: 'Sao Paulo',
        tags: const [],
        teamSize: 3,
      );

      await tester.pumpWidget(
        _buildHarness(
          ProjectCard(
            project: project,
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
            isListView: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estourado'), findsOneWidget);
      expect(find.text('Atrasado'), findsOneWidget);
    });
  });
}
