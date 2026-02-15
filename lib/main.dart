import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // Importante para injeção de dependência
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/firebase_options.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/screens/login_page.dart';
import 'package:project_granith/screens/subscription_page.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/controllers/subscription_controller.dart'; // Importe o controller aqui

/**
 * TIPO: Entry Point
 * FUNÇÃO: Inicializa Firebase, Configura Providers Globais e Emuladores.
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      String host = kIsWeb ? 'localhost' : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');

      debugPrint('--- [GRANITH] CONECTANDO EMULADORES EM: $host ---');

      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8085);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      
      debugPrint('🟢 [GRANITH] AMBIENTE LOCAL PRONTO: Auth(9099), Firestore(8085)');
    } catch (e) {
      debugPrint('🔴 [GRANITH] ERRO NA INICIALIZAÇÃO LOCAL: $e');
    }
  }

  await initializeDateFormatting('pt_BR', null);
  
  // AQUI ESTÁ A CORREÇÃO: Envolvemos o MyApp com MultiProvider
  runApp(
    MultiProvider(
      providers: [
        // Disponibiliza o AuthController para todo o app
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Disponibiliza o SubscriptionController para todo o app (Resolve o seu erro)
        ChangeNotifierProvider(create: (_) => SubscriptionController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Granith ERP',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      home: const AuthWrapper(),
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/subscription') {
          return MaterialPageRoute(
            builder: (context) => const SubscriptionPage(),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos o AuthService diretamente para o stream, mas o AuthController já está disponível via Provider se precisar
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        }
        
        return const LoginPage();
      },
    );
  }
}