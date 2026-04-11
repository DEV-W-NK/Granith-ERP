import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_granith/app/auth_wrapper.dart';
import 'package:project_granith/core/config/supabase_config.dart';
import 'package:project_granith/themes/app_theme.dart';

class AppInitializationPage extends StatefulWidget {
  const AppInitializationPage({super.key});

  @override
  State<AppInitializationPage> createState() => _AppInitializationPageState();
}

class _AppInitializationPageState extends State<AppInitializationPage> {
  bool _isInitialized = false;
  final String _statusMessage = 'Iniciando sistema...';

  @override
  void initState() {
    super.initState();
    _setupEnvironment();
  }

  Future<void> _setupEnvironment() async {
    if (kDebugMode && SupabaseConfig.useFirebaseAuthEmulator) {
      debugPrint(
        '[GRANITH] USE_FIREBASE_AUTH_EMULATOR esta habilitado, mas o app agora usa Supabase Auth.',
      );
    }

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return const AuthWrapper();
    }

    return Scaffold(
      backgroundColor: AppColors.borderColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentGold),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
