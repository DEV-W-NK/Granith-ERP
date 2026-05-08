import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/services/client_portal_access_service.dart';

import '../helpers/fake_access_management_service.dart';
import '../helpers/fake_client_account_service.dart';
import '../helpers/fake_client_portal_access_service.dart';

Widget _buildHarness({
  required FakeAccessManagementService accessService,
  required FakeClientAccountService clientAccountService,
  required FakeClientPortalAccessService portalAccessService,
}) {
  return MaterialApp(
    home: AccessManagementPage(
      accessService: accessService,
      clientAccountService: clientAccountService,
      clientPortalAccessService: portalAccessService,
    ),
  );
}

void main() {
  group('AccessManagementPage', () {
    testWidgets('carrega usuarios, altera permissao, salva e mostra clientes', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final accessService = FakeAccessManagementService(
        users: const [
          UserModel(
            uid: 'user-1',
            email: 'gestor@granith.com',
            displayName: 'Gestor',
            permissions: ['projects.read', 'financeiro'],
            role: UserRole.admin,
          ),
        ],
      );
      final clientService = FakeClientAccountService(
        accounts: const [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Norte',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@granith.com',
            contactPhone: '11999990000',
            portalAccessStatus: ClientPortalAccessStatus.pending,
          ),
        ],
      );
      final portalService = FakeClientPortalAccessService();

      await tester.pumpWidget(
        _buildHarness(
          accessService: accessService,
          clientAccountService: clientService,
          portalAccessService: portalService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permissoes e Clientes'), findsOneWidget);
      expect(find.text('gestor@granith.com'), findsOneWidget);
      expect(find.text('Salvar acesso do usuario'), findsNothing);
      expect(find.text('Visualizar projetos'), findsOneWidget);
      expect(find.text('Visualizar salarios no RH'), findsOneWidget);
      expect(find.text('Financeiro'), findsOneWidget);
      expect(find.text('projects.read'), findsNothing);

      await tester.tap(find.text('Criar e editar projetos'));
      await tester.pumpAndSettle();
      expect(accessService.lastUpdatedUser, isNull);
      expect(find.text('Salvar acesso do usuario'), findsOneWidget);

      await tester.tap(find.text('Salvar acesso do usuario'));
      await tester.pumpAndSettle();

      expect(
        accessService.lastUpdatedUser?.permissions,
        contains('projects.write'),
      );
      expect(find.text('Salvar acesso do usuario'), findsNothing);

      await tester.tap(find.text('Clientes do portal'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente Norte'), findsOneWidget);
      expect(find.text('Enviar convite'), findsOneWidget);
    });

    testWidgets('salva cliente novo e envia convite no mesmo fluxo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final accessService = FakeAccessManagementService();
      final clientService = FakeClientAccountService();
      final portalService =
          FakeClientPortalAccessService()
            ..inviteResult = ClientPortalInviteResult(
              account: ClientAccount.empty().copyWith(
                id: 'client-generated',
                name: 'Cliente Atlas',
                ownerEmail: 'cliente@atlas.com',
                portalAccessStatus: ClientPortalAccessStatus.invited,
              ),
              message: 'Convite enviado para cliente@atlas.com.',
            );

      await tester.pumpWidget(
        _buildHarness(
          accessService: accessService,
          clientAccountService: clientService,
          portalAccessService: portalService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clientes do portal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadastrar cliente').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do cliente'),
        'Cliente Atlas',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail da conta do portal'),
        'cliente@atlas.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone'),
        '11999990000',
      );
      await tester.tap(find.text('Salvar e enviar convite'));
      await tester.pumpAndSettle();

      expect(clientService.lastSavedAccount?.name, 'Cliente Atlas');
      expect(portalService.lastInvitedAccount?.ownerEmail, 'cliente@atlas.com');
      expect(
        find.text('Convite enviado para cliente@atlas.com.'),
        findsOneWidget,
      );
    });
  });
}
