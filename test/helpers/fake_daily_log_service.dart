import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/services/daily_log_service.dart';

class FakeDailyLogService extends DailyLogService {
  FakeDailyLogService() : super(authService: AuthService());

  List<DailyLogModel> nextLogs = <DailyLogModel>[];
  Object? recentLogsError;
  Object? signLogError;
  DailyLogModel? lastSavedLog;
  DailyLogModel? lastSignedLog;

  @override
  Future<void> saveLog(DailyLogModel log) async {
    lastSavedLog = log;
  }

  @override
  Future<List<DailyLogModel>> getRecentLogs({int limit = 20}) async {
    if (recentLogsError != null) {
      throw recentLogsError!;
    }
    return List<DailyLogModel>.from(nextLogs);
  }

  @override
  Future<void> signLogAsCurrentCoordinator(DailyLogModel log) async {
    if (signLogError != null) {
      throw signLogError!;
    }
    lastSignedLog = log;
  }

  @override
  Future<List<DailyLogModel>> getSignedLogsForProjects(
    Iterable<String> projectIds, {
    int limit = 100,
  }) async {
    final ids = projectIds.toSet();
    return nextLogs
        .where((log) => ids.contains(log.projectId) && log.isSigned)
        .take(limit)
        .toList();
  }
}
