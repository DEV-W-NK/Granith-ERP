import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/item_model.dart';

void main() {
  group('Item', () {
    test('fromMap e toMap preservam metadados de frete', () {
      final now = DateTime(2026, 5, 3, 14, 30);
      final item = Item.fromMap({
        'name': 'Cimento',
        'description': 'Saco estrutural',
        'unit': 'sc',
        'weight': 50,
        'width': 30,
        'height': 12,
        'length': 55,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, 'item-1');

      expect(item.name, 'Cimento');
      expect(item.weight, 50);
      expect(item.length, 55);

      final map = item.toMap();
      expect(map['unit'], 'sc');
      expect(map['description'], 'Saco estrutural');
      expect(map['weight'], 50);
    });

    test('copyWith substitui apenas os campos informados', () {
      final item = Item(
        id: 'item-1',
        name: 'Brita',
        description: 'Original',
        unit: 'm3',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = item.copyWith(
        description: 'Atualizado',
        width: 10,
        updatedAt: DateTime(2026, 2, 1),
      );

      expect(updated.name, 'Brita');
      expect(updated.description, 'Atualizado');
      expect(updated.width, 10);
      expect(updated.unit, 'm3');
    });
  });
}
