import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/ViewModels/ItemsViewModel.dart';
import 'package:project_granith/models/item_model.dart';

import '../helpers/fake_item_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ItemsViewModel', () {
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

    test('updateSearch e filterItems aplicam busca por nome e descricao', () {
      final viewModel = ItemsViewModel(FakeItemService());
      viewModel.updateSearch('galv');

      final filtered = viewModel.filterItems([
        item(id: '1', name: 'Cimento', description: 'Saco estrutural'),
        item(id: '2', name: 'Parafuso', description: 'Aco galvanizado'),
      ]);

      expect(viewModel.searchQuery, 'galv');
      expect(filtered.single.id, '2');
    });

    testWidgets('saveItem e deleteItem delegam para o service', (
      tester,
    ) async {
      final service = FakeItemService();
      final viewModel = ItemsViewModel(service);
      final created = item(id: '', name: 'Brita');
      final updated = item(id: 'item-9', name: 'Areia');

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          home: const SizedBox.shrink(),
        ),
      );

      await viewModel.saveItem(created);
      await viewModel.saveItem(updated, isUpdate: true);
      await viewModel.deleteItem('item-9');

      expect(service.lastAddedItem?.name, 'Brita');
      expect(service.lastUpdatedItem?.id, 'item-9');
      expect(service.lastDeletedId, 'item-9');
    });
  });
}
