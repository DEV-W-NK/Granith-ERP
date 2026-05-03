import 'package:project_granith/core/config/supabase_config.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsageService {
  Future<UsageStatsModel> getCurrentUsage() async {
    try {
      final now = DateTime.now();
      final projectRef = _projectRefFromUrl;
      final docId = '${projectRef}_${now.toUtc().month}_${now.toUtc().year}';
      final row = await AppSupabase.client
          .from('usage_stats')
          .select()
          .eq('id', docId)
          .maybeSingle();

      if (row != null) {
        final mapped = Map<String, dynamic>.from(row);
        mapped.putIfAbsent('projectRef', () => projectRef);
        return UsageStatsModel.fromMap(mapped);
      }

      return UsageStatsModel(
        tenantId: projectRef,
        projectRef: projectRef,
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: now,
        sourceLabel: 'Aguardando primeira sincronizacao',
      );
    } catch (e) {
      throw Exception('Erro ao buscar dados de consumo: $e');
    }
  }

  Future<Map<String, dynamic>> syncCurrentUsage({
    String interval = '24h',
  }) async {
    try {
      final response = await AppSupabase.client.functions.invoke(
        'sync_usage_stats',
        body: {
          'interval': interval,
          'projectRef': _projectRefFromUrl,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw const FormatException(
        'Resposta inesperada da sincronizacao de uso.',
      );
    } on FunctionException catch (error) {
      throw Exception(
        'Falha ao sincronizar uso do Supabase: ${error.details ?? error.reasonPhrase ?? error.toString()}',
      );
    } catch (e) {
      throw Exception('Falha ao sincronizar uso do Supabase: $e');
    }
  }

  String get _projectRefFromUrl {
    if (SupabaseConfig.url.isEmpty) {
      return 'granith';
    }

    final uri = Uri.tryParse(SupabaseConfig.url);
    if (uri == null || uri.host.isEmpty) {
      return 'granith';
    }

    return uri.host.split('.').first;
  }
}
