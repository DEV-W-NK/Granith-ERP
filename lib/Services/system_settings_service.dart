import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/system_settings_model.dart';

class SystemSettingsService {
  static const String _table = 'system_settings';
  static const String _primaryId = 'default';

  Future<SystemSettings> fetchSettings() async {
    final response = await AppSupabase.client
        .from(_table)
        .select()
        .eq('id', _primaryId)
        .maybeSingle();

    if (response == null) {
      return const SystemSettings();
    }

    return SystemSettings.fromMap(Map<String, dynamic>.from(response));
  }

  Future<SystemSettings> saveSettings(SystemSettings settings) async {
    final payload = DbValue.normalizeMap({
      ...settings.toMap(),
      'id': _primaryId,
      'updated_at': DateTime.now().toUtc(),
    });

    final response = await AppSupabase.client
        .from(_table)
        .upsert(payload)
        .select()
        .single();

    return SystemSettings.fromMap(Map<String, dynamic>.from(response));
  }
}
