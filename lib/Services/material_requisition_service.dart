import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/requisition_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/purchase_service.dart';

class MaterialRequisitionService {
  final FirebaseFirestore _firestore;

  MaterialRequisitionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col =>
      _firestore.collection('material_requisitions');

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<List<MaterialRequisitionModel>> getRequisitions() {
    return _col
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<MaterialRequisitionModel>> getByProject(String projectId) {
    return _col
        .where('projectId', isEqualTo: projectId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<MaterialRequisitionModel>> getByStatus(RequisitionStatus status) {
    return _col
        .where('status', isEqualTo: status.name)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  // ─── CRUD básico ──────────────────────────────────────────────────────────

  Future<String> addRequisition(MaterialRequisitionModel req) async {
    final docRef = await _col.add(req.toMap());
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  Future<void> updateRequisition(MaterialRequisitionModel req) async {
    await _col.doc(req.id).update(req.toMap());
  }

  Future<void> deleteRequisition(String id) async {
    await _col.doc(id).delete();
  }

  // ─── Etapa 2: Aprovação ───────────────────────────────────────────────────

  Future<void> approve({
    required MaterialRequisitionModel requisition,
    required String approvedBy,
    required String approvedByName,
  }) async {
    await _col.doc(requisition.id).update({
      'status':          RequisitionStatus.approved.name,
      'approvedBy':      approvedBy,
      'approvedByName':  approvedByName,
      'approvedAt':      Timestamp.fromDate(DateTime.now()),
      'rejectionReason': null,
    });
  }

  // ─── Etapa 2: Rejeição ────────────────────────────────────────────────────

  Future<void> reject({
    required MaterialRequisitionModel requisition,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Informe o motivo da rejeição.');
    }
    await _col.doc(requisition.id).update({
      'status':          RequisitionStatus.rejected.name,
      'approvedBy':      rejectedBy,
      'approvedByName':  rejectedByName,
      'approvedAt':      Timestamp.fromDate(DateTime.now()),
      'rejectionReason': reason.trim(),
    });
  }

  // ─── Etapa 3: Converter em Compra ─────────────────────────────────────────
  //
  // Para cada item da requisição, cria uma Purchase com o fornecedor
  // e preço escolhidos pelo gestor. Vincula purchaseId na requisição
  // e muda status para purchased.

  Future<List<String>> convertToPurchase({
    required MaterialRequisitionModel requisition,
    required Supplier supplier,
    required String createdBy,
    // itemName → valor total da compra daquele item
    required Map<String, double> itemPrices,
  }) async {
    if (requisition.status != RequisitionStatus.approved) {
      throw Exception(
          'A requisição precisa estar aprovada para gerar uma compra.');
    }

    final purchaseService = PurchaseService(firestore: _firestore);
    final purchaseIds = <String>[];

    for (final item in requisition.items) {
      final price = itemPrices[item.itemName] ?? 0.0;

      final purchase = Purchase(
        id:              '',
        itemId:          '',
        itemName:        item.itemName,
        supplierId:      supplier.id,
        supplierName:    supplier.name,
        projectId:       requisition.projectId,
        projectName:     requisition.projectName,
        deliveryAddress: requisition.projectName,
        quantity:        item.quantity,
        totalValue:      price,
        status:          PurchaseStatus.awaitingApproval,
        purchaseDate:    DateTime.now(),
        requisitionId:   requisition.id,
      );

      final purchaseId = await purchaseService.addPurchase(purchase);
      purchaseIds.add(purchaseId);
    }

    await _col.doc(requisition.id).update({
      'status':     RequisitionStatus.purchased.name,
      'purchaseId': purchaseIds.first,
    });

    return purchaseIds;
  }

  List<MaterialRequisitionModel> _mapSnapshot(QuerySnapshot snap) {
    return snap.docs
        .map((d) => MaterialRequisitionModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}