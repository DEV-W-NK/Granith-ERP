import 'package:project_granith/core/config/supabase_config.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef UsageRowFetcher =
    Future<Map<String, dynamic>?> Function(String documentId);
typedef UsageSyncInvoker =
    Future<Map<String, dynamic>> Function(String interval);

class UsageService {
  UsageService({
    UsageRowFetcher? fetchUsageRow,
    UsageSyncInvoker? syncUsage,
    DateTime Function()? nowProvider,
    String? projectRefOverride,
  }) : _fetchUsageRow = fetchUsageRow ?? _defaultFetchUsageRow,
       _syncUsage = syncUsage ?? _defaultSyncUsage,
       _nowProvider = nowProvider ?? DateTime.now,
       _projectRefOverride = projectRefOverride;

  final UsageRowFetcher _fetchUsageRow;
  final UsageSyncInvoker _syncUsage;
  final DateTime Function() _nowProvider;
  final String? _projectRefOverride;

  Future<UsageStatsModel> getCurrentUsage() async {
    try {
      final now = _nowProvider();
      final projectRef = _projectRefFromUrl;
      final docId = '${projectRef}_${now.toUtc().month}_${now.toUtc().year}';
      final row = await _fetchUsageRow(docId);

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
      return await _syncUsage(interval);
    } on FunctionException catch (error) {
      throw Exception(
        'Falha ao sincronizar uso do Supabase: ${error.details ?? error.reasonPhrase ?? error.toString()}',
      );
    } catch (e) {
      throw Exception('Falha ao sincronizar uso do Supabase: $e');
    }
  }

  String get _projectRefFromUrl {
    if (_projectRefOverride != null && _projectRefOverride.trim().isNotEmpty) {
      return _projectRefOverride.trim();
    }

    if (SupabaseConfig.url.isEmpty) {
      return 'granith';
    }

    final uri = Uri.tryParse(SupabaseConfig.url);
    if (uri == null || uri.host.isEmpty) {
      return 'granith';
    }

    return uri.host.split('.').first;
  }

  static Future<Map<String, dynamic>?> _defaultFetchUsageRow(
    String documentId,
  ) async {
    final row =
        await AppSupabase.client
            .from('usage_stats')
            .select()
            .eq('id', documentId)
            .maybeSingle();

    if (row == null) {
      return null;
    }

    return Map<String, dynamic>.from(row);
  }

  static Future<Map<String, dynamic>> _defaultSyncUsage(String interval) async {
    final response = await AppSupabase.client.functions.invoke(
      'sync_usage_stats',
      body: {'interval': interval},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Resposta inesperada da sincronizacao de uso.');
  }
}
