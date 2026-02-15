import 'package:flutter/material.dart';
import 'package:project_granith/controllers/logincontroller.dart';
import 'package:project_granith/widgets/animations/animation_background.dart';
import 'package:project_granith/widgets/components/login_logo.dart';
import 'package:project_granith/widgets/login/login_form_card.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/themes/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Injeção de dependência local para o Controller do Login
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            // Componente de Fundo (Independente)
            AnimatedBackground(controller: _backgroundController),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Componente de Logo (Independente)
                      LoginLogo(parentController: _mainController),
                      
                      const SizedBox(height: 40),
                      
                      // Componente de Card de Login (Independente)
                      LoginFormCard(parentController: _mainController),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}