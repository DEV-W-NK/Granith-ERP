import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:provider/provider.dart';

// Imports do Projeto
import 'package:project_granith/controllers/job_role_controller.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/firebase_options.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/screens/login_page.dart';
import 'package:project_granith/screens/subscription_page.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/team_page.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/controllers/logincontroller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/controllers/home_controller.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/utils/seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuração de Locale
  await initializeDateFormatting('pt_BR', null);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => SubscriptionController()),
        ChangeNotifierProvider(create: (_) => DailyLogController()),
        ChangeNotifierProvider(create: (_) => ProjectsController(ServiceProjetos())),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => TeamController()),
        ChangeNotifierProvider(create: (_) => JobRoleController()),
        ChangeNotifierProvider(create: (_) => ReportsController()),
        ChangeNotifierProvider(create: (_) => MaterialRequisitionController()),
        ChangeNotifierProvider(create: (_) => FinancialController()..init()),
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
      // Mudamos a home para a tela de inicialização, que cuida do emulador/seed
      home: const AppInitialization(), 
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/subscription':
            return MaterialPageRoute(builder: (context) => const SubscriptionPage());
          case '/reports':
            return MaterialPageRoute(builder: (context) => const ReportsPage());
          case '/nova-receita':
          case '/nova-despesa':
            return MaterialPageRoute(builder: (context) => const FinancialPage());
          case '/clientes':
            return MaterialPageRoute(builder: (context) => const TeamPage());
          default:
            return null;
        }
      },
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute(builder: (context) => const MainLayout());
      },
    );
  }
}

/// Widget responsável por preparar o ambiente (emulador, seed) antes de mostrar o app
class AppInitialization extends StatefulWidget {
  const AppInitialization({super.key});

  @override
  State<AppInitialization> createState() => _AppInitializationState();
}

class _AppInitializationState extends State<AppInitialization> {
  bool _isInitialized = false;
  String _statusMessage = 'Iniciando sistema...';

  @override
  void initState() {
    super.initState();
    _setupEnvironment();
  }

  Future<void> _setupEnvironment() async {
    if (kDebugMode) {
      try {
        setState(() => _statusMessage = 'Conectando ao Emulador...');
        
        String host = kIsWeb 
            ? 'localhost' 
            : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');

        debugPrint('--- [GRANITH] CONECTANDO EMULADORES EM: $host ---');

        // Nota: Só deve chamar useAuthEmulator se ainda não estiver conectado,
        // mas o plugin geralmente lida com isso. Se der erro de "já conectado", 
        // envolva em try-catch específico.
        try {
          await FirebaseAuth.instance.useAuthEmulator(host, 9099);
          
          FirebaseFirestore.instance.useFirestoreEmulator(host, 8089);
          
          // FIX CRÍTICO PARA WEB:
          // Força configurações para evitar travamentos e logs vazios no emulador.
          // Desabilitar SSL e Persistência é essencial para conexão estável,ki com localhost.
          FirebaseFirestore.instance.settings = Settings(
            host: '$host:8089',       // 🔧 ADD THIS
            persistenceEnabled: false,
            sslEnabled: false,
          );

          await FirebaseStorage.instance.useStorageEmulator(host, 9199);
        } catch (e) {
          debugPrint('Aviso: Emulador possivelmente já conectado: $e');
        }
        
        debugPrint('🟢 [GRANITH] AMBIENTE LOCAL PRONTO');
        
        setState(() => _statusMessage = 'Populando Banco de Dados...');
        
        // Pequeno delay para garantir que a conexão foi estabelecida
        await Future.delayed(const Duration(milliseconds: 500));

        // Agora rodamos o seeder SEM bloquear a UI (a UI é este widget com o loading)
        final seeder = DatabaseSeeder();
        // Timeout reduzido para não travar muito a experiência
        await seeder.ensureSyncedWithEmulator(timeoutSeconds: 15);
        
      } catch (e) {
        debugPrint('🔴 [GRANITH] ERRO NA INICIALIZAÇÃO LOCAL: $e');
      }
    }

    // Finaliza inicialização
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se já inicializou, mostra o AuthWrapper
    if (_isInitialized) {
      return const AuthWrapper();
    }

    // Enquanto inicializa, mostra tela de Loading bonita
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
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