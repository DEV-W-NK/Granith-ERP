import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/core/supabase/supabase_selects.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/client_account_service.dart';
import 'package:project_granith/services/auth_service_contract.dart';

class AuthService implements AuthServiceContract {
  SupabaseClient get _client => AppSupabase.client;
  final ClientAccountService _clientAccountService = ClientAccountService();

  @override
  User? get currentUser => _client.auth.currentUser;
  @override
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session?.user);

  @override
  Future<UserModel?> fetchUserData(String uid) async {
    try {
      final dataById =
          await _client
              .from('users')
              .select(SupabaseSelects.userProfile)
              .eq('id', uid)
              .maybeSingle();

      final profileById =
          dataById == null
              ? null
              : UserModel.fromMap(Map<String, dynamic>.from(dataById), uid);

      final authUser = currentUser;
      final authEmail = authUser?.email?.trim().toLowerCase() ?? '';
      if (authUser?.id != uid || authEmail.isEmpty) {
        return profileById;
      }

      final profileByEmail = await _fetchUserDataByEmail(authEmail);
      if (profileByEmail?.role == UserRole.admin) {
        return profileByEmail;
      }

      return profileById ?? profileByEmail;
    } catch (error) {
      debugPrint('Erro ao buscar dados do utilizador no Supabase: $error');
      return null;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
    } on AuthException catch (error) {
      throw AppAuthException(
        code: error.code ?? 'google_sign_in_failed',
        message: _mapAuthError(
          error,
          fallbackMessage: 'Nao foi possivel autenticar com Google.',
        ),
      );
    } catch (_) {
      throw const AppAuthException(
        code: 'google_sign_in_failed',
        message: 'Nao foi possivel autenticar com Google.',
      );
    }
  }

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await _checkAndSetupUser(user);
      }
    } on AuthException catch (error) {
      throw AppAuthException(
        code: error.code ?? 'email_sign_in_failed',
        message: _mapAuthError(
          error,
          fallbackMessage: 'Nao foi possivel entrar com e-mail e senha.',
        ),
      );
    } catch (_) {
      throw const AppAuthException(
        code: 'email_sign_in_failed',
        message: 'Nao foi possivel entrar com e-mail e senha.',
      );
    }
  }

  @override
  Future<void> sendMagicLink({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const AppAuthException(
        code: 'missing_email',
        message: 'Informe o e-mail para receber o link de acesso.',
      );
    }

    try {
      await _client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: shouldCreateUser,
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
      );
    } on AuthException catch (error) {
      throw AppAuthException(
        code: error.code ?? 'magic_link_failed',
        message: _mapAuthError(
          error,
          fallbackMessage: 'Nao foi possivel enviar o link de acesso.',
        ),
      );
    } catch (_) {
      throw const AppAuthException(
        code: 'magic_link_failed',
        message: 'Nao foi possivel enviar o link de acesso.',
      );
    }
  }

  @override
  Future<void> ensureCurrentUserProfile() async {
    final user = currentUser;
    if (user != null) {
      await _checkAndSetupUser(user);
    }
  }

  @override
  Future<void> completeClientFirstAccess({required String password}) async {
    final user = currentUser;
    if (user == null) {
      throw const AppAuthException(
        code: 'missing_session',
        message: 'A sessao do primeiro acesso nao esta disponivel.',
      );
    }

    if (password.trim().length < 8) {
      throw const AppAuthException(
        code: 'weak_password',
        message: 'A nova senha precisa ter pelo menos 8 caracteres.',
      );
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: password.trim()));

      final linkedAccounts = await _clientAccountService
          .getClientAccountsByOwnerEmail(
            (user.email ?? '').trim().toLowerCase(),
          );
      final primaryClientAccount =
          linkedAccounts.isNotEmpty ? linkedAccounts.first : null;

      if (primaryClientAccount != null) {
        await _clientAccountService.updateClientPortalSession(
          accountId: primaryClientAccount.id,
          authUserId: user.id,
          portalAccessStatus: ClientPortalAccessStatus.active,
          portalLastAccessAt: DateTime.now().toUtc(),
        );
      }

      await _checkAndSetupUser(_client.auth.currentUser ?? user);
    } on AuthException catch (error) {
      throw AppAuthException(
        code: error.code ?? 'complete_first_access_failed',
        message: _mapAuthError(
          error,
          fallbackMessage:
              'Nao foi possivel definir a senha do primeiro acesso.',
        ),
      );
    } catch (_) {
      throw const AppAuthException(
        code: 'complete_first_access_failed',
        message: 'Nao foi possivel definir a senha do primeiro acesso.',
      );
    }
  }

  @override
  Future<List<ClientAccount>> getOwnedClientAccounts(String email) {
    return _clientAccountService.getClientAccountsByOwnerEmail(email);
  }

  Future<void> _checkAndSetupUser(User user) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final displayName =
        user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString() ??
        user.email;
    final photoUrl = user.userMetadata?['avatar_url']?.toString();
    final existingProfile =
        await fetchUserData(user.id) ??
        await _fetchUserDataByEmail(normalizedEmail);
    final hasEmployeeRecord = await _hasEmployeeRecord(normalizedEmail);
    final linkedAccounts = await _clientAccountService
        .getClientAccountsByOwnerEmail(normalizedEmail);
    final primaryClientAccount =
        linkedAccounts.isNotEmpty ? linkedAccounts.first : null;

    final resolvedRole = _resolveRole(
      existingProfile: existingProfile,
      hasEmployeeRecord: hasEmployeeRecord,
      hasClientAccount: primaryClientAccount != null,
    );

    if (existingProfile == null) {
      await _client
          .from('users')
          .insert(
            buildAuthUserProfileInsertPayload(
              uid: user.id,
              email: normalizedEmail,
              displayName: displayName,
              photoUrl: photoUrl,
              nowIso: now,
              role: resolvedRole,
              primaryClientAccount: primaryClientAccount,
            ),
          );
    } else {
      await _client
          .from('users')
          .update(
            buildAuthUserProfileUpdatePayload(
              existingProfile: existingProfile,
              displayName: displayName,
              photoUrl: photoUrl,
              nowIso: now,
              primaryClientAccount: primaryClientAccount,
            ),
          )
          .eq('id', existingProfile.uid);
    }

    if (primaryClientAccount != null) {
      await _clientAccountService.updateClientPortalSession(
        accountId: primaryClientAccount.id,
        authUserId: user.id,
        portalLastAccessAt: DateTime.now().toUtc(),
      );
    }
  }

  Future<bool> _hasEmployeeRecord(String email) async {
    if (email.trim().isEmpty) {
      return false;
    }

    final response = await _client
        .from('employees')
        .select('id')
        .ilike('email', email.trim().toLowerCase())
        .limit(1);

    return (response as List).isNotEmpty;
  }

  Future<UserModel?> _fetchUserDataByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final data =
        await _client
            .from('users')
            .select(SupabaseSelects.userProfile)
            .ilike('email', normalizedEmail)
            .order('role')
            .limit(1)
            .maybeSingle();

    if (data == null) {
      return null;
    }

    final map = Map<String, dynamic>.from(data);
    return UserModel.fromMap(map, (map['id'] ?? '').toString());
  }

  UserRole _resolveRole({
    required UserModel? existingProfile,
    required bool hasEmployeeRecord,
    required bool hasClientAccount,
  }) {
    if (existingProfile?.role == UserRole.admin) {
      return UserRole.admin;
    }

    if (hasEmployeeRecord) {
      return UserRole.employee;
    }

    if (hasClientAccount) {
      return UserRole.client;
    }

    if (existingProfile?.role == UserRole.client) {
      return UserRole.client;
    }

    return existingProfile?.role ?? UserRole.employee;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _mapAuthError(AuthException error, {required String fallbackMessage}) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-mail ou senha invalidos.';
      case 'email_not_confirmed':
        return 'Esse e-mail ainda nao confirmou o acesso. Use o link enviado ou solicite um novo convite.';
      case 'user_not_found':
        return 'Nenhum acesso foi encontrado para este e-mail.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Muitas tentativas em sequencia. Aguarde um pouco e tente novamente.';
      case 'email_provider_disabled':
        return 'O login por e-mail ainda nao esta habilitado no Supabase.';
      case 'weak_password':
        return 'A senha informada nao atende aos requisitos minimos do Supabase.';
      default:
        return error.message.isNotEmpty ? error.message : fallbackMessage;
    }
  }
}

