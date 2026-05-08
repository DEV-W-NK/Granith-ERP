import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/purchase_model.dart';

void main() {
  group('Purchase', () {
    test('fromMap restaura status, valores e rastreabilidade', () {
      final now = DateTime(2026, 5, 3, 14);
      final purchase = Purchase.fromMap({
        'itemId': 'item-1',
        'itemName': 'Areia',
        'supplierId': 'supplier-1',
        'supplierName': 'Fornecedor A',
        'projectId': 'project-1',
        'projectName': 'Obra Torre',
        'deliveryAddress': 'Campinas',
        'quantity': 3,
        'totalValue': 1800,
        'status': PurchaseStatus.delivered.index,
        'purchaseDate': now.toIso8601String(),
        'deliveryDate': now.toIso8601String(),
        'expectedDeliveryDate':
            now.add(const Duration(days: 5)).toIso8601String(),
        'requisitionId': 'req-1',
        'financialTransactionId': 'tx-1',
        'receivedBy': 'user-2',
        'invoiceNumber': 'NF-123',
        'approvalSector': 'Engenharia',
        'consolidatedByName': 'Compras Granith',
      }, 'purchase-1');

      expect(purchase.id, 'purchase-1');
      expect(purchase.status, PurchaseStatus.delivered);
      expect(purchase.totalValue, 1800);
      expect(purchase.requisitionId, 'req-1');
      expect(purchase.financialTransactionId, 'tx-1');
      expect(purchase.receivedBy, 'user-2');
      expect(purchase.invoiceNumber, 'NF-123');
      expect(purchase.approvalSector, 'Engenharia');
      expect(purchase.consolidatedByName, 'Compras Granith');
    });

    test('copyWith substitui campos sem perder restante do estado', () {
      final original = Purchase(
        id: 'purchase-1',
        itemId: 'item-1',
        itemName: 'Tijolo',
        supplierId: 'supplier-1',
        supplierName: 'Fornecedor B',
        projectId: 'project-1',
        projectName: 'Obra Alfa',
        deliveryAddress: 'SP',
        totalValue: 2000,
        purchaseDate: DateTime(2026, 5, 1),
      );

      final updated = original.copyWith(
        status: PurchaseStatus.ordered,
        quantity: 50,
        invoiceNumber: 'NF-456',
      );

      expect(updated.status, PurchaseStatus.ordered);
      expect(updated.quantity, 50);
      expect(updated.invoiceNumber, 'NF-456');
      expect(updated.itemName, 'Tijolo');
      expect(updated.projectId, 'project-1');
    });
  });
}
