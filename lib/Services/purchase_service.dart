import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/purchase_model.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'purchases';

  CollectionReference get _purchasesRef => _firestore.collection(_collection);

  // Criar Compra
  Future<void> addPurchase(Purchase purchase) async {
    try {
      // Deixa o Firestore gerar o ID se não vier preenchido, ou usa doc().set se quiser ID manual
      if (purchase.id.isEmpty) {
        await _purchasesRef.add(purchase.toMap());
      } else {
        await _purchasesRef.doc(purchase.id).set(purchase.toMap());
      }
    } catch (e) {
      throw Exception('Erro ao registrar compra: $e');
    }
  }

  // Atualizar Compra
  Future<void> updatePurchase(Purchase purchase) async {
    try {
      await _purchasesRef.doc(purchase.id).update(purchase.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar compra: $e');
    }
  }

  // Deletar Compra
  Future<void> deletePurchase(String id) async {
    try {
      await _purchasesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar compra: $e');
    }
  }

  // Stream de Compras (Ordenado por data, mais recente primeiro)
  Stream<List<Purchase>> getPurchasesStream() {
    return _purchasesRef
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Purchase.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  
  // Atualizar Status
  Future<void> updateStatus(String id, PurchaseStatus status) async {
    await _purchasesRef.doc(id).update({'status': status.index});
  }
}