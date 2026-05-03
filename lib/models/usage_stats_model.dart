import 'package:project_granith/core/data/db_value.dart';

class UsageStatsModel {
  final String tenantId;
  final String projectRef;
  final int totalReads;
  final int totalWrites;
  final int totalApiRequests;
  final int totalRestRequests;
  final int totalAuthRequests;
  final int totalStorageRequests;
  final int totalRealtimeRequests;
  final double databaseUsedMB;
  final double storageUsedMB;
  final int aiRequests;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, int> dailyOperations;
  final int peakDayOperations;
  final bool hasSnapshot;
  final String sourceLabel;
  final DateTime? lastSyncedAt;

  const UsageStatsModel({
    required this.tenantId,
    this.projectRef = '',
    this.totalReads = 0,
    this.totalWrites = 0,
    this.totalApiRequests = 0,
    this.totalRestRequests = 0,
    this.totalAuthRequests = 0,
    this.totalStorageRequests = 0,
    this.totalRealtimeRequests = 0,
    this.databaseUsedMB = 0,
    this.storageUsedMB = 0,
    this.aiRequests = 0,
    required this.periodStart,
    required this.periodEnd,
    this.dailyOperations = const {},
    this.peakDayOperations = 0,
    this.hasSnapshot = false,
    this.sourceLabel = 'Sem snapshot sincronizado',
    this.lastSyncedAt,
  });

  int get observedOperations {
    if (totalApiRequests > 0) {
      return totalApiRequests;
    }
    return totalReads + totalWrites;
  }

  double get storageUsedGB => storageUsedMB / 1024;

  double get databaseUsedGB => databaseUsedMB / 1024;

  bool get hasUsageData =>
      totalApiRequests > 0 ||
      totalReads > 0 ||
      totalWrites > 0 ||
      storageUsedMB > 0 ||
      databaseUsedMB > 0 ||
      aiRequests > 0;

  double get averageDailyOperations {
    if (dailyOperations.isEmpty) return 0;
    final total = dailyOperations.values.reduce((a, b) => a + b);
    return total / dailyOperations.length;
  }

  factory UsageStatsModel.fromMap(Map<String, dynamic> map) {
    final dailyOps = <String, int>{};
    final rawDailyOperations = map['dailyOperations'];

    if (rawDailyOperations is Map) {
      for (final entry in rawDailyOperations.entries) {
        final value = entry.value;
        if (value is num) {
          dailyOps[entry.key.toString()] = value.toInt();
        }
      }
    }

    final peakOps = dailyOps.isEmpty
        ? 0
        : dailyOps.values.reduce((a, b) => a > b ? a : b);

    return UsageStatsModel(
      tenantId: map['tenantId']?.toString() ?? '',
      projectRef: map['projectRef']?.toString() ?? '',
      totalReads: map['totalReads']?.toInt() ?? 0,
      totalWrites: map['totalWrites']?.toInt() ?? 0,
      totalApiRequests: map['totalApiRequests']?.toInt() ?? 0,
      totalRestRequests: map['totalRestRequests']?.toInt() ?? 0,
      totalAuthRequests: map['totalAuthRequests']?.toInt() ?? 0,
      totalStorageRequests: map['totalStorageRequests']?.toInt() ?? 0,
      totalRealtimeRequests: map['totalRealtimeRequests']?.toInt() ?? 0,
      databaseUsedMB: (map['databaseUsedMB'] ?? 0).toDouble(),
      storageUsedMB: (map['storageUsedMB'] ?? 0).toDouble(),
      aiRequests: map['aiRequests']?.toInt() ?? 0,
      periodStart: DbValue.toDateTime(map['periodStart']) ?? DateTime.now(),
      periodEnd: DbValue.toDateTime(map['periodEnd']) ?? DateTime.now(),
      dailyOperations: dailyOps,
      peakDayOperations: peakOps,
      hasSnapshot: true,
      sourceLabel:
          map['sourceLabel']?.toString() ?? 'Snapshot interno do ERP',
      lastSyncedAt: DbValue.toDateTime(map['lastSyncedAt']),
    );
  }
}
