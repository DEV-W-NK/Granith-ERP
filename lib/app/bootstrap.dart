import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_granith/app/app.dart';
import 'package:project_granith/core/config/supabase_config.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  SupabaseConfig.validate();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: GranithApp()));
}
