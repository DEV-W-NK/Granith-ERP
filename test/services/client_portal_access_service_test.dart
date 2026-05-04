import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/services/client_portal_access_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_client_account_service.dart';

void main() {
  group('ClientPortalAccessService', () {
    test(
      'bloqueia criacao de acesso quando ownerEmail estiver vazio',
      () async {
        final service = ClientPortalAccessService(
          clientAccountService: FakeClientAccountService(),
          inviteSender:
              ({
                required String email,
                required bool shouldCreateUser,
                required String? emailRedirectTo,
                required Map<String, dynamic> data,
              }) async {},
        );

        expect(
          () => service.createOrResendAccess(
            const ClientAccount(
              id: 'client-1',
              name: 'Cliente sem e-mail',
              ownerEmail: '',
              contactEmail: '',
              contactPhone: '',
            ),
          ),
          throwsA(
            isA<ClientPortalAccessException>().having(
              (e) => e.message,
              'message',
              contains('Informe o e-mail da conta do portal'),
            ),
          ),
        );
      },
    );

    test(
      'createOrResendAccess normaliza email, envia convite e marca conta como invited',
      () async {
        final accountService = FakeClientAccountService();
        String? sentEmail;
        Map<String, dynamic>? sentData;

        final service = ClientPortalAccessService(
          clientAccountService: accountService,
          nowProvider: () => DateTime.utc(2026, 5, 3, 9, 30),
          inviteSender: ({
            required String email,
            required bool shouldCreateUser,
            required String? emailRedirectTo,
            required Map<String, dynamic> data,
          }) async {
            sentEmail = email;
            sentData = data;
            expect(shouldCreateUser, isTrue);
          },
        );

        final result = await service.createOrResendAccess(
          const ClientAccount(
            id: 'client-1',
            name: 'Cliente Premium',
            ownerEmail: 'CLIENTE@Empresa.com',
            contactEmail: 'contato@empresa.com',
            contactPhone: '11999999999',
          ),
        );

        expect(sentEmail, 'cliente@empresa.com');
        expect(sentData?['role'], 'client');
        expect(sentData?['client_account_id'], 'client-1');
        expect(
          result.account.portalAccessStatus,
          ClientPortalAccessStatus.invited,
        );
        expect(result.account.portalInvitedAt, DateTime.utc(2026, 5, 3, 9, 30));
        expect(
          accountService.lastSavedAccount?.ownerEmail,
          'cliente@empresa.com',
        );
        expect(
          result.message,
          contains('Convite enviado para cliente@empresa.com'),
        );
      },
    );

    test(
      'mapeia AuthApiException conhecida para mensagem de negocio',
      () async {
        final service = ClientPortalAccessService(
          clientAccountService: FakeClientAccountService(),
          inviteSender: ({
            required String email,
            required bool shouldCreateUser,
            required String? emailRedirectTo,
            required Map<String, dynamic> data,
          }) async {
            throw AuthApiException(
              'validation failed',
              statusCode: '400',
              code: 'validation_failed',
            );
          },
        );

        expect(
          () => service.createOrResendAccess(
            const ClientAccount(
              id: 'client-2',
              name: 'Cliente Validacao',
              ownerEmail: 'cliente@empresa.com',
              contactEmail: 'contato@empresa.com',
              contactPhone: '11999999999',
            ),
          ),
          throwsA(
            isA<ClientPortalAccessException>().having(
              (e) => e.message,
              'message',
              contains('nao passou na validacao'),
            ),
          ),
        );
      },
    );

    test(
      'mapeia erro inesperado de migration ausente para mensagem operacional clara',
      () async {
        final service = ClientPortalAccessService(
          clientAccountService: FakeClientAccountService(),
          inviteSender: ({
            required String email,
            required bool shouldCreateUser,
            required String? emailRedirectTo,
            required Map<String, dynamic> data,
          }) async {
            throw Exception('PGRST204 portal_access_status');
          },
        );

        expect(
          () => service.createOrResendAccess(
            const ClientAccount(
              id: 'client-3',
              name: 'Cliente Migration',
              ownerEmail: 'cliente@empresa.com',
              contactEmail: 'contato@empresa.com',
              contactPhone: '11999999999',
            ),
          ),
          throwsA(
            isA<ClientPortalAccessException>().having(
              (e) => e.message,
              'message',
              contains('Aplique a migration de portal'),
            ),
          ),
        );
      },
    );
  });
}
