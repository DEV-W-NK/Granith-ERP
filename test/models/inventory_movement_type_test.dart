import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/InventoryMovementType.dart';

void main() {
  group('InventoryMovementType', () {
    test('extensoes expoem labels, icones e natureza da movimentacao', () {
      expect(InventoryMovementType.inbound.label, 'Entrada');
      expect(InventoryMovementType.outbound.icon, Icons.arrow_upward);
      expect(InventoryMovementType.transfer.color, Colors.blueAccent);
      expect(InventoryMovementType.adjustment.isAdditive, isTrue);
      expect(InventoryMovementType.outbound.isIncrease, isFalse);
    });

    test('InventoryMovement fromMap e toMap preservam origem e projeto', () {
      final movement = InventoryMovement.fromMap({
        'itemId': 'i1',
        'itemName': 'Cimento',
        'quantity': 12,
        'type': 'transfer',
        'projectId': 'p1',
        'projectName': 'Obra Centro',
        'purchaseId': 'po1',
        'referenceId': 'req1',
        'date': '2026-05-03T00:00:00.000Z',
        'notes': 'Reposicao',
        'userId': 'u1',
      }, 'mov-1');

      expect(movement.type, InventoryMovementType.transfer);
      expect(movement.projectName, 'Obra Centro');
      expect(movement.toMap()['purchaseId'], 'po1');
    });
  });
}
