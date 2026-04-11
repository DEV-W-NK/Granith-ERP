import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/client_account_model.dart';

class ClientAccountService {
  static const String _table = 'client_accounts';

  Future<List<ClientAccount>> getClientAccounts() async {
    final response = await AppSupabase.client
        .from(_table)
        .select()
        .order('name');

    return (response as List)
        .map((row) => ClientAccount.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<ClientAccount>> getClientAccountsByOwnerEmail(String email) async {
    if (email.trim().isEmpty) return [];

    final response = await AppSupabase.client
        .from(_table)
        .select()
        .eq('ownerEmail', email.trim().toLowerCase())
        .order('name');

    return (response as List)
        .map((row) => ClientAccount.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ClientAccount?> getPrimaryAccountByOwnerEmail(String email) async {
    final accounts = await getClientAccountsByOwnerEmail(email);
    if (accounts.isEmpty) return null;
    return accounts.first;
  }

  Future<void> saveClientAccount(ClientAccount account) async {
    final now = DateTime.now().toUtc();
    final payload = DbValue.normalizeMap({
      ...account.toMap(),
      'created_at': account.createdAt ?? now,
      'updated_at': now,
    });

    if (account.id.isEmpty) {
      await AppSupabase.client.from(_table).insert(payload);
      return;
    }

    await AppSupabase.client.from(_table).upsert(payload);
  }
}
