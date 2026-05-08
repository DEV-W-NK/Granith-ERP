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
    double? weight,
    double? width,
    double? height,
    double? length,
  }) {
    return Item(
      id: id,
      name: name,
      description: description,
      unit: 'un',
      weight: weight,
      width: width,
      height: height,
      length: length,
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
      item(
        id: '1',
        name: 'Cimento',
        description: 'Saco estrutural',
        weight: 50,
      ),
      item(id: '2', name: 'Areia', description: 'Fina'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Catalogo de Itens'), findsOneWidget);
    expect(find.text('Cimento'), findsOneWidget);
    expect(find.text('Areia'), findsOneWidget);
    expect(find.text('2 itens'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'arei');
    await tester.pumpAndSettle();

    expect(find.text('Areia'), findsOneWidget);
    expect(find.text('Cimento'), findsNothing);
    expect(find.text('1 de 2 itens'), findsOneWidget);

    await tester.tap(find.text('Novo item'));
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

  for (final size in const [Size(390, 900), Size(768, 1024), Size(1280, 900)]) {
    testWidgets('ItemsPageView renderiza sem overflow em ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = StreamController<List<Item>>.broadcast();
      await tester.pumpWidget(
        MaterialApp(
          home: ItemsPageView(
            viewModel: ItemsViewModel(FakeItemService()),
            itemsStream: controller.stream,
          ),
        ),
      );

      controller.add([
        item(
          id: '1',
          name: 'Cimento CPII 50kg para estrutura de concreto',
          description:
              'Insumo usado em concretagem, reboco e assentamento com controle de estoque.',
          weight: 50,
          width: 40,
          height: 12,
          length: 65,
        ),
        item(
          id: '2',
          name: 'Vergalhao CA-50 10mm',
          description: 'Barra de aco para armacao de pilares e vigas.',
          weight: 7.4,
          length: 1200,
        ),
        item(
          id: '3',
          name: 'Areia media lavada',
          description: 'Material granular para argamassa e concreto.',
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Catalogo de Itens'), findsOneWidget);
      expect(find.textContaining('Cimento CPII'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await controller.close();
    });
  }
}
