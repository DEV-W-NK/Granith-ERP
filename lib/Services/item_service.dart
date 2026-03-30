import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore;
  final String _collection = 'items';

  ItemService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _itemsRef => _firestore.collection(_collection);

  // Criar Item
  Future<String> addItem(Item item) async {
    try {
      final docRef = await _itemsRef.add(item.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar item: $e');
    }
  }

  // Atualizar Item
  Future<void> updateItem(Item item) async {
    try {
      await _itemsRef.doc(item.id).update(
        item.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar item: $e');
    }
  }

  // Deletar Item
  Future<void> deleteItem(String id) async {
    try {
      await _itemsRef.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar item: $e');
    }
  }

  // Stream de Itens (Tempo Real)
  Stream<List<Item>> getItemsStream() {
    return _itemsRef
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Buscar itens por nome (para pesquisa)
  Future<List<Item>> searchItems(String query) async {
    final snapshot = await _itemsRef
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
        
    return snapshot.docs
        .map((doc) => Item.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}