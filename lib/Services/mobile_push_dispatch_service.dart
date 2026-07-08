import 'package:flutter/foundation.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';

class MobilePushDispatchService {
  const MobilePushDispatchService._();

  static Future<void> dispatchPending({int limit = 25}) async {
    try {
      final client = AppSupabase.client;
      await client.functions.invoke(
        'dispatch_mobile_push',
        body: {'limit': limit},
      );
    } on AssertionError catch (error) {
      if (error.toString().contains('_isInitialized')) {
        return;
      }
      debugPrint('[Push] Falha ao despachar notificacoes mobile: $error');
    } catch (error) {
      debugPrint('[Push] Falha ao despachar notificacoes mobile: $error');
      // Push nao deve bloquear a operacao principal do ERP.
    }
  }
}