@visibleForTesting
Map<String, dynamic> buildAuthUserProfileInsertPayload({
  required String uid,
  required String email,
  required String? displayName,
  required String? photoUrl,
  required String nowIso,
  required UserRole role,
  required ClientAccount? primaryClientAccount,
}) {
  return DbValue.normalizeMap({
    'id': uid,
    'email': email,
    'displayName': displayName,
    'display_name': displayName,
    'photoUrl': photoUrl,
    'photo_url': photoUrl,
    'lastLogin': nowIso,
    'last_login': nowIso,
    'created_at': nowIso,
    'updated_at': nowIso,
    'status': 'ativo',
    'permissions': const <String>[],
    'role': role.value,
    'clientAccountId': primaryClientAccount?.id,
    'client_account_id': primaryClientAccount?.id,
    'clientAccountName': primaryClientAccount?.name,
    'client_account_name': primaryClientAccount?.name,
  });
}

@visibleForTesting
Map<String, dynamic> buildAuthUserProfileUpdatePayload({
  required UserModel existingProfile,
  required String? displayName,
  required String? photoUrl,
  required String nowIso,
  required ClientAccount? primaryClientAccount,
}) {
  final payload = <String, dynamic>{
    'displayName': displayName,
    'display_name': displayName,
    'photoUrl': photoUrl,
    'photo_url': photoUrl,
    'lastLogin': nowIso,
    'last_login': nowIso,
    'updated_at': nowIso,
  };

  if (existingProfile.role == UserRole.client) {
    final clientAccountId =
        existingProfile.clientAccountId ?? primaryClientAccount?.id;
    final clientAccountName =
        existingProfile.clientAccountName ?? primaryClientAccount?.name;

    if (clientAccountId != null && clientAccountId.isNotEmpty) {
      payload['clientAccountId'] = clientAccountId;
      payload['client_account_id'] = clientAccountId;
    }

    if (clientAccountName != null && clientAccountName.isNotEmpty) {
      payload['clientAccountName'] = clientAccountName;
      payload['client_account_name'] = clientAccountName;
    }
  }

  return DbValue.normalizeMap(payload);
}

class AppAuthException implements Exception {
  final String code;
  final String message;

  const AppAuthException({required this.code, required this.message});

  @override
  String toString() => message;
}
