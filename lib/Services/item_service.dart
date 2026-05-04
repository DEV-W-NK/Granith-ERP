import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/item_model.dart';

class ItemService {
  final String _collection = 'items';

  Future<String> addItem(Item item) async {
    try {
      final response =
          await AppSupabase.client
              .from(_collection)
              .insert(DbValue.normalizeMap(item.toMap()))
              .select('id')
              .single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Erro ao adicionar item: $e');
    }
  }

  Future<void> updateItem(Item item) async {
    try {
      await AppSupabase.client
          .from(_collection)
          .update(
            DbValue.normalizeMap(
              item.copyWith(updatedAt: DateTime.now()).toMap(),
            ),
          )
          .eq('id', item.id);
    } catch (e) {
      throw Exception('Erro ao atualizar item: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await AppSupabase.client.from(_collection).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar item: $e');
    }
  }

  Stream<List<Item>> getItemsStream() {
    return AppSupabase.client
        .from(_collection)
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => Item.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id'] as String,
                    ),
                  )
                  .toList(),
        );
  }

  Future<List<Item>> searchItems(String query) async {
    final response = await AppSupabase.client
        .from(_collection)
        .select()
        .ilike('name', '$query%');

    return (response as List)
        .map(
          (row) => Item.fromMap(
            Map<String, dynamic>.from(row as Map),
            row['id'] as String,
          ),
        )
        .toList();
  }
}
