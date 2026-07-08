import 'dart:async';

import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/services/financial_service.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/services/mobile_push_dispatch_service.dart';

typedef PurchaseDeliveryPersister =
    Future<void> Function({
      required Purchase purchase,
      required String transactionId,
      required String receivedBy,
      required DateTime deliveryDate,
    });

typedef PurchaseApprovalPersister =
    Future<void> Function({
      required Purchase purchase,
      required String approvedBy,
      required String approvedByName,
      required DateTime approvedAt,
    });

typedef PurchaseConsolidationPersister =
    Future<void> Function({
      required Purchase purchase,
      required String transactionId,
      required String consolidatedBy,
      required String consolidatedByName,
      required DateTime consolidatedAt,
      required String invoiceNumber,
      required String invoiceAccessKey,
      required DateTime? expectedDeliveryDate,
      required String notes,
    });

typedef PurchaseLoader = Future<Purchase?> Function(String purchaseId);

class PurchaseService {
  static const _table = 'purchases';

  PurchaseService({
    FinancialService? financialService,
    InventoryService? inventoryService,
    ProjectBudgetService? projectBudgetService,
    PurchaseApprovalPersister? approvalPersister,
    PurchaseConsolidationPersister? consolidationPersister,
    PurchaseDeliveryPersister? deliveryPersister,
    PurchaseLoader? purchaseLoader,
    DateTime Function()? nowProvider,
  }) : _financialService = financialService,
       _inventoryService = inventoryService,
       _projectBudgetService = projectBudgetService,
       _approvalPersister = approvalPersister,
       _consolidationPersister = consolidationPersister,
       _deliveryPersister = deliveryPersister,
       _purchaseLoader = purchaseLoader,
       _nowProvider = nowProvider ?? DateTime.now;

  final FinancialService? _financialService;
  final InventoryService? _inventoryService;
  final ProjectBudgetService? _projectBudgetService;
  final PurchaseApprovalPersister? _approvalPersister;
  final PurchaseConsolidationPersister? _consolidationPersister;
  final PurchaseDeliveryPersister? _deliveryPersister;
  final PurchaseLoader? _purchaseLoader;
  final DateTime Function() _nowProvider;

  Future<String> addPurchase(Purchase purchase) async {
    try {
      final data = DbValue.normalizeMap(purchase.toMap());

      if (purchase.id.isNotEmpty) {
        data['id'] = purchase.id;
        await AppSupabase.client.from(_table).upsert(data);
        _notifyPurchasesChanged();
        return purchase.id;
      }

      final row =
          await AppSupabase.client
              .from(_table)
              .insert(data)
              .select('id')
              .single();

      final id = row['id'] as String;
      _notifyPurchasesChanged();
      return id;
    } catch (e) {
      throw Exception('Erro ao registrar compra: $e');
    }
  }

  Future<void> updatePurchase(Purchase purchase) async {
    await AppSupabase.client
        .from(_table)
        .update(DbValue.normalizeMap(purchase.toMap()))
        .eq('id', purchase.id);
    _notifyPurchasesChanged();
  }

  Future<void> deletePurchase(String id) async {
    await AppSupabase.client.from(_table).delete().eq('id', id);
    _notifyPurchasesChanged();
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
    final purchase = await _loadPurchase(purchaseId);
    if (purchase == null) {
      throw Exception('Compra nao encontrada.');
    }

    if (purchase.status == PurchaseStatus.cancelled) {
      throw Exception('Nao e possivel aprovar uma compra cancelada.');
    }
    if (purchase.status == PurchaseStatus.delivered) {
      throw Exception('Compra entregue nao pode voltar para aprovacao.');
    }

    if (purchase.status != PurchaseStatus.awaitingApproval) {
      throw Exception(
        'Apenas orcamentos aguardando aprovacao podem ser aprovados.',
      );
    }

    final now = _nowProvider();
    final approvedPurchase = purchase.copyWith(
      status: PurchaseStatus.pending,
      approvedBy: approvedBy,
      approvedByName: approvedByName,
      approvedAt: now,
    );

    final approvalPersister = _approvalPersister;
    if (approvalPersister != null) {
      await approvalPersister(
        purchase: approvedPurchase,
        approvedBy: approvedBy,
        approvedByName: approvedByName,
        approvedAt: now,
      );
    } else {
      await AppSupabase.client
          .from(_table)
          .update({
            'status': PurchaseStatus.pending.index,
            'approvedBy': approvedBy,
            'approvedByName': approvedByName,
            'approvedAt': DbValue.toPrimitive(now),
            'rejectionReason': null,
          })
          .eq('id', purchaseId);
    }
    _notifyPurchasesChanged();
  }

