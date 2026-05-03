import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';

import '../helpers/fake_auth_service.dart';

Future<void> _flushAuthQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('AuthViewModel', () {
    test('marca como inicializado e deslogado sem sessao', () async {
      final service = FakeAuthService();

      final viewModel = AuthViewModel(service: service);
      await _flushAuthQueue();

      expect(viewModel.isInitialized, isTrue);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.user, isNull);

      await service.dispose();
    });

    test('resolve cliente com conta vinculada e primeiro acesso pendente', () async {
      final service = FakeAuthService(
        currentUserValue: const FakeAuthUser('u1', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'u1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: [
          ClientAccount.empty().copyWith(
            id: 'client-1',
            name: 'Cliente Atlas',
            ownerEmail: 'cliente@granith.com',
            portalAccessStatus: ClientPortalAccessStatus.invited,
          ),
        ],
      );

      final viewModel = AuthViewModel(service: service);
      await _flushAuthQueue();

      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.isClientUser, isTrue);
      expect(viewModel.primaryClientAccount?.id, 'client-1');
      expect(viewModel.user?.clientAccountName, 'Cliente Atlas');
      expect(viewModel.requiresClientFirstAccess, isTrue);

      await service.dispose();
    });

    test('preserva papel admin mesmo com contas de cliente vinculadas', () async {
      final service = FakeAuthService(
        currentUserValue: const FakeAuthUser('u2', 'admin@granith.com'),
        profile: const UserModel(
          uid: 'u2',
          email: 'admin@granith.com',
          role: UserRole.admin,
          permissions: ['settings.manage'],
        ),
        ownedAccounts: [
          ClientAccount.empty().copyWith(
            id: 'client-2',
            name: 'Conta Admin',
            ownerEmail: 'admin@granith.com',
            portalAccessStatus: ClientPortalAccessStatus.active,
          ),
        ],
      );

      final viewModel = AuthViewModel(service: service);
      await _flushAuthQueue();

      expect(viewModel.isAdminUser, isTrue);
      expect(viewModel.isEmployeeUser, isTrue);
      expect(viewModel.isClientUser, isFalse);
      expect(viewModel.hasPermission('settings.manage'), isTrue);
      expect(viewModel.requiresClientFirstAccess, isFalse);

      await service.dispose();
    });

    test('logout limpa usuario e contas locais', () async {
      final service = FakeAuthService(
        currentUserValue: const FakeAuthUser('u3', 'colab@granith.com'),
        profile: const UserModel(
          uid: 'u3',
          email: 'colab@granith.com',
          role: UserRole.employee,
        ),
      );
      final viewModel = AuthViewModel(service: service);
      await _flushAuthQueue();

      await viewModel.logout();

      expect(service.signOutCalled, isTrue);
      expect(viewModel.user, isNull);
      expect(viewModel.ownedClientAccounts, isEmpty);

      await service.dispose();
    });
  });
}
