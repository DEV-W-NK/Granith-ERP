import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/inventory_model.dart';

void main() {
  group('InventoryItem', () {
    test('computed properties refletem saude do estoque', () {
      final item = InventoryItem(
        id: 'item-1',
        name: 'Cimento',
        unit: 'sc',
        quantity: 4,
        minQuantity: 5,
        updatedAt: DateTime(2026, 5, 3),
      );

      expect(item.isLowStock, isTrue);
      expect(item.isOutOfStock, isFalse);
      expect(item.stockHealthPercent, 80);
    });

    test('toMap normaliza nome e preserva purchase vinculada', () {
      final item = InventoryItem(
        id: 'item-1',
        name: 'Brita 1',
        unit: 'm3',
        quantity: 12,
        minQuantity: 3,
        updatedAt: DateTime(2026, 5, 3),
        lastPurchaseId: 'purchase-9',
      );

      final map = item.toMap();

      expect(map['name'], 'Brita 1');
      expect(map['name_normalized'], 'brita 1');
      expect(map['lastPurchaseId'], 'purchase-9');
    });
  });
}
