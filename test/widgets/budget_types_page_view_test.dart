import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/budget_type_controller.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/widgets/budget_type/budget_types_page_view.dart';

import '../helpers/fake_budget_type_service.dart';

void main() {
  BudgetType type({
    required String id,
    required String name,
    required String category,
    bool isActive = true,
  }) {
    return BudgetType(
      id: id,
      name: name,
      description: 'Tipo comercial para composição de orçamento',
      category: category,
      isActive: isActive,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
  }

  testWidgets('BudgetTypesPageView lista tipos comerciais cadastráveis', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = BudgetTypeController(
      FakeBudgetTypeService(
        activeTypes: [
          type(id: 'type-1', name: 'Mão de Obra', category: 'Mão de Obra'),
          type(id: 'type-2', name: 'Engenharia', category: 'Engenharia'),
          type(id: 'type-3', name: 'Combustível', category: 'Combustível'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: BudgetTypesPageView(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tipos de Orçamento'), findsOneWidget);
    expect(find.text('Mão de Obra'), findsWidgets);
    expect(find.text('Engenharia'), findsWidgets);
    expect(find.text('Combustível'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Combustível');
    await tester.pumpAndSettle();

    expect(find.text('Combustível'), findsWidgets);
    expect(find.text('Engenharia'), findsOneWidget);
  });
}
