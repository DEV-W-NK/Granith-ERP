import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/screens/client_first_access_page.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';

void main() {
  group('ClientFirstAccessPage', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      required FakeAuthService authService,
      required AuthViewModel authViewModel,
    }) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: authViewModel,
          child: MaterialApp(
            builder: EasyLoading.init(),
            home: ClientFirstAccessPage(
              authService: authService,
              showLoading: ({String? status}) async {},
              dismissLoading: () async {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('valida senha obrigatoria e confirmacao', (tester) async {
      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('client-1', 'cliente@granith.com'),
        profile: UserModel(
          uid: 'client-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: const [
          ClientAccount(
            id: 'acc-1',
            name: 'Cliente Granith',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@granith.com',
            contactPhone: '11999999999',
            portalAccessStatus: ClientPortalAccessStatus.invited,
          ),
        ],
      );
      addTearDown(authService.dispose);

      final authViewModel = AuthViewModel(
        service: authService,
        bootstrapOnInit: true,
      );

      await pumpPage(
        tester,
        authService: authService,
        authViewModel: authViewModel,
      );

      await tester.tap(find.text('Salvar senha e continuar'));
      await tester.pump();

      expect(find.text('Informe a nova senha.'), findsOneWidget);
      expect(find.text('Confirme a nova senha.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '12345678');
      await tester.enterText(find.byType(TextFormField).last, '87654321');
      await tester.tap(find.text('Salvar senha e continuar'));
      await tester.pump();

      expect(find.text('As senhas nao conferem.'), findsOneWidget);
    });

    testWidgets('conclui primeiro acesso e faz logout ao confirmar dialogo', (
      tester,
    ) async {
      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('client-1', 'cliente@granith.com'),
        profile: UserModel(
          uid: 'client-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: const [
          ClientAccount(
            id: 'acc-1',
            name: 'Cliente Granith',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@granith.com',
            contactPhone: '11999999999',
            portalAccessStatus: ClientPortalAccessStatus.invited,
          ),
        ],
      );
      addTearDown(authService.dispose);

      final authViewModel = AuthViewModel(
        service: authService,
        bootstrapOnInit: true,
      );

      await pumpPage(
        tester,
        authService: authService,
        authViewModel: authViewModel,
      );

      expect(find.text('Cliente Granith'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'SenhaForte1');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).last, 'SenhaForte1');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Salvar senha e continuar'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(authService.lastPassword, 'SenhaForte1');
      expect(find.text('Primeiro acesso concluido'), findsOneWidget);

      await tester.tap(find.text('Ir para login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(authService.signOutCalled, isTrue);
    });

    testWidgets(
      'exibe mensagem de negocio quando completeClientFirstAccess falha',
      (tester) async {
        final authService = FakeAuthService(
            currentUserValue: const FakeAuthUser(
              'client-1',
              'cliente@granith.com',
            ),
            profile: UserModel(
              uid: 'client-1',
              email: 'cliente@granith.com',
              role: UserRole.client,
            ),
            ownedAccounts: const [
              ClientAccount(
                id: 'acc-1',
                name: 'Cliente Granith',
                ownerEmail: 'cliente@granith.com',
                contactEmail: 'contato@granith.com',
                contactPhone: '11999999999',
                portalAccessStatus: ClientPortalAccessStatus.invited,
              ),
            ],
          )
          ..firstAccessError = const AppAuthException(
            code: 'weak_password',
            message: 'A senha precisa ser mais forte.',
          );
        addTearDown(authService.dispose);

        final authViewModel = AuthViewModel(
          service: authService,
          bootstrapOnInit: true,
        );

        await pumpPage(
          tester,
          authService: authService,
          authViewModel: authViewModel,
        );

        await tester.enterText(find.byType(TextFormField).first, 'SenhaForte1');
        await tester.pump();
        await tester.enterText(find.byType(TextFormField).last, 'SenhaForte1');
        await tester.pump();
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Salvar senha e continuar'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('A senha precisa ser mais forte.'), findsOneWidget);
        expect(authService.signOutCalled, isFalse);
      },
    );
  });
}
