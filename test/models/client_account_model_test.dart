import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';

void main() {
  group('ClientAccount', () {
    test('fromMap resolve campos do portal em snake_case', () {
      final account = ClientAccount.fromMap({
        'id': 'client-1',
        'name': 'Atlas Engenharia',
        'owner_email': 'Cliente@Atlas.com',
        'contact_email': 'contato@atlas.com',
        'contact_phone': '(11) 99999-0000',
        'portal_access_status': 'invited',
        'portal_auth_user_id': 'auth-1',
        'portal_invited_at': '2026-05-03T10:00:00Z',
        'portal_last_access_at': '2026-05-03T12:30:00Z',
      });

      expect(account.id, 'client-1');
      expect(account.ownerEmail, 'Cliente@Atlas.com');
      expect(account.portalAccessStatus, ClientPortalAccessStatus.invited);
      expect(account.portalAuthUserId, 'auth-1');
      expect(account.portalInvitedAt, DateTime.parse('2026-05-03T10:00:00Z'));
      expect(
        account.portalLastAccessAt,
        DateTime.parse('2026-05-03T12:30:00Z'),
      );
      expect(account.hasPortalAccess, isTrue);
    });

    test('toMap normaliza emails e replica colunas camelCase/snake_case', () {
      final account = ClientAccount.empty().copyWith(
        name: 'Atlas Engenharia',
        ownerEmail: 'Cliente@Atlas.com ',
        contactEmail: ' Comercial@Atlas.com ',
        contactPhone: ' 11999990000 ',
        portalAccessStatus: ClientPortalAccessStatus.active,
      );

      final map = account.toMap();

      expect(map['ownerEmail'], 'cliente@atlas.com');
      expect(map['owner_email'], 'cliente@atlas.com');
      expect(map['contactEmail'], 'comercial@atlas.com');
      expect(map['contact_email'], 'comercial@atlas.com');
      expect(map['contactPhone'], '11999990000');
      expect(map['contact_phone'], '11999990000');
      expect(map['portalAccessStatus'], 'active');
      expect(map['portal_access_status'], 'active');
    });
  });
}
