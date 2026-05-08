import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/services/client_account_service.dart';

void main() {
  group('ClientAccountService portal payloads', () {
    test('session update payload only contains RLS-allowed portal fields', () {
      final payload = buildClientPortalSessionUpdatePayload(
        authUserId: 'auth-client-1',
        portalAccessStatus: ClientPortalAccessStatus.active,
        portalLastAccessAt: DateTime.utc(2026, 5, 7, 13, 10),
        updatedAt: DateTime.utc(2026, 5, 7, 13, 11),
      );

      expect(
        payload.keys,
        unorderedEquals([
          'portalAccessStatus',
          'portal_access_status',
          'portalAuthUserId',
          'portal_auth_user_id',
          'portalLastAccessAt',
          'portal_last_access_at',
          'updated_at',
        ]),
      );
      expect(payload['portalAccessStatus'], 'active');
      expect(payload['portal_auth_user_id'], 'auth-client-1');
      expect(payload, isNot(contains('id')));
      expect(payload, isNot(contains('ownerEmail')));
      expect(payload, isNot(contains('owner_email')));
      expect(payload, isNot(contains('name')));
      expect(payload, isNot(contains('created_at')));
    });

    test('session update can omit access status during regular login', () {
      final payload = buildClientPortalSessionUpdatePayload(
        authUserId: 'auth-client-1',
        portalAccessStatus: null,
        portalLastAccessAt: DateTime.utc(2026, 5, 7, 13, 10),
        updatedAt: DateTime.utc(2026, 5, 7, 13, 11),
      );

      expect(payload, isNot(contains('portalAccessStatus')));
      expect(payload, isNot(contains('portal_access_status')));
      expect(payload['portalAuthUserId'], 'auth-client-1');
      expect(payload['portalLastAccessAt'], '2026-05-07T13:10:00.000Z');
      expect(payload['updated_at'], '2026-05-07T13:11:00.000Z');
    });
  });
}
