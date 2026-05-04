import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';

import '../helpers/fake_financial_service.dart';
import '../helpers/fake_inventory_service.dart';
import '../helpers/fake_project_budget_service.dart';

void main() {
  group('PurchaseService', () {
    test(
      'confirmDelivery gera despesa paga, persiste entrega, atualiza estoque e sincroniza custo do projeto',
      () async {
        final financialService = FakeFinancialService();
        final inventoryService = FakeInventoryService();
        final budgetService = FakeProjectBudgetService();
        late Map<String, dynamic> persistedDelivery;

        final service = PurchaseService(
          financialService: financialService,
          inventoryService: inventoryService,
          projectBudgetService: budgetService,
          nowProvider: () => DateTime(2026, 5, 3, 14),
          deliveryPersister: ({
            required purchase,
            required transactionId,
            required receivedBy,
            required deliveryDate,
          }) async {
            persistedDelivery = {
              'purchaseId': purchase.id,
              'transactionId': transactionId,
              'receivedBy': receivedBy,
              'deliveryDate': deliveryDate,
            };
          },
        );

        final purchase = Purchase(
          id: 'purchase-1',
          itemId: 'item-1',
          itemName: 'Cimento',
          supplierId: 'supplier-1',
          supplierName: 'Fornecedor Forte',
          projectId: 'project-1',
          projectName: 'Obra Comercial',
          deliveryAddress: 'Campinas',
          quantity: 10,
          totalValue: 2100,
          status: PurchaseStatus.pending,
          purchaseDate: DateTime(2026, 5, 2, 9),
        );

        await service.confirmDelivery(
          purchase: purchase,
          receivedBy: 'warehouse-1',
        );

        final transaction = financialService.lastAddedTransaction;
        expect(transaction, isNotNull);
        expect(transaction!.type, TransactionType.expense);
        expect(transaction.status, TransactionStatus.paid);
        expect(transaction.origin, TransactionOrigin.purchase);
        expect(transaction.category, TransactionCategory.material);
        expect(transaction.projectId, 'project-1');
        expect(transaction.referenceId, 'purchase-1');
        expect(transaction.amount, 2100);

        expect(persistedDelivery['purchaseId'], 'purchase-1');
        expect(persistedDelivery['transactionId'], 'generated-financial-id');
        expect(persistedDelivery['receivedBy'], 'warehouse-1');
        expect(
          persistedDelivery['deliveryDate'],
          DateTime(2026, 5, 3, 14),
        );

        expect(inventoryService.lastDeliveryReceivedBy, 'warehouse-1');
        expect(
          inventoryService.lastDeliveredPurchase?.status,
          PurchaseStatus.delivered,
        );
        expect(
          inventoryService.lastDeliveredPurchase?.financialTransactionId,
          'generated-financial-id',
        );

        expect(budgetService.lastSyncedProjectId, 'project-1');
      },
    );

    test(
      'confirmDelivery rejeita compra que ja esta entregue antes de acessar backend',
      () async {
        final service = PurchaseService();

        await expectLater(
          () => service.confirmDelivery(
            purchase: Purchase(
              id: 'purchase-1',
              itemId: 'item-1',
              itemName: 'Cimento',
              supplierId: 'supplier-1',
              supplierName: 'Fornecedor',
              projectId: 'project-1',
              projectName: 'Obra',
              deliveryAddress: 'Deposito',
              totalValue: 100,
              status: PurchaseStatus.delivered,
              purchaseDate: DateTime(2026, 5, 3),
            ),
            receivedBy: 'user-1',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('updateStatus exige metodos dedicados para status finais', () async {
      final service = PurchaseService();

      await expectLater(
        () => service.updateStatus('purchase-1', PurchaseStatus.delivered),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        () => service.updateStatus('purchase-1', PurchaseStatus.cancelled),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        () =>
            service.updateStatus('purchase-1', PurchaseStatus.awaitingApproval),
        throwsA(isA<Exception>()),
      );
    });
  });
}
