import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/auth_service.dart';

void main() {
  group('AuthService OAuth redirect', () {
    test('usa a origem atual no web', () {
      final redirectTo = resolveAuthRedirectTo(
        isWeb: true,
        targetPlatform: TargetPlatform.android,
        webBaseUri: Uri.parse('http://localhost:61886/login?foo=bar'),
      );

      expect(redirectTo, 'http://localhost:61886');
    });

    test('usa deep link proprio no Android e iOS', () {
      expect(
        resolveAuthRedirectTo(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
        ),
        mobileOAuthRedirectTo,
      );
      expect(
        resolveAuthRedirectTo(isWeb: false, targetPlatform: TargetPlatform.iOS),
        mobileOAuthRedirectTo,
      );
    });

    test('nao usa localhost implicito em plataformas desktop', () {
      expect(
        resolveAuthRedirectTo(
          isWeb: false,
          targetPlatform: TargetPlatform.windows,
        ),
        isNull,
      );
    });

    test('usa Google Sign-In nativo somente em Android e iOS', () {
      expect(
        shouldUseNativeGoogleSignIn(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        shouldUseNativeGoogleSignIn(
          isWeb: false,
          targetPlatform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        shouldUseNativeGoogleSignIn(
          isWeb: true,
          targetPlatform: TargetPlatform.android,
        ),
        isFalse,
      );
      expect(
        shouldUseNativeGoogleSignIn(
          isWeb: false,
          targetPlatform: TargetPlatform.windows,
        ),
        isFalse,
      );
    });

    test('mapeia erro de configuracao do Google Sign-In nativo', () {
      final message = mapGoogleSignInError(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      );

      expect(message, contains('Google Sign-In nativo'));
      expect(message, contains('SHA-1/SHA-256'));
    });
  });

  group('AuthService internal username helpers', () {
    test('normaliza usuario interno e gera e-mail tecnico estavel', () {
      expect(normalizeInternalUsername(' Maria.Obra '), 'maria.obra');
      expect(
        internalLoginEmailForUsername('Maria.Obra'),
        'maria.obra@internal.granith.local',
      );
    });

    test('rejeita usuario interno com espaco ou separador repetido', () {
      expect(validateInternalUsername('ma'), isNotNull);
      expect(validateInternalUsername('maria obra'), isNotNull);
      expect(validateInternalUsername('maria..obra'), isNotNull);
      expect(validateInternalUsername('maria.obra'), isNull);
    });
  });

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
