import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/widgets/items/item_form_dialog.dart';

void main() {
  Widget wrapDialog(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ItemFormDialog', () {
    testWidgets('valida nome e unidade obrigatorios', (tester) async {
      await tester.pumpWidget(wrapDialog(const ItemFormDialog()));

      await tester.tap(find.text('Criar Item'));
      await tester.pumpAndSettle();

      expect(find.text('Obrigatório'), findsOneWidget);
    });

    testWidgets('retorna item preenchido ao submeter formulario valido', (
      tester,
    ) async {
      await tester.pumpWidget(wrapDialog(const ItemFormDialog()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Cimento');
      await tester.enterText(find.byType(TextFormField).at(1), 'sc');
      await tester.enterText(find.byType(TextFormField).at(2), 'Saco estrutural');
      await tester.enterText(find.byType(TextFormField).at(3), '50');
      await tester.enterText(find.byType(TextFormField).at(4), '30');
      await tester.enterText(find.byType(TextFormField).at(5), '12');
      await tester.enterText(find.byType(TextFormField).at(6), '55');

      await tester.tap(find.text('Criar Item'));
      await tester.pumpAndSettle();

      final route = tester.state<NavigatorState>(find.byType(Navigator));
      expect(route.canPop(), isFalse);
    });

    testWidgets('preenche valores de edicao existentes', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Brita',
        description: 'Original',
        unit: 'm3',
        weight: 10,
        width: 20,
        height: 30,
        length: 40,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(wrapDialog(ItemFormDialog(item: item)));

      expect(find.text('Editar Item'), findsOneWidget);
      expect(find.text('Brita'), findsOneWidget);
      expect(find.text('m3'), findsOneWidget);
      expect(find.text('10.0'), findsOneWidget);
    });
  });
}
