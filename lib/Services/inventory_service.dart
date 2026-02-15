import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';

// DTO para entrada de compras
class PurchaseItemDto {
  final String name;
  final double quantity;
  final String unit;

  PurchaseItemDto({required this.name, required this.quantity, required this.unit});
}

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'inventory';
  final String _historyCollection = 'inventory_movements';

  // ==============================================================================
  // 1. ENTRADA AUTOMÁTICA (Compras -> Estoque)
  // ==============================================================================
  
  Future<void> processPurchaseArrival(List<PurchaseItemDto> items) async {
    final batch = _firestore.batch();

    try {
      for (final item in items) {
        final normalizedName = item.name.trim().toLowerCase();

        final querySnapshot = await _firestore
            .collection(_collection)
            .where('name_normalized', isEqualTo: normalizedName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Atualiza existente
          final doc = querySnapshot.docs.first;
          final currentQty = (doc.data()['quantity'] ?? 0).toDouble();
          
          batch.update(doc.reference, {
            'quantity': currentQty + item.quantity,
            'lastEntryDate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Cria novo
          final newDocRef = _firestore.collection(_collection).doc();
          batch.set(newDocRef, {
            'name': item.name,
            'name_normalized': normalizedName,
            'unit': item.unit,
            'quantity': item.quantity,
            'minQuantity': 5.0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao processar entrada de estoque: $e');
    }
  }

  // ==============================================================================
  // 2. MOVIMENTAÇÕES
  // ==============================================================================

  /// Adiciona uma movimentação e atualiza o saldo do item
  Future<void> addMovement(InventoryMovement movement) async {
    return _firestore.runTransaction((transaction) async {
      // 1. Buscar o item para verificar saldo atual
      final itemRef = _firestore.collection(_collection).doc(movement.itemId);
      final itemDoc = await transaction.get(itemRef);

      if (!itemDoc.exists) {
        throw Exception("Item não encontrado no estoque.");
      }

      final currentQty = (itemDoc.data()?['quantity'] ?? 0).toDouble();

      // 2. Validar se há saldo suficiente para saídas
      if (movement.type == InventoryMovementType.outbound || movement.type == InventoryMovementType.transfer) {
        if (currentQty < movement.quantity) {
          throw Exception("Saldo insuficiente. Disponível: $currentQty");
        }
      }

      // 3. Calcular novo saldo (Saída/Transferência diminui)
      double newQty = currentQty;
      if (movement.type == InventoryMovementType.outbound || movement.type == InventoryMovementType.transfer) {
        newQty -= movement.quantity;
      } else {
        // Se for entrada ou ajuste positivo, soma (lógica básica, ajuste conforme necessidade)
        newQty += movement.quantity;
      }
      
      // 4. Atualizar saldo do item
      transaction.update(itemRef, {
        'quantity': newQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Registrar o histórico da movimentação
      final movementRef = _firestore.collection(_historyCollection).doc();
      transaction.set(movementRef, movement.toMap());
    });
  }

  // ==============================================================================
  // 3. LEITURA
  // ==============================================================================

  Stream<List<InventoryItem>> getInventoryStream() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => InventoryItem.fromMap(doc.id, doc.data())).toList();
    });
  }
}