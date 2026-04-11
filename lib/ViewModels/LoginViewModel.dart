import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  bool _isDisposed = false;

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
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    await EasyLoading.show(status: 'Autenticando...');

    try {
      await _authService.signInWithGoogle();
      if (_isDisposed) {
        await EasyLoading.dismiss();
        return false;
      }
      await EasyLoading.dismiss();
      _setLoading(false);
      return true;
    } on AppAuthException catch (e) {
      if (!_isDisposed) _errorMessage = e.message;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = 'Ocorreu um erro inesperado ao tentar entrar.';
      }
    } finally {
      await EasyLoading.dismiss();
      if (!_isDisposed) _setLoading(false);
    }

    return false;
  }

  Future<bool> handleEmailPasswordSignIn() async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    await EasyLoading.show(status: 'Autenticando com email...');

    if (_email.trim().isEmpty || _password.isEmpty) {
      _errorMessage = 'Informe e-mail e senha para prosseguir.';
      _setLoading(false);
      await EasyLoading.dismiss();
      return false;
    }

    try {
      await _authService.signInWithEmailPassword(
        email: _email,
        password: _password,
      );
      _setLoading(false);
      await EasyLoading.dismiss();
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel entrar com e-mail e senha.';
    }

    _setLoading(false);
    await EasyLoading.dismiss();
    return false;
  }

  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }
}
