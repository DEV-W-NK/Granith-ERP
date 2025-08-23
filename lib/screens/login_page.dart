import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/Services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // Service de autenticação
  final AuthService _authService = AuthService();
  
  // Estados da UI
  String? _errorMessage;
  bool _isLoading = false;
  bool _isDisposed = false;
  
  // Animações
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

  /// Inicializar Firebase
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Erro ao inicializar Firebase: $e');
    }
  }

  /// Configurar animações
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

  /// Verificar se o widget ainda está montado antes de atualizar o estado
  void _setStateIfMounted(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// Lidar com o login do Google
  Future<void> _handleGoogleSignIn() async {
    // Mostrar loading
    EasyLoading.show(status: 'Fazendo login...');
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar o service para fazer login
      await _authService.signInWithGoogle();
      
      // Login bem-sucedido - navegar para home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      // Tratar erros de autenticação
      _setStateIfMounted(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      // Tratar outros erros
      _setStateIfMounted(() {
        _errorMessage = 'Erro inesperado: ${e.toString()}';
      });
    } finally {
      // Esconder loading
      EasyLoading.dismiss();
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  /// Limpar mensagem de erro
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
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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

  /// Construir o card de login
  Widget _buildLoginCard(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo da aplicação
        
        // Card principal
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Título
              const Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A11CB),
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtítulo
              const Text(
                'Use sua conta Google para continuar',
                style: TextStyle(fontSize: 16, color: Colors.black54),
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
                '© ${DateTime.now().year} Enebras',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              
              // Indicador de plataforma (apenas para debug)
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  kIsWeb ? 'Web Version' : 'Mobile Version',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Construir botão do Google
  Widget _buildGoogleButton() {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isLoading ? null : () {
          _clearError();
          _handleGoogleSignIn();
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [              
              // Divisor
              VerticalDivider(color: Colors.grey.shade300),
              const SizedBox(width: 16),
              
              // Texto do botão
              const Expanded(
                child: Text(
                  'Entrar com Google',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Loading indicator
              if (_isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF6A11CB)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  /// Construir caixa de erro
  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
          // Botão para fechar o erro
          InkWell(
            onTap: _clearError,
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}