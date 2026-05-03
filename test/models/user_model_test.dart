import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap aceita chaves camelCase e snake_case', () {
      final user = UserModel.fromMap({
        'email': 'cliente@granith.com',
        'display_name': 'Cliente Granith',
        'photo_url': 'https://cdn/avatar.png',
        'status': 'ativo',
        'permissions': ['budgets.read'],
        'role': 'client',
        'client_account_id': 'client-1',
        'client_account_name': 'Construtora Atlas',
      }, 'user-1');

      expect(user.uid, 'user-1');
      expect(user.email, 'cliente@granith.com');
      expect(user.displayName, 'Cliente Granith');
      expect(user.photoUrl, 'https://cdn/avatar.png');
      expect(user.permissions, ['budgets.read']);
      expect(user.role, UserRole.client);
      expect(user.clientAccountId, 'client-1');
      expect(user.clientAccountName, 'Construtora Atlas');
      expect(user.isClient, isTrue);
      expect(user.isEmployee, isFalse);
    });

    test('toMap replica role e referencias da conta do cliente', () {
      const user = UserModel(
        uid: 'u1',
        email: 'admin@granith.com',
        displayName: 'Admin',
        role: UserRole.admin,
        clientAccountId: 'client-99',
        clientAccountName: 'Conta Premium',
      );

      final map = user.toMap();

      expect(map['role'], 'admin');
      expect(map['clientAccountId'], 'client-99');
      expect(map['client_account_id'], 'client-99');
      expect(map['clientAccountName'], 'Conta Premium');
      expect(map['client_account_name'], 'Conta Premium');
    });
  });
}
