import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/InventoryViewModel.dart';
import 'package:project_granith/models/inventory_model.dart';
import '../helpers/fake_inventory_service.dart';

void main() {
  group('InventoryViewModel', () {
    test('filterItems aplica busca por nome', () {
      final viewModel = InventoryViewModel(FakeInventoryService());
      final items = [
        InventoryItem(
          id: '1',
          name: 'Cimento',
          unit: 'sc',
          quantity: 10,
          updatedAt: DateTime(2026, 5, 3),
        ),
        InventoryItem(
          id: '2',
          name: 'Brita',
          unit: 'm3',
          quantity: 5,
          updatedAt: DateTime(2026, 5, 3),
        ),
      ];

      viewModel.updateSearch('ci');

      final filtered = viewModel.filterItems(items);

      expect(filtered, hasLength(1));
      expect(filtered.first.name, 'Cimento');
    });

    test('registerOutput delega payload para o service', () async {
      final service = FakeInventoryService();
      final viewModel = InventoryViewModel(service);

      await viewModel.registerOutput(
        itemId: 'item-1',
        itemName: 'Areia',
        quantity: 3,
        notes: 'Uso na fundacao',
      );

      expect(service.lastOutboundPayload?['itemId'], 'item-1');
      expect(service.lastOutboundPayload?['itemName'], 'Areia');
      expect(service.lastOutboundPayload?['quantity'], 3.0);
      expect(service.lastOutboundPayload?['userId'], 'manual_user');
      expect(service.lastOutboundPayload?['notes'], 'Uso na fundacao');
    });
  });
}
