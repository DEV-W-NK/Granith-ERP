import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/models/usage_stats_model.dart';

import '../helpers/fake_usage_service.dart';

UsageStatsModel _usage({
  int totalApiRequests = 1200,
  String sourceLabel = 'Snapshot oficial',
}) {
  return UsageStatsModel(
    tenantId: 'granith',
    projectRef: 'test-project-ref',
    totalApiRequests: totalApiRequests,
    periodStart: DateTime(2026, 5, 1),
    periodEnd: DateTime(2026, 5, 3),
    sourceLabel: sourceLabel,
    lastSyncedAt: DateTime(2026, 5, 3, 10),
    hasSnapshot: true,
  );
}

void main() {
  group('SubscriptionController', () {
    test('loadUsageData carrega snapshot e limpa feedback', () async {
      final usageService = FakeUsageService()..currentUsage = _usage();
      final controller = SubscriptionController(usageService: usageService);

      await controller.loadUsageData();

      expect(controller.isLoading, isFalse);
      expect(controller.feedbackMessage, isNull);
      expect(controller.currentUsage?.projectRef, 'test-project-ref');
    });

    test('loadUsageData expõe mensagem amigavel quando falha', () async {
      final usageService =
          FakeUsageService()..getCurrentUsageError = Exception('network');
      final controller = SubscriptionController(usageService: usageService);

      await controller.loadUsageData();

      expect(controller.isLoading, isFalse);
      expect(
        controller.feedbackMessage,
        'Nao foi possivel carregar o snapshot de uso.',
      );
    });

    test('syncUsageData atualiza snapshot, feedback e intervalo', () async {
      final usageService =
          FakeUsageService()
            ..currentUsage = _usage(totalApiRequests: 500)
            ..syncResponse = const {'message': 'Dados sincronizados agora.'};
      final controller = SubscriptionController(usageService: usageService);

      final result = await controller.syncUsageData(interval: '7d');

      expect(result, isTrue);
      expect(controller.isSyncing, isFalse);
      expect(controller.feedbackMessage, 'Dados sincronizados agora.');
      expect(controller.currentUsage?.observedOperations, 500);
      expect(usageService.syncIntervals, ['7d']);
      expect(usageService.getCurrentUsageCalls, 1);
    });

    test('syncUsageData devolve falso e remove prefixo de exception', () async {
      final usageService =
          FakeUsageService()
            ..currentUsage = _usage()
            ..syncError = Exception(
              'Falha ao sincronizar uso do Supabase: timeout',
            );
      final controller = SubscriptionController(usageService: usageService);

      final result = await controller.syncUsageData();

      expect(result, isFalse);
      expect(controller.isSyncing, isFalse);
      expect(
        controller.feedbackMessage,
        'Falha ao sincronizar uso do Supabase: timeout',
      );
    });
  });
}
