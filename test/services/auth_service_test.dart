import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/auth_service.dart';

void main() {
  group('AuthService profile payloads', () {
    test('insert payload creates only non-privileged client profile', () {
      final payload = buildAuthUserProfileInsertPayload(
        uid: 'auth-client-1',
        email: 'cliente@granith.com',
        displayName: 'Cliente Granith',
        photoUrl: 'https://cdn/avatar.png',
        nowIso: '2026-05-07T12:30:00.000Z',
        role: UserRole.client,
        primaryClientAccount: ClientAccount.empty().copyWith(
          id: 'client-1',
          name: 'Cliente Granith',
        ),
      );

      expect(payload['id'], 'auth-client-1');
      expect(payload['email'], 'cliente@granith.com');
      expect(payload['role'], 'client');
      expect(payload['permissions'], isEmpty);
      expect(payload['status'], 'ativo');
      expect(payload['clientAccountId'], 'client-1');
      expect(payload['client_account_id'], 'client-1');
    });

    test('update payload does not resend privileged profile fields', () {
      final payload = buildAuthUserProfileUpdatePayload(
        existingProfile: const UserModel(
          uid: 'auth-client-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
          permissions: ['portal_cliente'],
        ),
        displayName: 'Cliente Atualizado',
        photoUrl: null,
        nowIso: '2026-05-07T12:31:00.000Z',
        primaryClientAccount: ClientAccount.empty().copyWith(
          id: 'client-1',
          name: 'Cliente Granith',
        ),
      );

      expect(payload, isNot(contains('id')));
      expect(payload, isNot(contains('email')));
      expect(payload, isNot(contains('role')));
      expect(payload, isNot(contains('permissions')));
      expect(payload, isNot(contains('status')));
      expect(payload['displayName'], 'Cliente Atualizado');
      expect(payload['lastLogin'], '2026-05-07T12:31:00.000Z');
      expect(payload['clientAccountId'], 'client-1');
    });

    test('update payload keeps client bindings out of internal profiles', () {
      final payload = buildAuthUserProfileUpdatePayload(
        existingProfile: const UserModel(
          uid: 'admin-1',
          email: 'admin@granith.com',
          role: UserRole.admin,
          permissions: ['settings.manage'],
        ),
        displayName: 'Admin',
        photoUrl: null,
        nowIso: '2026-05-07T12:32:00.000Z',
        primaryClientAccount: ClientAccount.empty().copyWith(
          id: 'client-99',
          name: 'Conta Admin',
        ),
      );

      expect(payload, isNot(contains('clientAccountId')));
      expect(payload, isNot(contains('client_account_id')));
      expect(payload, isNot(contains('role')));
      expect(payload, isNot(contains('permissions')));
    });
  });
}
