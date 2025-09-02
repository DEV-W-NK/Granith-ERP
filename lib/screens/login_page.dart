import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/Services/auth_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isDisposed = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _setupAnimation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Erro ao inicializar Firebase: $e');
    }
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    EasyLoading.show(status: 'Fazendo login...');
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      _setStateIfMounted(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      _setStateIfMounted(() {
        _errorMessage = 'Erro inesperado: ${e.toString()}';
      });
    } finally {
      EasyLoading.dismiss();
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  void _clearError() {
    _setStateIfMounted(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark, // Fundo escuro do theme
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildLoginCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo da aplicação - Adicione sua logo Granith aqui
        const SizedBox(height: 20),
        Icon(
          Icons.home_work_outlined,
          size: 80,
          color: AppColors.accentGold, // Dourado do theme
        ),
        const SizedBox(height: 20),
        Text(
          'GRANITH',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.accentGold, // Dourado do theme
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),

        // Card principal
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark, // Superfície escura do theme
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Título
              Text(
                'Bem-vindo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary, // Texto primário do theme
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'Use sua conta Google para continuar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, // Texto secundário do theme
                ),
              ),
              const SizedBox(height: 40),

              // Botão do Google
              _buildGoogleButton(),

              // Mensagem de erro (se houver)
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                _buildErrorBox(),
              ],

              const SizedBox(height: 30),

              // Copyright
              Text(
                '© ${DateTime.now().year} Granith',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted, // Texto muted do theme
                ),
              ),

              // Indicador de plataforma (apenas para debug)
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  kIsWeb ? 'Web Version' : 'Mobile Version',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold, // Dourado do theme
        foregroundColor: AppColors.primaryDark, // Texto escuro
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone do Google (mantido do original)
          // Texto do botão
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryDark),
              ),
            )
          else
            const Text(
              'Entrar com Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.1), // Vermelho com opacidade
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentRed),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.accentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.accentRed, fontSize: 14),
            ),
          ),
          InkWell(
            onTap: _clearError,
            child: Icon(Icons.close, size: 18, color: AppColors.accentRed),
          ),
        ],
      ),
    );
  }
}
