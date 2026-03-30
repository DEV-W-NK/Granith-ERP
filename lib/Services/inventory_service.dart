import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/models/purchase_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore;
  static const _col     = 'inventory';
  static const _history = 'inventory_movements';

  InventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<List<InventoryItem>> getInventoryStream() {
    return _firestore
        .collection(_col)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs
            .map((d) => InventoryItem.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<InventoryItem>> getLowStockStream() {
    return getInventoryStream()
        .map((items) => items.where((i) => i.isLowStock).toList());
  }

  Stream<List<InventoryMovement>> getMovementsStream({
    String? itemId,
    String? projectId,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(_history)
        .orderBy('date', descending: true)
        .limit(limit);

    if (itemId != null)    query = query.where('itemId',    isEqualTo: itemId);
    if (projectId != null) query = query.where('projectId', isEqualTo: projectId);

    return query.snapshots().map((s) => s.docs
        .map((d) => InventoryMovement.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Entrada de compra ────────────────────────────────────────────────────
  //
  // Chamado pelo purchase_service.confirmDelivery() após o batch financeiro.
  // Encontra ou cria o InventoryItem, incrementa quantidade e registra
  // a movimentação com purchaseId para rastreabilidade bidirecional.

  Future<void> processPurchaseDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    final normalizedName = purchase.itemName.trim().toLowerCase();

    final existing = await _firestore
        .collection(_col)
        .where('name_normalized', isEqualTo: normalizedName)
        .limit(1)
        .get();

    final batch = _firestore.batch();
    late String itemId;

    if (existing.docs.isNotEmpty) {
      final doc    = existing.docs.first;
      itemId       = doc.id;
      final curQty = (doc.data()['quantity'] ?? 0.0).toDouble();

      batch.update(doc.reference, {
        'quantity':       curQty + purchase.quantity,
        'lastEntryDate':  FieldValue.serverTimestamp(),
        'updatedAt':      FieldValue.serverTimestamp(),
        'lastPurchaseId': purchase.id,
      });
    } else {
      final newRef = _firestore.collection(_col).doc();
      itemId = newRef.id;

      batch.set(newRef, {
        'id':              newRef.id,
        'name':            purchase.itemName,
        'name_normalized': normalizedName,
        'unit':            'un',
        'quantity':        purchase.quantity,
        'minQuantity':     5.0,
        'lastEntryDate':   FieldValue.serverTimestamp(),
        'lastPurchaseId':  purchase.id,
        'createdAt':       FieldValue.serverTimestamp(),
        'updatedAt':       FieldValue.serverTimestamp(),
      });
    }

    final movRef  = _firestore.collection(_history).doc();
    final movement = InventoryMovement(
      id:          movRef.id,
      itemId:      itemId,
      itemName:    purchase.itemName,
      quantity:    purchase.quantity,
      type:        InventoryMovementType.inbound,
      projectId:   purchase.projectId.isNotEmpty ? purchase.projectId : null,
      projectName: purchase.projectName.isNotEmpty ? purchase.projectName : null,
      purchaseId:  purchase.id,
      date:        DateTime.now(),
      notes:       'Entrada automática — compra #${purchase.id}',
      userId:      receivedBy,
    );

    batch.set(movRef, movement.toMap());
    await batch.commit();
  }

  // ─── Saída manual ────────────────────────────────────────────────────────

  Future<void> addOutboundMovement({
    required String itemId,
    required String itemName,
    required double quantity,
    required String userId,
    String? projectId,
    String? projectName,
    String? notes,
  }) async {
    await _firestore.runTransaction((tx) async {
      final itemRef = _firestore.collection(_col).doc(itemId);
      final itemDoc = await tx.get(itemRef);

      if (!itemDoc.exists) throw Exception('Item não encontrado no estoque.');

      final curQty = (itemDoc.data()?['quantity'] ?? 0.0).toDouble();
      if (curQty < quantity) {
        throw Exception(
            'Saldo insuficiente. Disponível: $curQty, solicitado: $quantity');
      }

      tx.update(itemRef, {
        'quantity':  curQty - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final movRef   = _firestore.collection(_history).doc();
      final movement = InventoryMovement(
        id:          movRef.id,
        itemId:      itemId,
        itemName:    itemName,
        quantity:    quantity,
        type:        InventoryMovementType.outbound,
        projectId:   projectId,
        projectName: projectName,
        date:        DateTime.now(),
        notes:       notes,
        userId:      userId,
      );
      tx.set(movRef, movement.toMap());
    });
  }

  // ─── Ajuste manual (contagem física) ────────────────────────────────────

  Future<void> addAdjustment({
    required String itemId,
    required String itemName,
    required double newQuantity,
    required String userId,
    String? notes,
  }) async {
    await _firestore.runTransaction((tx) async {
      final itemRef = _firestore.collection(_col).doc(itemId);
      final itemDoc = await tx.get(itemRef);

      if (!itemDoc.exists) throw Exception('Item não encontrado.');

      final oldQty = (itemDoc.data()?['quantity'] ?? 0.0).toDouble();
      final diff   = newQuantity - oldQty;

      tx.update(itemRef, {
        'quantity':  newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final movRef   = _firestore.collection(_history).doc();
      final movement = InventoryMovement(
        id:       movRef.id,
        itemId:   itemId,
        itemName: itemName,
        quantity: diff.abs(),
        type:     InventoryMovementType.adjustment,
        date:     DateTime.now(),
        notes:    notes ?? 'Ajuste: ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)}',
        userId:   userId,
      );
      tx.set(movRef, movement.toMap());
    });
  }

  // ─── Genérico (mantido para compatibilidade) ─────────────────────────────

  Future<void> addMovement(InventoryMovement movement) async {
    await _firestore.runTransaction((tx) async {
      final itemRef = _firestore.collection(_col).doc(movement.itemId);
      final itemDoc = await tx.get(itemRef);

      if (!itemDoc.exists) throw Exception('Item não encontrado.');

      final curQty = (itemDoc.data()?['quantity'] ?? 0.0).toDouble();

      if (!movement.type.isIncrease && curQty < movement.quantity) {
        throw Exception('Saldo insuficiente. Disponível: $curQty');
      }

      final newQty = movement.type.isIncrease
          ? curQty + movement.quantity
          : curQty - movement.quantity;

      tx.update(itemRef, {
        'quantity':  newQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final movRef = _firestore.collection(_history).doc();
      tx.set(movRef, movement.toMap());
    });
  }

  // ─── Pontuais ────────────────────────────────────────────────────────────

  Future<InventoryItem?> getItemById(String id) async {
    final doc = await _firestore.collection(_col).doc(id).get();
    if (!doc.exists) return null;
    return InventoryItem.fromMap(doc.id, doc.data()!);
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final snap = await _firestore.collection(_col).get();
    return snap.docs
        .map((d) => InventoryItem.fromMap(d.id, d.data()))
        .where((i) => i.isLowStock)
        .toList();
  }
}