import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_granith/core/config/supabase_config.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/services/client_account_service.dart';

class ClientPortalAccessService {
  final ClientAccountService _clientAccountService = ClientAccountService();

  SupabaseClient _buildProvisioningClient() {
    return SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  }

  Future<ClientPortalInviteResult> createOrResendAccess(
    ClientAccount account,
  ) async {
    final normalizedEmail = account.ownerEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const ClientPortalAccessException(
        'Informe o e-mail da conta do portal antes de criar o acesso.',
      );
    }

    final inviteClient = _buildProvisioningClient();
    try {
      await inviteClient.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
        data: {
          'role': 'client',
          'client_account_name': account.name,
          if (account.id.isNotEmpty) 'client_account_id': account.id,
        },
      );

      final savedAccount = await _clientAccountService.saveClientAccount(
        account.copyWith(
          ownerEmail: normalizedEmail,
          portalAccessStatus: ClientPortalAccessStatus.invited,
          portalInvitedAt: DateTime.now().toUtc(),
        ),
      );

      return ClientPortalInviteResult(
        account: savedAccount,
        message:
            'Convite enviado para $normalizedEmail. O cliente definira a senha pelo link recebido e depois passara a entrar pelo login normal.',
      );
    } on AuthApiException catch (error) {
      throw ClientPortalAccessException(_mapAuthError(error));
    } on AuthException catch (error) {
      throw ClientPortalAccessException(error.message);
    } catch (error) {
      debugPrint('[ClientPortalAccessService] Falha ao enviar convite: $error');
      throw ClientPortalAccessException(_mapUnexpectedError(error));
    }
  }

  String _mapAuthError(AuthApiException error) {
    switch (error.code) {
      case 'email_provider_disabled':
        return 'O provedor de e-mail do Supabase nao esta habilitado para enviar o convite.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'O Supabase limitou o envio de convites agora. Aguarde um pouco e tente novamente.';
      case 'validation_failed':
        return 'O e-mail informado para o acesso do cliente nao passou na validacao.';
      default:
        return error.message;
    }
  }

  String _mapUnexpectedError(Object error) {
    final message = error.toString();
    if (message.contains('portalAccessStatus') ||
        message.contains('portal_access_status') ||
        message.contains('portalInvitedAt') ||
        message.contains('portal_invited_at') ||
        message.contains('42703') ||
        message.contains('PGRST204')) {
      return 'O banco ainda nao possui as colunas de acesso do portal do cliente. Aplique a migration de portal e tente novamente.';
    }

    if (message.contains('asyncStorage') || message.contains('pkce')) {
      return 'O cliente de convite do Supabase esta configurado com fluxo PKCE sem storage. Use o fluxo implicit para envio de convites.';
    }

    return 'Nao foi possivel criar o acesso do cliente agora. Detalhe: $message';
  }
}

class ClientPortalInviteResult {
  final ClientAccount account;
  final String message;

  const ClientPortalInviteResult({
    required this.account,
    required this.message,
  });
}

class ClientPortalAccessException implements Exception {
  final String message;

  const ClientPortalAccessException(this.message);

  @override
  String toString() => message;
}
