import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        debugPrint,
        defaultTargetPlatform,
        kIsWeb,
        visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_granith/core/config/google_oauth_config.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/core/supabase/supabase_selects.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/client_account_service.dart';
import 'package:project_granith/services/auth_service_contract.dart';

@visibleForTesting
const String mobileOAuthRedirectTo = 'granithmobile://login-callback/';
const String internalLoginEmailDomain = 'internal.granith.local';

class AuthService implements AuthServiceContract {
  SupabaseClient get _client => AppSupabase.client;
  final ClientAccountService _clientAccountService = ClientAccountService();
  static Future<void>? _googleSignInInitFuture;
  static bool _nativeGoogleSignInInitialized = false;

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
    final targetPlatform = defaultTargetPlatform;
    if (shouldUseNativeGoogleSignIn(
      isWeb: kIsWeb,
      targetPlatform: targetPlatform,
    )) {
      await _signInWithNativeGoogle(targetPlatform);
      return;
    }

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: resolveAuthRedirectTo(
          isWeb: kIsWeb,
          targetPlatform: targetPlatform,
        ),
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

  Future<void> _signInWithNativeGoogle(TargetPlatform targetPlatform) async {
    await _ensureNativeGoogleSignInInitialized(targetPlatform);

    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AppAuthException(
          code: 'google_native_unsupported',
          message:
              'O login nativo do Google nao esta disponivel nesta plataforma.',
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppAuthException(
          code: 'google_missing_id_token',
          message:
              'O Google nao retornou o token de identidade necessario para entrar.',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on AppAuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw AppAuthException(
        code: error.code.name,
        message: mapGoogleSignInError(error),
      );
    } on AuthException catch (error) {
      throw AppAuthException(
        code: error.code ?? 'google_id_token_failed',
        message: _mapGoogleIdTokenAuthError(error),
      );
    } catch (_) {
      throw const AppAuthException(
        code: 'google_native_sign_in_failed',
        message: 'Nao foi possivel autenticar com Google no app.',
      );
    }
  }

  Future<void> _ensureNativeGoogleSignInInitialized(
    TargetPlatform targetPlatform,
  ) {
    if (!GoogleOAuthConfig.hasServerClientId) {
      throw const AppAuthException(
        code: 'missing_google_web_client_id',
        message:
            'GOOGLE_OAUTH_WEB_CLIENT_ID nao esta configurado para o login nativo do Google.',
      );
    }

    if (targetPlatform == TargetPlatform.iOS &&
        GoogleOAuthConfig.iosClientId.isEmpty) {
      throw const AppAuthException(
        code: 'missing_google_ios_client_id',
        message:
            'GOOGLE_OAUTH_IOS_CLIENT_ID nao esta configurado para o login nativo do Google no iOS.',
      );
    }

    _googleSignInInitFuture ??= GoogleSignIn.instance.initialize(
      clientId: GoogleOAuthConfig.nativeClientIdFor(targetPlatform),
      serverClientId: GoogleOAuthConfig.webClientId,
    );
    _nativeGoogleSignInInitialized = true;
    return _googleSignInInitFuture!;
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
  Future<void> signInWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = normalizeInternalUsername(username);
    final validationError = validateInternalUsername(normalizedUsername);
    if (validationError != null) {
      throw AppAuthException(
        code: 'invalid_username',
        message: validationError,
      );
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: internalLoginEmailForUsername(normalizedUsername),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await _checkAndSetupUser(user);
      }
    } on AuthException catch (error) {
      throw AppAuthException(
        code: error.code ?? 'username_sign_in_failed',
        message: _mapAuthError(
          error,
          fallbackMessage: 'Nao foi possivel entrar com usuario e senha.',
        ),
      );
    } on AppAuthException {
      rethrow;
    } catch (_) {
      throw const AppAuthException(
        code: 'username_sign_in_failed',
        message: 'Nao foi possivel entrar com usuario e senha.',
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
        emailRedirectTo: resolveAuthRedirectTo(
          isWeb: kIsWeb,
          targetPlatform: defaultTargetPlatform,
        ),
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
    if (_nativeGoogleSignInInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint('Erro ao encerrar sessao Google nativa: $error');
      }
    }

    await _client.auth.signOut();
  }

  String _mapGoogleIdTokenAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('audience') ||
        message.contains('id_token') ||
        message.contains('id token') ||
        message.contains('invalid')) {
      return 'O token do Google nao foi aceito pelo Supabase. Confira se o Client ID web esta configurado no app e no provedor Google do Supabase.';
    }

    return _mapAuthError(
      error,
      fallbackMessage: 'Nao foi possivel validar o login do Google.',
    );
  }

  String _mapAuthError(AuthException error, {required String fallbackMessage}) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Usuario/e-mail ou senha invalidos.';
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

String normalizeInternalUsername(String value) {
  return value.trim().toLowerCase();
}

String? validateInternalUsername(String value) {
  final normalized = normalizeInternalUsername(value);
  if (normalized.isEmpty) {
    return 'Informe o usuario para prosseguir.';
  }
  if (normalized.length < 3 || normalized.length > 32) {
    return 'O usuario precisa ter entre 3 e 32 caracteres.';
  }
  if (!RegExp(r'^[a-z0-9][a-z0-9._-]*[a-z0-9]$').hasMatch(normalized)) {
    return 'Use apenas letras, numeros, ponto, hifen ou sublinhado, sem espacos.';
  }
  if (normalized.contains('..') ||
      normalized.contains('__') ||
      normalized.contains('--')) {
    return 'O usuario nao pode ter separadores repetidos.';
  }
  return null;
}

String internalLoginEmailForUsername(String username) {
  final normalized = normalizeInternalUsername(username);
  final validationError = validateInternalUsername(normalized);
  if (validationError != null) {
    throw AppAuthException(code: 'invalid_username', message: validationError);
  }
  return '$normalized@$internalLoginEmailDomain';
}

@visibleForTesting
bool shouldUseNativeGoogleSignIn({
  required bool isWeb,
  required TargetPlatform targetPlatform,
}) {
  if (isWeb) {
    return false;
  }

  return switch (targetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

@visibleForTesting
String? resolveAuthRedirectTo({
  required bool isWeb,
  required TargetPlatform targetPlatform,
  Uri? webBaseUri,
}) {
  if (isWeb) {
    return (webBaseUri ?? Uri.base).origin;
  }

  return switch (targetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => mobileOAuthRedirectTo,
    _ => null,
  };
}

@visibleForTesting
String mapGoogleSignInError(GoogleSignInException error) {
  switch (error.code) {
    case GoogleSignInExceptionCode.canceled:
      return 'Login com Google cancelado.';
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
      return 'Google Sign-In nativo nao esta configurado corretamente. Confira package name, Bundle ID, SHA-1/SHA-256 e Client IDs no Google Cloud.';
    case GoogleSignInExceptionCode.uiUnavailable:
      return 'O Google nao conseguiu abrir a tela de login neste dispositivo.';
    default:
      return error.description?.trim().isNotEmpty == true
          ? error.description!
          : 'Nao foi possivel abrir o login do Google.';
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
