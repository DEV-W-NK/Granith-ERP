import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/services/inventory_service.dart';

class PurchaseService {
  final FirebaseFirestore _firestore;
  static const String _col = 'purchases';

  PurchaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _ref => _firestore.collection(_col);

  // ─── CRUD básico ──────────────────────────────────────────────────────────

  Future<String> addPurchase(Purchase purchase) async {
    try {
      if (purchase.id.isEmpty) {
        final docRef = await _ref.add(purchase.toMap());
        await docRef.update({'id': docRef.id});
        return docRef.id;
      } else {
        await _ref.doc(purchase.id).set(purchase.toMap());
        return purchase.id;
      }
    } catch (e) {
      throw Exception('Erro ao registrar compra: $e');
    }
  }

  Future<void> updatePurchase(Purchase purchase) async {
    await _ref.doc(purchase.id).update(purchase.toMap());
  }

  Future<void> deletePurchase(String id) async {
    await _ref.doc(id).delete();
  }

  // ─── Streams ─────────────────────────────────────────────────────────────

  /// Todas as compras exceto awaitingApproval — para o setor de compras.
  Stream<List<Purchase>> getPurchasesStream() {
    return _ref
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Apenas compras aguardando aprovação do CEO.
  Stream<List<Purchase>> getAwaitingApprovalStream() {
    return _ref
        .where('status', isEqualTo: PurchaseStatus.awaitingApproval.index)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<Purchase>> getPurchasesByProject(String projectId) {
    return _ref
        .where('projectId', isEqualTo: projectId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  // ─── Aprovação CEO ────────────────────────────────────────────────────────

  Future<void> approvePurchase({
    required String purchaseId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    await _ref.doc(purchaseId).update({
      'status':          PurchaseStatus.pending.index,
      'approvedBy':      approvedBy,
      'approvedByName':  approvedByName,
      'approvedAt':      Timestamp.fromDate(DateTime.now()),
      'rejectionReason': null,
    });
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
    await _ref.doc(purchaseId).update({
      'status':          PurchaseStatus.cancelled.index,
      'approvedBy':      rejectedBy,
      'approvedByName':  rejectedByName,
      'approvedAt':      Timestamp.fromDate(DateTime.now()),
      'rejectionReason': reason.trim(),
    });
  }

  // ─── Confirmação de entrega ───────────────────────────────────────────────
  //
  // Batch atômico:
  //   1. Compra → delivered + deliveryDate + receivedBy + financialTransactionId
  //   2. FinancialTransaction → despesa lançada (origin: purchase)
  // Pós-batch:
  //   3. InventoryService → entrada no estoque com purchase.quantity
  //   4. ProjectBudgetService → sync currentCost do projeto

  Future<void> confirmDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    if (purchase.status == PurchaseStatus.delivered) {
      throw Exception('Esta compra já foi confirmada como entregue.');
    }

    final now            = DateTime.now();
    final transactionRef = _firestore.collection('financial_transactions').doc();

    final transaction = FinancialTransactionModel(
      id:          transactionRef.id,
      description: 'Compra: ${purchase.itemName} — ${purchase.supplierName}',
      amount:      purchase.totalValue,
      type:        TransactionType.expense,
      status:      TransactionStatus.paid,
      origin:      TransactionOrigin.purchase,
      category:    TransactionCategory.material,
      dueDate:     now,
      paymentDate: now,
      projectId:   purchase.projectId.isNotEmpty  ? purchase.projectId  : null,
      supplierId:  purchase.supplierId.isNotEmpty ? purchase.supplierId : null,
      referenceId: purchase.id,
      createdBy:   receivedBy,
      createdAt:   now,
      notes: 'Gerado automaticamente ao confirmar entrega da compra #${purchase.id}',
    );

    final batch = _firestore.batch();

    batch.update(_ref.doc(purchase.id), {
      'status':                 PurchaseStatus.delivered.index,
      'deliveryDate':           Timestamp.fromDate(now),
      'receivedBy':             receivedBy,
      'financialTransactionId': transactionRef.id,
    });

    batch.set(transactionRef, transaction.toMap());

    final inventoryService = InventoryService(firestore: _firestore);
    await inventoryService.processPurchaseDelivery(
      purchase:   purchase,
      receivedBy: receivedBy,
    );

    await batch.commit();

    if (purchase.projectId.isNotEmpty) {
      try {
        await ProjectBudgetService(firestore: _firestore)
            .syncProjectCurrentCost(purchase.projectId);
      } catch (e) {
        // ignore: avoid_print
        print('[PurchaseService] Aviso: sync de custo falhou: $e');
      }
    }
  }

  // ─── Cancelamento ─────────────────────────────────────────────────────────

  Future<void> cancelPurchase({
    required Purchase purchase,
    required String cancelledBy,
  }) async {
    if (purchase.status == PurchaseStatus.delivered) {
      throw Exception(
          'Não é possível cancelar uma compra entregue. Faça uma devolução manual.');
    }

    final batch = _firestore.batch();

    batch.update(_ref.doc(purchase.id), {
      'status': PurchaseStatus.cancelled.index,
    });

    if (purchase.financialTransactionId != null) {
      batch.update(
        _firestore
            .collection('financial_transactions')
            .doc(purchase.financialTransactionId),
        {
          'status':    TransactionStatus.cancelled.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
    }

    await batch.commit();
  }

  // Atualização simples de status intermediário (pending → ordered)
  Future<void> updateStatus(String id, PurchaseStatus status) async {
    if (status == PurchaseStatus.delivered ||
        status == PurchaseStatus.cancelled ||
        status == PurchaseStatus.awaitingApproval) {
      throw Exception(
          'Use os métodos dedicados para este status.');
    }
    await _ref.doc(id).update({'status': status.index});
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  List<Purchase> _mapSnapshot(QuerySnapshot snap) {
    return snap.docs
        .map((d) =>
            Purchase.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}