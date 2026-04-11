import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/client_account_service.dart';

class AuthService {
  SupabaseClient get _client => AppSupabase.client;
  final ClientAccountService _clientAccountService = ClientAccountService();

  User? get currentUser => _client.auth.currentUser;
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session?.user);

  Future<UserModel?> fetchUserData(String uid) async {
    try {
      final data = await _client.from('users').select().eq('id', uid).maybeSingle();

      if (data == null) {
        return null;
      }

      return UserModel.fromMap(Map<String, dynamic>.from(data), uid);
    } catch (error) {
      debugPrint('Erro ao buscar dados do utilizador no Supabase: $error');
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AppAuthException(
        code: 'google_sign_in_failed',
        message: 'Nao foi possivel autenticar com Google.',
      );
    }
  }

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
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AppAuthException(
        code: 'email_sign_in_failed',
        message: 'Nao foi possivel entrar com e-mail e senha.',
      );
    }
  }

  Future<void> ensureCurrentUserProfile() async {
    final user = currentUser;
    if (user != null) {
      await _checkAndSetupUser(user);
    }
  }

  Future<List<ClientAccount>> getOwnedClientAccounts(String email) {
    return _clientAccountService.getClientAccountsByOwnerEmail(email);
  }

  Future<void> _checkAndSetupUser(User user) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final displayName =
        user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString() ??
        user.email;
    final photoUrl = user.userMetadata?['avatar_url']?.toString();
    final existingProfile = await fetchUserData(user.id);
    final linkedAccounts = await _clientAccountService.getClientAccountsByOwnerEmail(
      user.email ?? '',
    );
    final primaryClientAccount =
        linkedAccounts.isNotEmpty ? linkedAccounts.first : null;

    final resolvedRole = existingProfile?.role ??
        (primaryClientAccount != null ? UserRole.client : UserRole.employee);

    await _client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'displayName': displayName,
      'display_name': displayName,
      'photoUrl': photoUrl,
      'photo_url': photoUrl,
      'lastLogin': now,
      'last_login': now,
      'created_at': now,
      'updated_at': now,
      'status': 'ativo',
      'permissions': existingProfile?.permissions ?? const <String>[],
      'role': resolvedRole.value,
      'clientAccountId':
          existingProfile?.clientAccountId ?? primaryClientAccount?.id,
      'client_account_id':
          existingProfile?.clientAccountId ?? primaryClientAccount?.id,
      'clientAccountName':
          existingProfile?.clientAccountName ?? primaryClientAccount?.name,
      'client_account_name':
          existingProfile?.clientAccountName ?? primaryClientAccount?.name,
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class AppAuthException implements Exception {
  final String code;
  final String message;

  const AppAuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}
