import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/widgets/projects/ProjectBudgetSummary.dart';

import '../helpers/fake_project_budget_service.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 960, height: 420, child: child)),
  );
}

Project _project() {
  return Project(
    id: 'project-1',
    name: 'Residencial Horizonte',
    client: 'Cliente Horizonte',
    description: 'Obra principal',
    status: ProjectStatus.inProgress,
    startDate: DateTime(2026, 5, 1),
    budget: 1000,
    currentCost: 400,
    location: 'Sao Paulo',
    tags: const ['obra'],
    teamSize: 6,
  );
}

ProjectBudgetSnapshot _snapshot() {
  return const ProjectBudgetSnapshot(
    projectId: 'project-1',
    budgetPrevisto: 1000,
    totalDespesas: 1200,
    totalReceitas: 1800,
    despesasPendentes: 150,
    receitasPendentes: 200,
    despesasPorCategoria: {
      TransactionCategory.material: 700,
      TransactionCategory.labor: 500,
    },
    despesasPorOrigem: {
      TransactionOrigin.purchase: 900,
      TransactionOrigin.manual: 300,
    },
  );
}

void main() {
  group('ProjectBudgetSummary', () {
    testWidgets('renderiza visao compacta com alerta de estouro', (
      tester,
    ) async {
      final service = FakeProjectBudgetService();

      await tester.pumpWidget(
        _buildHarness(
          ProjectBudgetSummary(
            project: _project(),
            compact: true,
            budgetService: service,
          ),
        ),
      );

      service.emit(_snapshot());
      await tester.pumpAndSettle();

      expect(find.textContaining('120.0%'), findsOneWidget);
      expect(find.textContaining('R\$'), findsWidgets);
      expect(find.textContaining('estourado'), findsOneWidget);

      await service.dispose();
    });

    testWidgets('renderiza visao completa com breakdown', (tester) async {
      final service = FakeProjectBudgetService();

      await tester.pumpWidget(
        _buildHarness(
          ProjectBudgetSummary(
            project: _project(),
            showBreakdown: true,
            budgetService: service,
          ),
        ),
      );

      service.emit(_snapshot());
      await tester.pumpAndSettle();

      expect(find.text('Budget vs Realizado'), findsOneWidget);
      expect(find.text('Estourado'), findsOneWidget);
      expect(find.text('Despesas por categoria'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('M. de obra'), findsOneWidget);
      expect(find.textContaining('pendentes'), findsOneWidget);

      await service.dispose();
    });
  });
}
