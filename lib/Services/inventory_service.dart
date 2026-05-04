import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/models/purchase_model.dart';

class InventoryService {
  static const _table = 'inventory';
  static const _historyTable = 'inventory_movements';

  InventoryService();

  Stream<List<InventoryItem>> getInventoryStream() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(_inventoryFromRow).toList());
  }

  Stream<List<InventoryItem>> getLowStockStream() {
    return getInventoryStream().map(
      (items) => items.where((item) => item.isLowStock).toList(),
    );
  }

  Stream<List<InventoryMovement>> getMovementsStream({
    String? itemId,
    String? projectId,
    int limit = 50,
  }) {
    dynamic stream = AppSupabase.client
        .from(_historyTable)
        .stream(primaryKey: ['id']);

    if (itemId != null) {
      stream = stream.eq('itemId', itemId);
    }
    if (projectId != null) {
      stream = stream.eq('projectId', projectId);
    }

    return stream
        .order('date', ascending: false)
        .limit(limit)
        .map((rows) => (rows as List).map(_movementFromRow).toList());
  }

  Future<void> processPurchaseDelivery({
    required Purchase purchase,
    required String receivedBy,
  }) async {
    final now = DateTime.now();
    final normalizedName = purchase.itemName.trim().toLowerCase();
    final existing =
        await AppSupabase.client
            .from(_table)
            .select()
            .eq('name_normalized', normalizedName)
            .limit(1)
            .maybeSingle();

    late final String itemId;

    if (existing != null) {
      final row = Map<String, dynamic>.from(existing);
      itemId = row['id'] as String;
      final currentQuantity = (row['quantity'] as num? ?? 0).toDouble();

      await AppSupabase.client
          .from(_table)
          .update({
            'quantity': currentQuantity + purchase.quantity,
            'lastEntryDate': DbValue.toPrimitive(now),
            'updatedAt': DbValue.toPrimitive(now),
            'lastPurchaseId': purchase.id,
          })
          .eq('id', itemId);
    } else {
      final row =
          await AppSupabase.client
              .from(_table)
              .insert({
                'name': purchase.itemName,
                'name_normalized': normalizedName,
                'unit': 'un',
                'quantity': purchase.quantity,
                'minQuantity': 5.0,
                'lastEntryDate': DbValue.toPrimitive(now),
                'lastPurchaseId': purchase.id,
                'createdAt': DbValue.toPrimitive(now),
                'updatedAt': DbValue.toPrimitive(now),
              })
              .select('id')
              .single();

      itemId = row['id'] as String;
    }

    final movement = InventoryMovement(
      id: '',
      itemId: itemId,
      itemName: purchase.itemName,
      quantity: purchase.quantity,
      type: InventoryMovementType.inbound,
      projectId: purchase.projectId.isNotEmpty ? purchase.projectId : null,
      projectName:
          purchase.projectName.isNotEmpty ? purchase.projectName : null,
      purchaseId: purchase.id,
      date: now,
      notes: 'Entrada automatica - compra #${purchase.id}',
      userId: receivedBy,
    );

    await _insertMovement(movement);
  }

  Future<void> addOutboundMovement({
    required String itemId,
    required String itemName,
    required double quantity,
    required String userId,
    String? projectId,
    String? projectName,
    String? notes,
  }) async {
    final item = await getItemById(itemId);
    if (item == null) throw Exception('Item nao encontrado no estoque.');
    if (item.quantity < quantity) {
      throw Exception(
        'Saldo insuficiente. Disponivel: ${item.quantity}, solicitado: $quantity',
      );
    }

    final now = DateTime.now();
    await _updateItemQuantity(itemId, item.quantity - quantity, now);
    await _insertMovement(
      InventoryMovement(
        id: '',
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
        type: InventoryMovementType.outbound,
        projectId: projectId,
        projectName: projectName,
        date: now,
        notes: notes,
        userId: userId,
      ),
    );
  }

  Future<void> addAdjustment({
    required String itemId,
    required String itemName,
    required double newQuantity,
    required String userId,
    String? notes,
  }) async {
    final item = await getItemById(itemId);
    if (item == null) throw Exception('Item nao encontrado.');

    final now = DateTime.now();
    final diff = newQuantity - item.quantity;

    await _updateItemQuantity(itemId, newQuantity, now);
    await _insertMovement(
      InventoryMovement(
        id: '',
        itemId: itemId,
        itemName: itemName,
        quantity: diff.abs(),
        type: InventoryMovementType.adjustment,
        date: now,
        notes:
            notes ??
            'Ajuste: ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)}',
        userId: userId,
      ),
    );
  }

  Future<void> addMovement(InventoryMovement movement) async {
    final item = await getItemById(movement.itemId);
    if (item == null) throw Exception('Item nao encontrado.');

    if (!movement.type.isIncrease && item.quantity < movement.quantity) {
      throw Exception('Saldo insuficiente. Disponivel: ${item.quantity}');
    }

    final newQuantity =
        movement.type.isIncrease
            ? item.quantity + movement.quantity
            : item.quantity - movement.quantity;

    await _updateItemQuantity(movement.itemId, newQuantity, DateTime.now());
    await _insertMovement(movement);
  }

  Future<InventoryItem?> getItemById(String id) async {
    final row =
        await AppSupabase.client
            .from(_table)
            .select()
            .eq('id', id)
            .maybeSingle();
    if (row == null) return null;
    return _inventoryFromRow(Map<String, dynamic>.from(row));
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final response = await AppSupabase.client
        .from(_table)
        .select()
        .order('name');

    return (response as List)
        .map((row) => _inventoryFromRow(Map<String, dynamic>.from(row as Map)))
        .where((item) => item.isLowStock)
        .toList();
  }

  Future<void> _updateItemQuantity(
    String itemId,
    double quantity,
    DateTime updatedAt,
  ) async {
    await AppSupabase.client
        .from(_table)
        .update({
          'quantity': quantity,
          'updatedAt': DbValue.toPrimitive(updatedAt),
        })
        .eq('id', itemId);
  }

  Future<void> _insertMovement(InventoryMovement movement) async {
    final data = DbValue.normalizeMap(movement.toMap());
    if (movement.id.isNotEmpty) {
      data['id'] = movement.id;
    }
    await AppSupabase.client.from(_historyTable).insert(data);
  }

  InventoryItem _inventoryFromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return InventoryItem.fromMap(data['id'] as String? ?? '', data);
  }

  InventoryMovement _movementFromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row as Map);
    return InventoryMovement.fromMap(data, data['id'] as String? ?? '');
  }
}