  Future<void> consolidatePurchase({
    required Purchase purchase,
    required String consolidatedBy,
    required String consolidatedByName,
    required String invoiceNumber,
    String invoiceAccessKey = '',
    DateTime? expectedDeliveryDate,
    String notes = '',
  }) async {
    if (purchase.status != PurchaseStatus.pending) {
      throw Exception(
        'A compra precisa estar aprovada pelo setor para ser consolidada.',
      );
    }
    if (invoiceNumber.trim().isEmpty) {
      throw Exception('Informe o numero da nota fiscal.');
    }

    final now = _nowProvider();
    final financialService = _financialService ?? FinancialService();
    final enrichedPurchase = purchase.copyWith(
      status: PurchaseStatus.ordered,
      invoiceNumber: invoiceNumber.trim(),
      invoiceAccessKey: invoiceAccessKey.trim(),
      expectedDeliveryDate: expectedDeliveryDate,
      notes: notes.trim(),
      consolidatedBy: consolidatedBy,
      consolidatedByName: consolidatedByName,
      consolidatedAt: now,
    );
    final transactionId = await _ensurePurchasePayable(
      purchase: enrichedPurchase,
      financialService: financialService,
      createdBy: consolidatedBy,
      now: now,
      notes:
          'Conta a pagar gerada na consolidacao da compra #${purchase.id}. NF: ${invoiceNumber.trim()}. ${notes.trim()}',
    );

    final consolidationPersister = _consolidationPersister;
    if (consolidationPersister != null) {
      await consolidationPersister(
        purchase: enrichedPurchase,
        transactionId: transactionId,
        consolidatedBy: consolidatedBy,
        consolidatedByName: consolidatedByName,
        consolidatedAt: now,
        invoiceNumber: invoiceNumber.trim(),
        invoiceAccessKey: invoiceAccessKey.trim(),
        expectedDeliveryDate: expectedDeliveryDate,
        notes: notes.trim(),
      );
    } else {
      await AppSupabase.client
          .from(_table)
          .update({
            'status': PurchaseStatus.ordered.index,
            'financialTransactionId': transactionId,
            'invoiceNumber': invoiceNumber.trim(),
            'invoiceAccessKey': invoiceAccessKey.trim(),
            'expectedDeliveryDate': DbValue.toPrimitive(expectedDeliveryDate),
            'notes': notes.trim(),
            'consolidatedBy': consolidatedBy,
            'consolidatedByName': consolidatedByName,
            'consolidatedAt': DbValue.toPrimitive(now),
          })
          .eq('id', purchase.id);
    }
    _notifyPurchasesChanged(
      extraScopes: const [AppDataRefreshBus.financialTransactions],
    );
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
    _notifyPurchasesChanged();
  }

  Future<void> confirmDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    if (purchase.status == PurchaseStatus.delivered) {
      throw Exception('Esta compra ja foi confirmada como entregue.');
    }
    if (purchase.status != PurchaseStatus.ordered) {
      throw Exception(
        'A compra precisa estar consolidada antes de confirmar a entrega.',
      );
    }

    final now = _nowProvider();
    final financialService = _financialService ?? FinancialService();
    final inventoryService = _inventoryService ?? InventoryService();
    final projectBudgetService =
        _projectBudgetService ?? ProjectBudgetService();
    final deliveryPersister = _deliveryPersister;
    final transactionId = await _ensurePurchasePayable(
      purchase: purchase,
      financialService: financialService,
      createdBy: receivedBy,
      now: now,
      notes:
          'Conta a pagar criada automaticamente no recebimento da compra #${purchase.id}.',
    );

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
    _notifyPurchasesChanged(
      extraScopes: const [
        AppDataRefreshBus.inventory,
        AppDataRefreshBus.inventoryMovements,
        AppDataRefreshBus.projects,
        AppDataRefreshBus.financialTransactions,
      ],
    );
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
    _notifyPurchasesChanged(
      extraScopes: const [AppDataRefreshBus.financialTransactions],
    );
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
    _notifyPurchasesChanged();
  }

  List<Purchase> _rowsToPurchases(List<dynamic> rows) {
    return rows
        .map((row) => _rowToPurchase(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Purchase _rowToPurchase(Map<String, dynamic> row) {
    return Purchase.fromMap(row, row['id'] as String? ?? '');
  }

  Future<Purchase?> _loadPurchase(String purchaseId) async {
    final loader = _purchaseLoader;
    if (loader != null) {
      return loader(purchaseId);
    }

    final row =
        await AppSupabase.client
            .from(_table)
            .select()
            .eq('id', purchaseId)
            .maybeSingle();
    if (row == null) return null;
    return _rowToPurchase(Map<String, dynamic>.from(row));
  }

  Future<String> _ensurePurchasePayable({
    required Purchase purchase,
    required FinancialService financialService,
    required String createdBy,
    required DateTime now,
    required String notes,
  }) async {
    final existingTransactionId = purchase.financialTransactionId;
    if (existingTransactionId != null && existingTransactionId.isNotEmpty) {
      return existingTransactionId;
    }

    final transaction = FinancialTransactionModel(
      id: '',
      description:
          'Compra: ${purchase.itemName} - ${purchase.supplierName}'
          '${purchase.invoiceNumber?.trim().isNotEmpty == true ? ' - NF ${purchase.invoiceNumber}' : ''}',
      amount: purchase.totalValue,
      type: TransactionType.expense,
      status: TransactionStatus.pending,
      origin: TransactionOrigin.purchase,
      category: TransactionCategory.material,
      dueDate: purchase.expectedDeliveryDate ?? now,
      paymentDate: null,
      projectId: purchase.projectId.isNotEmpty ? purchase.projectId : null,
      supplierId: purchase.supplierId.isNotEmpty ? purchase.supplierId : null,
      referenceId: purchase.id,
      createdBy: createdBy,
      createdAt: now,
      notes: [
        notes,
        purchase.notes,
      ].where((value) => value != null && value.trim().isNotEmpty).join('\n'),
    );

    return financialService.addTransaction(transaction);
  }

  void _notifyPurchasesChanged({List<String> extraScopes = const []}) {
    AppDataRefreshBus.instance.notify(
      scopes: [AppDataRefreshBus.purchases, ...extraScopes],
      source: 'PurchaseService',
    );
    unawaited(MobilePushDispatchService.dispatchPending());
  }
}
