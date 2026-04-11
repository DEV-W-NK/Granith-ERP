import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/job_role_model.dart';

class JobRoleService {
  static const _collection = 'job_roles';

  Stream<List<JobRoleModel>> getJobRoles() {
    return AppSupabase.client
        .from(_collection)
        .stream(primaryKey: ['id'])
        .order('title')
        .map((rows) => rows
            .map((row) => JobRoleModel.fromMap(
                  Map<String, dynamic>.from(row),
                  row['id'] as String,
                ))
            .toList());
  }

  Future<void> saveJobRole(JobRoleModel role) async {
    if (role.id.isEmpty) {
      await AppSupabase.client
          .from(_collection)
          .insert(DbValue.normalizeMap(role.toMap()));
    } else {
      await AppSupabase.client
          .from(_collection)
          .update(DbValue.normalizeMap(role.toMap()))
          .eq('id', role.id);
    }
  }

  Future<void> deleteJobRole(String id) async {
    await AppSupabase.client.from(_collection).delete().eq('id', id);
  }
}
