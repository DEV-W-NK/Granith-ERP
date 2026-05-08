import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/sector_model.dart';

class SectorService {
  static const _collection = 'sectors';

  Stream<List<SectorModel>> getSectors() {
    return AppSupabase.client
        .from(_collection)
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => SectorModel.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id'] as String,
                    ),
                  )
                  .toList(),
        );
  }

  Future<String> saveSector(SectorModel sector) async {
    final data = DbValue.normalizeMap(
      sector.copyWith(updatedAt: DateTime.now()).toMap(),
    );

    if (sector.id.isEmpty) {
      final row =
          await AppSupabase.client
              .from(_collection)
              .insert(data)
              .select('id')
              .single();
      return row['id'] as String;
    }

    await AppSupabase.client.from(_collection).update(data).eq('id', sector.id);
    return sector.id;
  }
}
