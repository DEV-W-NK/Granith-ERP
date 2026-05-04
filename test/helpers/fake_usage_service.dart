import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/services/usage_service.dart';

class FakeUsageService extends UsageService {
  UsageStatsModel? currentUsage;
  Object? getCurrentUsageError;
  Object? syncError;
  Map<String, dynamic> syncResponse = const {
    'message': 'Uso sincronizado com sucesso.',
  };
  int getCurrentUsageCalls = 0;
  final List<String> syncIntervals = <String>[];

  @override
  Future<UsageStatsModel> getCurrentUsage() async {
    getCurrentUsageCalls += 1;
    if (getCurrentUsageError != null) {
      throw getCurrentUsageError!;
    }
    return currentUsage!;
  }

  @override
  Future<Map<String, dynamic>> syncCurrentUsage({
    String interval = '24h',
  }) async {
    syncIntervals.add(interval);
    if (syncError != null) {
      throw syncError!;
    }
    return syncResponse;
  }
}
