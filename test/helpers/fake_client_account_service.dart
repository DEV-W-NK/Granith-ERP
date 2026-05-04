import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/services/client_account_service.dart';

class FakeClientAccountService extends ClientAccountService {
  FakeClientAccountService({List<ClientAccount>? accounts})
    : _accounts = List<ClientAccount>.from(accounts ?? const <ClientAccount>[]);

  final List<ClientAccount> _accounts;
  Object? getAccountsError;
  Object? saveError;
  ClientAccount? lastSavedAccount;

  @override
  Future<List<ClientAccount>> getClientAccounts() async {
    if (getAccountsError != null) {
      throw getAccountsError!;
    }
    return List<ClientAccount>.from(_accounts);
  }

  @override
  Future<ClientAccount> saveClientAccount(ClientAccount account) async {
    lastSavedAccount = account;
    if (saveError != null) {
      throw saveError!;
    }
    final saved = account.copyWith(
      id: account.id.isEmpty ? 'client-generated' : account.id,
    );
    final index = _accounts.indexWhere((item) => item.id == saved.id);
    if (index >= 0) {
      _accounts[index] = saved;
    } else {
      _accounts.add(saved);
    }
    return saved;
  }
}
