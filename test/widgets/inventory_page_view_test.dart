import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/widgets/inventory/inventory_page_page_widgets.dart';

import '../helpers/fake_inventory_service.dart';

void main() {
  InventoryItem item({
    required String id,
    required String name,
    required double quantity,
    required double minQuantity,
    DateTime? lastEntryDate,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      unit: 'un',
      quantity: quantity,
      minQuantity: minQuantity,
      updatedAt: DateTime(2026, 5, 10, 8),
      lastEntryDate: lastEntryDate,
    );
  }

  testWidgets('InventoryPageView mostra resumo, busca e alertas derivados', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StreamController<List<InventoryItem>>.broadcast();

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryPageView(
          service: FakeInventoryService(),
          inventoryStream: controller.stream,
        ),
      ),
    );

    controller.add([
      item(id: '1', name: 'Cimento', quantity: 0, minQuantity: 5),
      item(id: '2', name: 'Areia', quantity: 2, minQuantity: 5),
      item(
        id: '3',
        name: 'Brita',
        quantity: 30,
        minQuantity: 10,
        lastEntryDate: DateTime(2026, 5, 9),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Controle de Estoque'), findsOneWidget);
    expect(find.text('3 itens'), findsOneWidget);
    expect(find.text('1 critico'), findsOneWidget);
    expect(find.text('1 zerado'), findsOneWidget);
    expect(find.text('Cimento'), findsOneWidget);
    expect(find.text('Areia'), findsOneWidget);
    expect(find.text('Brita'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'brita');
    await tester.pumpAndSettle();

    expect(find.text('Brita'), findsOneWidget);
    expect(find.text('Cimento'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alertas (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Cimento'), findsOneWidget);
    expect(find.text('Areia'), findsOneWidget);
    expect(find.text('Brita'), findsNothing);

    await controller.close();
  });
}
