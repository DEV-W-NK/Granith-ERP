import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/usage_stats_model.dart';

class UsageService {
  Future<UsageStatsModel> getCurrentUsage(String tenantId) async {
    try {
      final docId = '${tenantId}_${DateTime.now().month}_${DateTime.now().year}';
      final row = await AppSupabase.client
          .from('usage_stats')
          .select()
          .eq('id', docId)
          .maybeSingle();

      if (row != null) {
        return UsageStatsModel.fromMap(Map<String, dynamic>.from(row));
      }

      await Future.delayed(const Duration(milliseconds: 800));
      return UsageStatsModel(
        tenantId: tenantId,
        totalReads: 45200,
        totalWrites: 1250,
        storageUsedMB: 450.5,
        aiRequests: 12,
        periodStart: DateTime(DateTime.now().year, DateTime.now().month, 1),
        periodEnd: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erro ao buscar dados de consumo: $e');
    }
  }
}
