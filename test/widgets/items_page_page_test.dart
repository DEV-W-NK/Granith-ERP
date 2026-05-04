import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/item_model.dart';
import 'package:project_granith/viewmodels/itemsviewmodel.dart';
import 'package:project_granith/widgets/items/items_page_page_widgets.dart';

import '../helpers/fake_item_service.dart';

void main() {
  Item item({
    required String id,
    required String name,
    String description = '',
  }) {
    return Item(
      id: id,
      name: name,
      description: description,
      unit: 'un',
      createdAt: DateTime(2026, 5, 3),
      updatedAt: DateTime(2026, 5, 3),
    );
  }

  testWidgets('ItemsPageView renderiza lista, busca e dialogo de novo item', (
    tester,
  ) async {
    final controller = StreamController<List<Item>>.broadcast();
    final viewModel = ItemsViewModel(FakeItemService());

    await tester.pumpWidget(
      MaterialApp(
        home: ItemsPageView(
          viewModel: viewModel,
          itemsStream: controller.stream,
        ),
      ),
    );

    controller.add([
      item(id: '1', name: 'Cimento', description: 'Saco estrutural'),
      item(id: '2', name: 'Areia', description: 'Fina'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Catálogo de Itens'), findsOneWidget);
    expect(find.text('Cimento'), findsOneWidget);
    expect(find.text('Areia'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'arei');
    await tester.pumpAndSettle();

    expect(find.text('Areia'), findsOneWidget);
    expect(find.text('Cimento'), findsNothing);

    await tester.tap(find.text('Novo'));
    await tester.pumpAndSettle();

    expect(find.text('Novo Item'), findsOneWidget);

    await controller.close();
  });

  testWidgets('ItemsPageView mostra estado vazio e erro do stream', (
    tester,
  ) async {
    final emptyController = StreamController<List<Item>>.broadcast();
    await tester.pumpWidget(
      MaterialApp(
        home: ItemsPageView(
          viewModel: ItemsViewModel(FakeItemService()),
          itemsStream: emptyController.stream,
        ),
      ),
    );

    emptyController.add(<Item>[]);
    await tester.pumpAndSettle();
    expect(find.text('Nenhum item cadastrado'), findsOneWidget);

    final errorController = StreamController<List<Item>>.broadcast();
    await tester.pumpWidget(
      MaterialApp(
        home: ItemsPageView(
          viewModel: ItemsViewModel(FakeItemService()),
          itemsStream: errorController.stream,
        ),
      ),
    );

    errorController.addError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Erro ao carregar itens'), findsOneWidget);

    await emptyController.close();
    await errorController.close();
  });
}
