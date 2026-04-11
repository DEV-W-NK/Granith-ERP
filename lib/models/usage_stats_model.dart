import 'package:project_granith/core/data/db_value.dart';

class UsageStatsModel {
  final String tenantId;
  final int totalReads;
  final int totalWrites;
  final double storageUsedMB;
  final int aiRequests;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, int> dailyOperations; // Operações por dia (formato: "2026-02-14": 1500)
  final int peakDayOperations; // Pico de operações em um dia

  static const double _costPer1kReads = 0.006;
  static const double _costPer1kWrites = 0.018;
  static const double _costPerGBStorage = 0.15;
  static const double _costPerAIRequest = 0.05;
  static const double _markupMultiplier = 3.5;

  UsageStatsModel({
    required this.tenantId,
    this.totalReads = 0,
    this.totalWrites = 0,
    this.storageUsedMB = 0,
    this.aiRequests = 0,
    required this.periodStart,
    required this.periodEnd,
    this.dailyOperations = const {},
    this.peakDayOperations = 0,
  });

  double get estimatedTechnicalCost {
    final readsCost = (totalReads / 1000) * _costPer1kReads;
    final writesCost = (totalWrites / 1000) * _costPer1kWrites;
    final storageCost = (storageUsedMB / 1024) * _costPerGBStorage;
    final aiCost = aiRequests * _costPerAIRequest;
    return readsCost + writesCost + storageCost + aiCost;
  }

  double get clientBillableAmount {
    const double baseFee = 49.90; 
    return baseFee + (estimatedTechnicalCost * _markupMultiplier);
  }

  double get grossProfit => clientBillableAmount - estimatedTechnicalCost;

  // Calcula média diária de operações
  double get averageDailyOperations {
    if (dailyOperations.isEmpty) return 0;
    int total = dailyOperations.values.reduce((a, b) => a + b);
    return total / dailyOperations.length;
  }

  factory UsageStatsModel.fromMap(Map<String, dynamic> map) {
    // Simula dados diários para demonstração
    final dailyOps = <String, int>{};
    final random = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = random.subtract(Duration(days: i));
      final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      dailyOps[dayKey] = (500 + (i * 200)) % 1500; // Dados variados
    }
    
    final peakOps = dailyOps.isEmpty ? 0 : dailyOps.values.reduce((a, b) => a > b ? a : b);

    return UsageStatsModel(
      tenantId: map['tenantId'] ?? '',
      totalReads: map['totalReads']?.toInt() ?? 0,
      totalWrites: map['totalWrites']?.toInt() ?? 0,
      storageUsedMB: (map['storageUsedMB'] ?? 0).toDouble(),
      aiRequests: map['aiRequests']?.toInt() ?? 0,
      periodStart: DbValue.toDateTime(map['periodStart']) ?? DateTime.now(),
      periodEnd: DbValue.toDateTime(map['periodEnd']) ?? DateTime.now(),
      dailyOperations: dailyOps,
      peakDayOperations: peakOps,
    );
  }
}
