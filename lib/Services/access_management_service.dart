import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/user_model.dart';

class AccessManagementService {
  static const String _table = 'users';

  Future<List<UserModel>> getUsers() async {
    final response = await AppSupabase.client
        .from(_table)
        .select()
        .order('displayName', ascending: true);

    return (response as List).map((row) {
      final data = Map<String, dynamic>.from(row);
      return UserModel.fromMap(data, (data['id'] ?? '').toString());
    }).toList();
  }

  Future<void> updateUserAccess(UserModel user) async {
    final payload = DbValue.normalizeMap({
      ...user.toMap(),
      'id': user.uid,
      'updated_at': DateTime.now().toUtc(),
    });

    await AppSupabase.client.from(_table).upsert(payload);
  }
}
