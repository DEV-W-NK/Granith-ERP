import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/services/auth_service.dart';

/// Controller responsável pela lógica de estado da tela de Login.
/// Segue o princípio de Responsabilidade Única (SRP).
class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  void setEmail(String value) {
    if (_isDisposed) return;
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    if (_isDisposed) return;
    _password = value;
    notifyListeners();
  }

  // 1. Mantemos a variável de segurança para evitar o erro "used after disposed"
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> handleGoogleSignIn() async {
    // Proteção inicial
    if (_isDisposed) return false;

    _setLoading(true);
    // Não precisamos limpar erro aqui se vamos usar o EasyLoading, mas mal não faz
    if (!_isDisposed) _errorMessage = null; 
    
    await EasyLoading.show(status: 'Autenticando...');

    try {
      await _authService.signInWithGoogle();
      
      // Se o widget foi descartado durante o await, paramos aqui
      if (_isDisposed) {
        await EasyLoading.dismiss();
        return false;
      }

      await EasyLoading.dismiss();
      _setLoading(false);
      return true;

    } on AuthException catch (e) {
      if (!_isDisposed) _errorMessage = e.message;
    } catch (e) {
      if (!_isDisposed) _errorMessage = 'Ocorreu um erro inesperado ao tentar entrar.';
    } finally {
      // O finally corre sempre. O EasyLoading é global, então deve ser fechado.
      await EasyLoading.dismiss();
      
      // Mas o _setLoading só pode ser chamado se o controller estiver vivo.
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
    return false;
  }

  Future<bool> handleEmailPasswordSignIn() async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    await EasyLoading.show(status: 'Autenticando com email...');

    await Future.delayed(const Duration(milliseconds: 800));

    if (_email.trim().isEmpty || _password.isEmpty) {
      _errorMessage = 'Informe e-mail e senha para prosseguir.';
      _setLoading(false);
      await EasyLoading.dismiss();
      return false;
    }

    _errorMessage = 'Login por e-mail/senha ainda não implementado; use Google.';
    _setLoading(false);
    await EasyLoading.dismiss();
    return false;
  }

  void _setLoading(bool value) {
    // BLOQUEIO DE SEGURANÇA: Impede o crash
    if (_isDisposed) return;
    
    _isLoading = value;
    notifyListeners();
  }
}