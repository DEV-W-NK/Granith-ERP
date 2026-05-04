import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/usage_stats_model.dart';

void main() {
  group('UsageStatsModel', () {
    test('fromMap calcula pico diario e propriedades derivadas', () {
      final usage = UsageStatsModel.fromMap({
        'tenantId': 'granith',
        'projectRef': 'abc123',
        'totalReads': 10,
        'totalWrites': 5,
        'totalApiRequests': 40,
        'databaseUsedMB': 512,
        'storageUsedMB': 1024,
        'aiRequests': 3,
        'periodStart': '2026-05-01T00:00:00Z',
        'periodEnd': '2026-05-03T12:00:00Z',
        'dailyOperations': {
          '2026-05-01': 12,
          '2026-05-02': 18,
          '2026-05-03': 10,
        },
        'sourceLabel': 'Snapshot oficial',
        'lastSyncedAt': '2026-05-03T12:30:00Z',
      });

      expect(usage.projectRef, 'abc123');
      expect(usage.peakDayOperations, 18);
      expect(usage.observedOperations, 40);
      expect(usage.averageDailyOperations, 40 / 3);
      expect(usage.databaseUsedGB, 0.5);
      expect(usage.storageUsedGB, 1);
      expect(usage.hasUsageData, isTrue);
      expect(usage.sourceLabel, 'Snapshot oficial');
    });

    test(
      'fallback de observedOperations usa reads+writes quando api requests zerado',
      () {
        final usage = UsageStatsModel(
          tenantId: 'granith',
          periodStart: DateTime(2026, 5, 1),
          periodEnd: DateTime(2026, 5, 2),
          totalReads: 6,
          totalWrites: 4,
        );

        expect(usage.observedOperations, 10);
        expect(usage.hasUsageData, isTrue);
      },
    );
  });
}
