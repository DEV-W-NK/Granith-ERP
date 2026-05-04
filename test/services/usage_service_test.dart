import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/services/usage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('UsageService', () {
    test(
      'getCurrentUsage devolve snapshot existente e injeta projectRef quando ausente',
      () async {
        final service = UsageService(
          projectRefOverride: 'granith-ref',
          nowProvider: () => DateTime.utc(2026, 5, 3, 10),
          fetchUsageRow: (docId) async {
            expect(docId, 'granith-ref_5_2026');
            return <String, dynamic>{
              'id': docId,
              'tenantId': 'granith-ref',
              'periodStart': '2026-05-01T00:00:00.000Z',
              'periodEnd': '2026-05-03T10:00:00.000Z',
              'sourceLabel': 'Snapshot oficial',
              'totalApiRequests': 91,
            };
          },
        );

        final result = await service.getCurrentUsage();

        expect(result, isA<UsageStatsModel>());
        expect(result.projectRef, 'granith-ref');
        expect(result.totalApiRequests, 91);
        expect(result.sourceLabel, 'Snapshot oficial');
      },
    );

    test(
      'getCurrentUsage devolve placeholder quando ainda nao existe snapshot',
      () async {
        final service = UsageService(
          projectRefOverride: 'granith-ref',
          nowProvider: () => DateTime.utc(2026, 5, 3, 10),
          fetchUsageRow: (_) async => null,
        );

        final result = await service.getCurrentUsage();

        expect(result.projectRef, 'granith-ref');
        expect(result.sourceLabel, 'Aguardando primeira sincronizacao');
        expect(result.periodStart, DateTime(2026, 5, 1));
      },
    );

    test('syncCurrentUsage devolve payload da edge function', () async {
      final service = UsageService(
        syncUsage: (interval) async {
          expect(interval, '7d');
          return <String, dynamic>{'status': 'ok', 'interval': interval};
        },
      );

      final result = await service.syncCurrentUsage(interval: '7d');

      expect(result, {'status': 'ok', 'interval': '7d'});
    });

    test(
      'syncCurrentUsage converte FunctionException em mensagem amigavel',
      () async {
        final service = UsageService(
          syncUsage: (_) async {
            throw const FunctionException(
              status: 500,
              details: 'timeout interno',
            );
          },
        );

        expect(
          () => service.syncCurrentUsage(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('timeout interno'),
            ),
          ),
        );
      },
    );
  });
}
