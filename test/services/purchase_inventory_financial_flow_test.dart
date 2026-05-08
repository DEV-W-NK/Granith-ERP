import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';

import '../helpers/fake_financial_service.dart';
import '../helpers/fake_inventory_service.dart';
import '../helpers/fake_project_budget_service.dart';

void main() {
  group('PurchaseService', () {
    test('approvePurchase aprova o orcamento sem criar financeiro', () async {
      final financialService = FakeFinancialService();
      late Map<String, dynamic> persistedApproval;

      final purchase = Purchase(
        id: 'purchase-approval-1',
        itemId: 'item-1',
        itemName: 'Vergalhao',
        supplierId: 'supplier-1',
        supplierName: 'Aco Forte',
        projectId: 'project-1',
        projectName: 'Obra Comercial',
        deliveryAddress: 'Campinas',
        quantity: 20,
        totalValue: 5800,
        status: PurchaseStatus.awaitingApproval,
        purchaseDate: DateTime(2026, 5, 2, 9),
        approvalSector: 'Engenharia',
      );

      final service = PurchaseService(
        financialService: financialService,
        nowProvider: () => DateTime(2026, 5, 3, 14),
        purchaseLoader: (id) async => id == purchase.id ? purchase : null,
        approvalPersister: ({
          required purchase,
          required approvedBy,
          required approvedByName,
          required approvedAt,
        }) async {
          persistedApproval = {
            'purchaseId': purchase.id,
            'approvedBy': approvedBy,
            'approvedByName': approvedByName,
            'approvedAt': approvedAt,
          };
        },
      );

      await service.approvePurchase(
        purchaseId: purchase.id,
        approvedBy: 'coord-1',
        approvedByName: 'Coordenador Engenharia',
      );

      expect(financialService.lastAddedTransaction, isNull);
      expect(persistedApproval['purchaseId'], purchase.id);
      expect(persistedApproval['approvedBy'], 'coord-1');
      expect(persistedApproval['approvedByName'], 'Coordenador Engenharia');
      expect(persistedApproval['approvedAt'], DateTime(2026, 5, 3, 14));
    });

    test(
      'consolidatePurchase gera conta a pagar e vincula dados da NF',
      () async {
        final financialService = FakeFinancialService();
        late Map<String, dynamic> persistedConsolidation;

        final purchase = Purchase(
          id: 'purchase-consolidation-1',
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

        final service = PurchaseService(
          financialService: financialService,
          nowProvider: () => DateTime(2026, 5, 3, 14),
          consolidationPersister: ({
            required purchase,
            required transactionId,
            required consolidatedBy,
            required consolidatedByName,
            required consolidatedAt,
            required invoiceNumber,
            required invoiceAccessKey,
            required expectedDeliveryDate,
            required notes,
          }) async {
            persistedConsolidation = {
              'purchase': purchase,
              'transactionId': transactionId,
              'consolidatedBy': consolidatedBy,
              'consolidatedByName': consolidatedByName,
              'consolidatedAt': consolidatedAt,
              'invoiceNumber': invoiceNumber,
              'invoiceAccessKey': invoiceAccessKey,
              'expectedDeliveryDate': expectedDeliveryDate,
              'notes': notes,
            };
          },
        );

        await service.consolidatePurchase(
          purchase: purchase,
          consolidatedBy: 'buyer-1',
          consolidatedByName: 'Compras Granith',
          invoiceNumber: 'NF-123',
          invoiceAccessKey: '352605...',
          expectedDeliveryDate: DateTime(2026, 5, 10),
          notes: 'Entrega em horario comercial',
        );

        final transaction = financialService.lastAddedTransaction;
        expect(transaction, isNotNull);
        expect(transaction!.type, TransactionType.expense);
        expect(transaction.status, TransactionStatus.pending);
        expect(transaction.origin, TransactionOrigin.purchase);
        expect(transaction.category, TransactionCategory.material);
        expect(transaction.projectId, 'project-1');
        expect(transaction.supplierId, 'supplier-1');
        expect(transaction.referenceId, purchase.id);
        expect(transaction.paymentDate, isNull);
        expect(transaction.amount, 2100);
        expect(transaction.dueDate, DateTime(2026, 5, 10));
        expect(transaction.description, contains('NF NF-123'));
        expect(transaction.notes, contains('consolidacao da compra'));

        expect(
          persistedConsolidation['transactionId'],
          'generated-financial-id',
        );
        expect(persistedConsolidation['consolidatedBy'], 'buyer-1');
        expect(persistedConsolidation['consolidatedByName'], 'Compras Granith');
        expect(
          persistedConsolidation['consolidatedAt'],
          DateTime(2026, 5, 3, 14),
        );
        expect(persistedConsolidation['invoiceNumber'], 'NF-123');
        expect(persistedConsolidation['invoiceAccessKey'], '352605...');
        expect(
          persistedConsolidation['expectedDeliveryDate'],
          DateTime(2026, 5, 10),
        );
        expect(persistedConsolidation['notes'], 'Entrega em horario comercial');
      },
    );

    test(
      'confirmDelivery cria conta a pagar pendente quando compra consolidada ainda nao tinha lancamento financeiro',
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
          status: PurchaseStatus.ordered,
          purchaseDate: DateTime(2026, 5, 2, 9),
        );

        await service.confirmDelivery(
          purchase: purchase,
          receivedBy: 'warehouse-1',
        );

        final transaction = financialService.lastAddedTransaction;
        expect(transaction, isNotNull);
        expect(transaction!.type, TransactionType.expense);
        expect(transaction.status, TransactionStatus.pending);
        expect(transaction.origin, TransactionOrigin.purchase);
        expect(transaction.category, TransactionCategory.material);
        expect(transaction.projectId, 'project-1');
        expect(transaction.referenceId, 'purchase-1');
        expect(transaction.paymentDate, isNull);
        expect(transaction.amount, 2100);

        expect(persistedDelivery['purchaseId'], 'purchase-1');
        expect(persistedDelivery['transactionId'], 'generated-financial-id');
        expect(persistedDelivery['receivedBy'], 'warehouse-1');
        expect(persistedDelivery['deliveryDate'], DateTime(2026, 5, 3, 14));

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
      'confirmDelivery reaproveita conta a pagar criada na consolidacao',
      () async {
        final financialService = FakeFinancialService();
        final inventoryService = FakeInventoryService();
        final budgetService = FakeProjectBudgetService();
        late Map<String, dynamic> persistedDelivery;

        final service = PurchaseService(
          financialService: financialService,
          inventoryService: inventoryService,
          projectBudgetService: budgetService,
          nowProvider: () => DateTime(2026, 5, 4, 10),
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
          id: 'purchase-2',
          itemId: 'item-2',
          itemName: 'Areia',
          supplierId: 'supplier-2',
          supplierName: 'Fornecedor Sul',
          projectId: 'project-2',
          projectName: 'Obra Industrial',
          deliveryAddress: 'Santos',
          quantity: 3,
          totalValue: 900,
          status: PurchaseStatus.ordered,
          purchaseDate: DateTime(2026, 5, 2),
          financialTransactionId: 'payable-1',
        );

        await service.confirmDelivery(
          purchase: purchase,
          receivedBy: 'warehouse-1',
        );

        expect(financialService.lastAddedTransaction, isNull);
        expect(persistedDelivery['transactionId'], 'payable-1');
        expect(
          inventoryService.lastDeliveredPurchase?.financialTransactionId,
          'payable-1',
        );
        expect(budgetService.lastSyncedProjectId, 'project-2');
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

    test('confirmDelivery exige compra consolidada', () async {
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
            status: PurchaseStatus.pending,
            purchaseDate: DateTime(2026, 5, 3),
          ),
          receivedBy: 'user-1',
        ),
        throwsA(isA<Exception>()),
      );
    });

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
