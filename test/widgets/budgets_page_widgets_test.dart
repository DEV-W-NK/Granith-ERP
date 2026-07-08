import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/BudgetsViewModel.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/widgets/budget_types/budget_types_page_widgets.dart';

import '../helpers/fake_service_orcamentos.dart';

void main() {
  Budget budget({
    required String id,
    required String clientName,
    required String projectName,
    required BudgetStatus status,
    double totalValue = 1000,
  }) {
    return Budget(
      id: id,
      clientName: clientName,
      projectName: projectName,
      totalValue: totalValue,
      creationDate: DateTime(2026, 5, 1),
      expirationDate: DateTime.now().add(const Duration(days: 5)),
      status: status,
    );
  }

  testWidgets('BudgetsPageView renderiza lista, filtros e atualizacao manual', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = FakeServiceOrcamentos();
    final viewModel = BudgetsViewModel(service, bootstrapOnInit: false);

    await tester.pumpWidget(
      MaterialApp(home: BudgetsPageView(viewModel: viewModel)),
    );

    viewModel.listenToBudgets();
    service.emitBudgets([
      budget(
        id: '1',
        clientName: 'Cliente Atlas',
        projectName: 'Obra Alfa',
        status: BudgetStatus.pending,
        totalValue: 2000,
      ),
      budget(
        id: '2',
        clientName: 'Cliente Beta',
        projectName: 'Obra Beta',
        status: BudgetStatus.approved,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Orcamentos'), findsOneWidget);
    expect(find.text('1 pendente'), findsOneWidget);
    expect(find.text('1 aprovado'), findsOneWidget);
    expect(find.text('Cliente Atlas'), findsOneWidget);
    expect(find.text('Cliente Beta'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Aprovados'));
    await tester.pumpAndSettle();
    expect(find.text('Cliente Beta'), findsOneWidget);
    expect(find.text('Cliente Atlas'), findsNothing);

    await tester.tap(find.text('Verificar expirados'));
    await tester.pumpAndSettle();
    expect(service.forceUpdateCalled, isTrue);

    await service.dispose();
  });
}
