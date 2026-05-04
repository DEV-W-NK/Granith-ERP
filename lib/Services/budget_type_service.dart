import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/budget_type.dart';

class BudgetTypeService {
  final String _collection = 'budget_types';

  Future<String> createBudgetType(BudgetType budgetType) async {
    try {
      final response =
          await AppSupabase.client
              .from(_collection)
              .insert(DbValue.normalizeMap(budgetType.toMap()))
              .select('id')
              .single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Erro ao criar tipo de orcamento: $e');
    }
  }

  Future<void> updateBudgetType(BudgetType budgetType) async {
    try {
      await AppSupabase.client
          .from(_collection)
          .update(
            DbValue.normalizeMap(
              budgetType.copyWith(updatedAt: DateTime.now()).toMap(),
            ),
          )
          .eq('id', budgetType.id);
    } catch (e) {
      throw Exception('Erro ao atualizar tipo de orcamento: $e');
    }
  }

  Future<void> deleteBudgetType(String id) async {
    try {
      await AppSupabase.client.from(_collection).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar tipo de orcamento: $e');
    }
  }

  Future<List<BudgetType>> getBudgetTypes() async {
    try {
      final response = await AppSupabase.client
          .from(_collection)
          .select()
          .order('name');

      return (response as List)
          .map(
            (row) => BudgetType.fromMap(
              Map<String, dynamic>.from(row as Map),
              row['id'] as String,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tipos de orcamento: $e');
    }
  }

  Future<List<BudgetType>> getActiveBudgetTypes() async {
    try {
      final response = await AppSupabase.client
          .from(_collection)
          .select()
          .eq('isActive', true)
          .order('name');

      return (response as List)
          .map(
            (row) => BudgetType.fromMap(
              Map<String, dynamic>.from(row as Map),
              row['id'] as String,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tipos de orcamento ativos: $e');
    }
  }

  Future<List<BudgetType>> getBudgetTypesByCategory(String category) async {
    try {
      final response = await AppSupabase.client
          .from(_collection)
          .select()
          .eq('category', category)
          .eq('isActive', true)
          .order('name');

      return (response as List)
          .map(
            (row) => BudgetType.fromMap(
              Map<String, dynamic>.from(row as Map),
              row['id'] as String,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tipos de orcamento por categoria: $e');
    }
  }

  Future<BudgetType?> getBudgetTypeById(String id) async {
    try {
      final row =
          await AppSupabase.client
              .from(_collection)
              .select()
              .eq('id', id)
              .maybeSingle();

      if (row == null) {
        return null;
      }

      return BudgetType.fromMap(Map<String, dynamic>.from(row), id);
    } catch (e) {
      throw Exception('Erro ao buscar tipo de orcamento: $e');
    }
  }

  Stream<List<BudgetType>> budgetTypesStream() {
    return AppSupabase.client
        .from(_collection)
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => BudgetType.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id'] as String,
                    ),
                  )
                  .toList(),
        );
  }

  Future<bool> budgetTypeNameExists(String name, {String? excludeId}) async {
    try {
      final response = await AppSupabase.client
          .from(_collection)
          .select('id')
          .eq('name', name);
      final rows = (response as List).cast<Map<String, dynamic>>();
      if (excludeId != null) {
        return rows.any((row) => row['id'] != excludeId);
      }
      return rows.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar nome: $e');
    }
  }

  Future<void> toggleBudgetTypeStatus(String id, bool isActive) async {
    try {
      await AppSupabase.client
          .from(_collection)
          .update({
            'isActive': isActive,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao alterar status: $e');
    }
  }
}
