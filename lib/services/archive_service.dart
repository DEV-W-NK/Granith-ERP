import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchiveService {
  ArchiveService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? AppSupabase.client;

  Future<void> archive({
    required String table,
    required String id,
    String? reason,
  }) async {
    final archived = await _supabase.rpc(
      'archive_record',
      params: {'p_table': table, 'p_id': id, 'p_reason': reason},
    );

    if (archived != true) {
      throw StateError('Registro nao encontrado ou ja arquivado.');
    }
  }

  Future<void> restore({required String table, required String id}) async {
    final restored = await _supabase.rpc(
      'restore_archived_record',
      params: {'p_table': table, 'p_id': id},
    );

    if (restored != true) {
      throw StateError('Registro nao encontrado ou nao esta arquivado.');
    }
  }
}
