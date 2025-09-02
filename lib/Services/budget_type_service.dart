import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/budget_type.dart';

class BudgetTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'budget_types';

  // Obter referência da coleção
  CollectionReference get _budgetTypesRef => _firestore.collection(_collection);

  // Criar novo tipo de orçamento
  Future<String> createBudgetType(BudgetType budgetType) async {
    try {
      final docRef = await _budgetTypesRef.add(budgetType.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar tipo de orçamento: $e');
    }
  }

  // Atualizar tipo de orçamento
  Future<void> updateBudgetType(BudgetType budgetType) async {
    try {
      await _budgetTypesRef.doc(budgetType.id).update(
        budgetType.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar tipo de orçamento: $e');
    }
  }

  // Deletar tipo de orçamento
  Future<void> deleteBudgetType(String id) async {
    try {
      await _budgetTypesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar tipo de orçamento: $e');
    }
  }

  // Obter todos os tipos de orçamento
  Future<List<BudgetType>> getBudgetTypes() async {
    try {
      final querySnapshot = await _budgetTypesRef
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => BudgetType.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tipos de orçamento: $e');
    }
  }

  // Obter tipos de orçamento ativos
  Future<List<BudgetType>> getActiveBudgetTypes() async {
    try {
      final querySnapshot = await _budgetTypesRef
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => BudgetType.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tipos de orçamento ativos: $e');
    }
  }

  // Obter tipos de orçamento por categoria
  Future<List<BudgetType>> getBudgetTypesByCategory(String category) async {
    try {
      final querySnapshot = await _budgetTypesRef
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => BudgetType.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tipos de orçamento por categoria: $e');
    }
  }

  // Obter um tipo de orçamento por ID
  Future<BudgetType?> getBudgetTypeById(String id) async {
    try {
      final docSnapshot = await _budgetTypesRef.doc(id).get();
      
      if (docSnapshot.exists) {
        return BudgetType.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar tipo de orçamento: $e');
    }
  }

  // Stream de tipos de orçamento (para atualizações em tempo real)
  Stream<List<BudgetType>> budgetTypesStream() {
    return _budgetTypesRef
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetType.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // Verificar se nome já existe
  Future<bool> budgetTypeNameExists(String name, {String? excludeId}) async {
    try {
      Query query = _budgetTypesRef.where('name', isEqualTo: name);
      
      final querySnapshot = await query.get();
      
      if (excludeId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar nome: $e');
    }
  }

  // Ativar/Desativar tipo de orçamento
  Future<void> toggleBudgetTypeStatus(String id, bool isActive) async {
    try {
      await _budgetTypesRef.doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erro ao alterar status: $e');
    }
  }
}