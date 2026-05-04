import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/services/financial_service.dart';
import 'package:project_granith/services/inventory_service.dart';

typedef PurchaseDeliveryPersister =
    Future<void> Function({
      required Purchase purchase,
      required String transactionId,
      required String receivedBy,
      required DateTime deliveryDate,
    });

class PurchaseService {
  static const _table = 'purchases';

  PurchaseService({
    FinancialService? financialService,
    InventoryService? inventoryService,
    ProjectBudgetService? projectBudgetService,
    PurchaseDeliveryPersister? deliveryPersister,
    DateTime Function()? nowProvider,
  }) : _financialService = financialService,
       _inventoryService = inventoryService,
       _projectBudgetService = projectBudgetService,
       _deliveryPersister = deliveryPersister,
       _nowProvider = nowProvider ?? DateTime.now;

  final FinancialService? _financialService;
  final InventoryService? _inventoryService;
  final ProjectBudgetService? _projectBudgetService;
  final PurchaseDeliveryPersister? _deliveryPersister;
  final DateTime Function() _nowProvider;

  Future<String> addPurchase(Purchase purchase) async {
    try {
      final data = DbValue.normalizeMap(purchase.toMap());

      if (purchase.id.isNotEmpty) {
        data['id'] = purchase.id;
        await AppSupabase.client.from(_table).upsert(data);
        return purchase.id;
      }

      final row =
          await AppSupabase.client
              .from(_table)
              .insert(data)
              .select('id')
              .single();

      return row['id'] as String;
    } catch (e) {
      throw Exception('Erro ao registrar compra: $e');
    }
  }

  Future<void> updatePurchase(Purchase purchase) async {
    await AppSupabase.client
        .from(_table)
        .update(DbValue.normalizeMap(purchase.toMap()))
        .eq('id', purchase.id);
  }

  Future<void> deletePurchase(String id) async {
    await AppSupabase.client.from(_table).delete().eq('id', id);
  }

  Stream<List<Purchase>> getPurchasesStream() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('purchaseDate', ascending: false)
        .map(_rowsToPurchases);
  }

  Stream<List<Purchase>> getAwaitingApprovalStream() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('status', PurchaseStatus.awaitingApproval.index)
        .order('purchaseDate', ascending: false)
        .map(_rowsToPurchases);
  }

  Stream<List<Purchase>> getPurchasesByProject(String projectId) {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('projectId', projectId)
        .order('purchaseDate', ascending: false)
        .map(_rowsToPurchases);
  }

  Future<void> approvePurchase({
    required String purchaseId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    await AppSupabase.client
        .from(_table)
        .update({
          'status': PurchaseStatus.pending.index,
          'approvedBy': approvedBy,
          'approvedByName': approvedByName,
          'approvedAt': DbValue.toPrimitive(DateTime.now()),
          'rejectionReason': null,
        })
        .eq('id', purchaseId);
  }

  Future<void> rejectPurchase({
    required String purchaseId,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Informe o motivo da recusa.');
    }

    await AppSupabase.client
        .from(_table)
        .update({
          'status': PurchaseStatus.cancelled.index,
          'approvedBy': rejectedBy,
          'approvedByName': rejectedByName,
          'approvedAt': DbValue.toPrimitive(DateTime.now()),
          'rejectionReason': reason.trim(),
        })
        .eq('id', purchaseId);
  }

  Future<void> confirmDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    if (purchase.status == PurchaseStatus.delivered) {
      throw Exception('Esta compra ja foi confirmada como entregue.');
    }

    final now = _nowProvider();
    final transaction = FinancialTransactionModel(
      id: '',
      description: 'Compra: ${purchase.itemName} - ${purchase.supplierName}',
      amount: purchase.totalValue,
      type: TransactionType.expense,
      status: TransactionStatus.paid,
      origin: TransactionOrigin.purchase,
      category: TransactionCategory.material,
      dueDate: now,
      paymentDate: now,
      projectId: purchase.projectId.isNotEmpty ? purchase.projectId : null,
      supplierId: purchase.supplierId.isNotEmpty ? purchase.supplierId : null,
      referenceId: purchase.id,
      createdBy: receivedBy,
      createdAt: now,
      notes:
          'Gerado automaticamente ao confirmar entrega da compra #${purchase.id}',
    );

    final financialService = _financialService ?? FinancialService();
    final inventoryService = _inventoryService ?? InventoryService();
    final projectBudgetService =
        _projectBudgetService ?? ProjectBudgetService();
    final deliveryPersister = _deliveryPersister;
    final transactionId = await financialService.addTransaction(transaction);

    if (deliveryPersister != null) {
      await deliveryPersister(
        purchase: purchase,
        transactionId: transactionId,
        receivedBy: receivedBy,
        deliveryDate: now,
      );
    } else {
      await AppSupabase.client
          .from(_table)
          .update({
            'status': PurchaseStatus.delivered.index,
            'deliveryDate': DbValue.toPrimitive(now),
            'receivedBy': receivedBy,
            'financialTransactionId': transactionId,
          })
          .eq('id', purchase.id);
    }

    await inventoryService.processPurchaseDelivery(
      purchase: purchase.copyWith(
        status: PurchaseStatus.delivered,
        deliveryDate: now,
        receivedBy: receivedBy,
        financialTransactionId: transactionId,
      ),
      receivedBy: receivedBy,
    );

    if (purchase.projectId.isNotEmpty) {
      try {
        await projectBudgetService.syncProjectCurrentCost(purchase.projectId);
      } catch (e) {
        // ignore: avoid_print
        print('[PurchaseService] Aviso: sync de custo falhou: $e');
      }
    }
  }

  Future<void> cancelPurchase({
    required Purchase purchase,
    required String cancelledBy,
  }) async {
    if (purchase.status == PurchaseStatus.delivered) {
      throw Exception(
        'Nao e possivel cancelar uma compra entregue. Faca uma devolucao manual.',
      );
    }

    await AppSupabase.client
        .from(_table)
        .update({'status': PurchaseStatus.cancelled.index})
        .eq('id', purchase.id);

    final transactionId = purchase.financialTransactionId;
    if (transactionId != null && transactionId.isNotEmpty) {
      await FinancialService().cancelTransaction(transactionId);
    }
  }

  Future<void> updateStatus(String id, PurchaseStatus status) async {
    if (status == PurchaseStatus.delivered ||
        status == PurchaseStatus.cancelled ||
        status == PurchaseStatus.awaitingApproval) {
      throw Exception('Use os metodos dedicados para este status.');
    }

    await AppSupabase.client
        .from(_table)
        .update({'status': status.index})
        .eq('id', id);
  }

  List<Purchase> _rowsToPurchases(List<dynamic> rows) {
    return rows
        .map((row) => _rowToPurchase(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Purchase _rowToPurchase(Map<String, dynamic> row) {
    return Purchase.fromMap(row, row['id'] as String? ?? '');
  }
}
