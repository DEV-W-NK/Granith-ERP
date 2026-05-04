import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/app/auth_wrapper.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:provider/provider.dart';
import '../helpers/fake_auth_service.dart';

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

void main() {
  Widget buildHarness(AuthViewModel viewModel) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: const MaterialApp(
        home: AuthWrapper(
          loginPage: _RouteStub('login'),
          clientFirstAccessPage: _RouteStub('first-access'),
          clientPortalPage: _RouteStub('client-portal'),
          mainLayoutPage: _RouteStub('main-layout'),
        ),
      ),
    );
  }

  group('AuthWrapper', () {
    testWidgets('mostra loading enquanto auth nao inicializou', (tester) async {
      final auth = AuthViewModel(
        service: FakeAuthService(),
        bootstrapOnInit: false,
      );

      await tester.pumpWidget(buildHarness(auth));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('roteia para login quando nao autenticado', (tester) async {
      final service = FakeAuthService(currentUserValue: null);
      final auth = AuthViewModel(service: service);

      await tester.pumpWidget(buildHarness(auth));
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      await service.dispose();
    });

    testWidgets('roteia cliente convidado para primeiro acesso', (
      tester,
    ) async {
      final service = FakeAuthService(
        currentUserValue: const FakeAuthUser('user-1', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'user-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Alfa',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@cliente.com',
            contactPhone: '11999990000',
            portalAccessStatus: ClientPortalAccessStatus.invited,
          ),
        ],
      );
      final auth = AuthViewModel(service: service);

      await tester.pumpWidget(buildHarness(auth));
      await tester.pumpAndSettle();

      expect(find.text('first-access'), findsOneWidget);
      await service.dispose();
    });

    testWidgets('roteia cliente ativo para portal do cliente', (tester) async {
      final service = FakeAuthService(
        currentUserValue: const FakeAuthUser('user-1', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'user-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Alfa',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@cliente.com',
            contactPhone: '11999990000',
            portalAccessStatus: ClientPortalAccessStatus.active,
          ),
        ],
      );
      final auth = AuthViewModel(service: service);

      await tester.pumpWidget(buildHarness(auth));
      await tester.pumpAndSettle();

      expect(find.text('client-portal'), findsOneWidget);
      await service.dispose();
    });

    testWidgets('roteia funcionario para o layout principal', (tester) async {
      final service = FakeAuthService(
        currentUserValue: const FakeAuthUser('user-1', 'colab@granith.com'),
        profile: const UserModel(
          uid: 'user-1',
          email: 'colab@granith.com',
          role: UserRole.employee,
        ),
      );
      final auth = AuthViewModel(service: service);

      await tester.pumpWidget(buildHarness(auth));
      await tester.pumpAndSettle();

      expect(find.text('main-layout'), findsOneWidget);
      await service.dispose();
    });
  });
}
