import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/subscription/subscription_dashboard.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_usage_service.dart';

Widget _buildHarness({
  required AuthViewModel auth,
  required SubscriptionController controller,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: controller),
    ],
    child: const MaterialApp(home: SubscriptionDashboard()),
  );
}

UsageStatsModel _usage({
  bool hasSnapshot = true,
  String sourceLabel = 'Snapshot oficial',
}) {
  return UsageStatsModel(
    tenantId: 'granith',
    projectRef: 'test-project-ref',
    totalApiRequests: 1600,
    databaseUsedMB: 2048,
    storageUsedMB: 512,
    periodStart: DateTime(2026, 5, 1),
    periodEnd: DateTime(2026, 5, 3),
    sourceLabel: sourceLabel,
    lastSyncedAt: DateTime(2026, 5, 3, 12, 15),
    dailyOperations: const {
      '2026-05-01': 300,
      '2026-05-02': 700,
      '2026-05-03': 600,
    },
    hasSnapshot: hasSnapshot,
  );
}

void main() {
  group('SubscriptionDashboard', () {
    testWidgets(
      'renderiza leitura simples e permite sincronizacao para admin',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1440, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authService = FakeAuthService(
          currentUserValue: const FakeAuthUser('admin-1', 'admin@granith.com'),
          profile: const UserModel(
            uid: 'admin-1',
            email: 'admin@granith.com',
            role: UserRole.admin,
          ),
        );
        final usageService = FakeUsageService()..currentUsage = _usage();
        final auth = AuthViewModel(service: authService);
        final controller = SubscriptionController(usageService: usageService);

        await tester.pumpWidget(
          _buildHarness(auth: auth, controller: controller),
        );
        await tester.pumpAndSettle();

        expect(find.text('Uso da Plataforma'), findsOneWidget);
        expect(find.text('Visao simples do uso do sistema'), findsOneWidget);
        expect(find.text('Atividade do sistema'), findsOneWidget);
        expect(find.text('Atualizar dados'), findsOneWidget);

        await tester.tap(find.text('Atualizar dados'));
        await tester.pumpAndSettle();

        expect(usageService.syncIntervals, ['24h']);
        expect(find.text('Uso sincronizado com sucesso.'), findsOneWidget);
        await authService.dispose();
      },
    );

    testWidgets('oculta botao de sincronizacao para usuario sem permissao', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('user-1', 'user@granith.com'),
        profile: const UserModel(
          uid: 'user-1',
          email: 'user@granith.com',
          role: UserRole.employee,
        ),
      );
      final usageService =
          FakeUsageService()
            ..currentUsage = _usage(
              hasSnapshot: false,
              sourceLabel: 'Aguardando primeira sincronizacao',
            );
      final auth = AuthViewModel(service: authService);
      final controller = SubscriptionController(usageService: usageService);

      await tester.pumpWidget(
        _buildHarness(auth: auth, controller: controller),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atualizar dados'), findsNothing);
      expect(find.text('Primeira sincronizacao pendente'), findsOneWidget);
      await authService.dispose();
    });
  });
}
