import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/firebase_options.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'screens/main_layout.dart';
import 'screens/login_page.dart'; // Importar a tela de login
import 'services/auth_service.dart'; // Importar o serviço de auth

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GranithApp());
}

class GranithApp extends StatelessWidget {
  const GranithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Granith ERP',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(), // Usar wrapper de autenticação
      debugShowCheckedModeBanner: false,
      // Configuração de rotas
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainLayout(),
      },
      // Configurar EasyLoading
      builder: EasyLoading.init(),
    );
  }
}

/// Widget que gerencia o estado de autenticação
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Enquanto carrega
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // Se tem usuário logado
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: authService.isUserActive(),
            builder: (context, activeSnapshot) {
              if (activeSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              
              // Verificar se usuário está ativo
              if (activeSnapshot.data == true) {
                return const MainLayout();
              } else {
                // Usuário inativo - fazer logout
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authService.signOut();
                });
                return const LoginPage();
              }
            },
          );
        }
        
        // Não tem usuário logado
        return const LoginPage();
      },
    );
  }
}

/// Tela de splash/loading
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou nome do app
              Text(
                'GRANITH ERP',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 30),
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Carregando...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}