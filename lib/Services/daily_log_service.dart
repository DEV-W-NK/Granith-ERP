import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/auth_service.dart';

class DailyLogService {
  static const _table = 'daily_logs';

  final AuthService _authService;

  DailyLogService({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<void> saveLog(DailyLogModel log) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final user = _authService.currentUser;
      final data = DbValue.normalizeMap({
        ...log.toMap(),
        if (log.createdByUserId.isEmpty && user != null)
          'createdByUserId': user.id,
        'updatedAt': now,
      });

      if (log.id.isEmpty) {
        await AppSupabase.client.from(_table).insert({
          ...data,
          'createdAt': now,
        });
      } else {
        await AppSupabase.client.from(_table).update(data).eq('id', log.id);
      }
    } catch (e) {
      throw Exception('Erro ao salvar diario: $e');
    }
  }

  Future<void> signLog(
    DailyLogModel log, {
    String? signedByCoordinatorId,
    String? signedByCoordinatorName,
  }) async {
    if (log.id.trim().isEmpty) {
      throw Exception('ID do diario e obrigatorio para assinatura');
    }

    try {
      final now = DateTime.now().toUtc();
      final data = DbValue.normalizeMap({
        'status': LogStatus.signed.name,
        'signedAt': now,
        'signedByCoordinatorId': signedByCoordinatorId ?? log.coordinatorId,
        'signedByCoordinatorName':
            signedByCoordinatorName ?? log.coordinatorName,
        'updatedAt': now,
      });

      await AppSupabase.client.from(_table).update(data).eq('id', log.id);
    } catch (e) {
      throw Exception('Erro ao assinar diario: $e');
    }
  }

  Future<List<DailyLogModel>> getRecentLogs({int limit = 20}) async {
    try {
      final response = await AppSupabase.client
          .from(_table)
          .select()
          .order('date', ascending: false)
          .limit(limit);

      return (response as List).map((row) => _fromRow(row as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<DailyLogModel>> watchByProject(String projectId) {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('projectId', projectId)
        .order('date', ascending: false)
        .map((rows) => rows.map((row) => _fromRow(row)).toList());
  }

  DailyLogModel _fromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return DailyLogModel.fromMap(data, data['id'] as String? ?? '');
  }
}
