import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/services/auth_service_contract.dart';

typedef LoadingPresenter = Future<void> Function({String? status});
typedef LoadingDismiss = Future<void> Function();

enum LoginCredentialMode { email, username }

class LoginViewModel extends ChangeNotifier {
  final AuthServiceContract _authService;
  final LoadingPresenter _showLoading;
  final LoadingDismiss _dismissLoading;
  final bool _isWeb;
  final Uri? _initialUri;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _infoMessage;
  String? get infoMessage => _infoMessage;

  String _email = '';
  String get email => _email;

  String _username = '';
  String get username => _username;

  String _password = '';
  String get password => _password;

  LoginCredentialMode _credentialMode = LoginCredentialMode.email;
  LoginCredentialMode get credentialMode => _credentialMode;

  bool _isDisposed = false;

  LoginViewModel({
    AuthServiceContract? authService,
    LoadingPresenter? showLoading,
    LoadingDismiss? dismissLoading,
    bool isWeb = kIsWeb,
    Uri? initialUri,
  }) : _authService = authService ?? AuthService(),
       _showLoading = showLoading ?? EasyLoading.show,
       _dismissLoading = dismissLoading ?? EasyLoading.dismiss,
       _isWeb = isWeb,
       _initialUri = initialUri {
    _consumeInitialAuthRedirect();
  }

  void setEmail(String value) {
    if (_isDisposed) return;
    _email = value;
    notifyListeners();
  }

  void setUsername(String value) {
    if (_isDisposed) return;
    _username = value;
    notifyListeners();
  }

  void setPassword(String value) {
    if (_isDisposed) return;
    _password = value;
    notifyListeners();
  }

  void setCredentialMode(LoginCredentialMode value) {
    if (_isDisposed || _credentialMode == value) return;
    _credentialMode = value;
    _errorMessage = null;
    _infoMessage = null;
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
    _infoMessage = null;
    notifyListeners();
  }

  Future<bool> handleGoogleSignIn() async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    _infoMessage = null;
    await _showLoading(status: 'Autenticando...');

    try {
      await _authService.signInWithGoogle();
      if (_isDisposed) {
        await _dismissLoading();
        return false;
      }
      await _dismissLoading();
      _setLoading(false);
      return true;
    } on AppAuthException catch (e) {
      if (!_isDisposed) _errorMessage = e.message;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = 'Ocorreu um erro inesperado ao tentar entrar.';
      }
    } finally {
      await _dismissLoading();
      if (!_isDisposed) _setLoading(false);
    }

    return false;
  }

  Future<bool> handleEmailPasswordSignIn() async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    _infoMessage = null;
    await _showLoading(status: 'Autenticando com email...');

    if (_email.trim().isEmpty || _password.isEmpty) {
      _errorMessage = 'Informe e-mail e senha para prosseguir.';
      _setLoading(false);
      await _dismissLoading();
      return false;
    }

    try {
      await _authService.signInWithEmailPassword(
        email: _email,
        password: _password,
      );
      _setLoading(false);
      await _dismissLoading();
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel entrar com e-mail e senha.';
    }

    _setLoading(false);
    await _dismissLoading();
    return false;
  }

  Future<bool> handleUsernamePasswordSignIn() async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    _infoMessage = null;
    await _showLoading(status: 'Autenticando com usuario...');

    if (_username.trim().isEmpty || _password.isEmpty) {
      _errorMessage = 'Informe usuario e senha para prosseguir.';
      _setLoading(false);
      await _dismissLoading();
      return false;
    }

    try {
      await _authService.signInWithUsernamePassword(
        username: _username,
        password: _password,
      );
      _setLoading(false);
      await _dismissLoading();
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel entrar com usuario e senha.';
    }

    _setLoading(false);
    await _dismissLoading();
    return false;
  }

  Future<bool> handleMagicLinkSignIn() async {
    if (_isDisposed) return false;

    _setLoading(true);
    _errorMessage = null;
    _infoMessage = null;
    await _showLoading(status: 'Enviando link de acesso...');

    if (_email.trim().isEmpty) {
      _errorMessage = 'Informe o e-mail para receber o link de acesso.';
      _setLoading(false);
      await _dismissLoading();
      return false;
    }

    try {
      await _authService.sendMagicLink(email: _email, shouldCreateUser: false);
      if (!_isDisposed) {
        _infoMessage =
            'Link enviado. Se a conta estiver habilitada, voce recebera o acesso no e-mail informado.';
      }
      _setLoading(false);
      await _dismissLoading();
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel enviar o link de acesso.';
    }

    _setLoading(false);
    await _dismissLoading();
    return false;
  }

  void _consumeInitialAuthRedirect() {
    if (!_isWeb) return;

    final params = _collectAuthRedirectParams(_initialUri ?? Uri.base);
    final errorCode = params['error_code'];
    final errorDescription = params['error_description'];
    if (errorCode == null && errorDescription == null) {
      return;
    }

    _errorMessage = _mapRedirectError(
      errorCode: errorCode,
      errorDescription: errorDescription,
    );
  }

  Map<String, String> _collectAuthRedirectParams(Uri uri) {
    final params = <String, String>{...uri.queryParameters};

    final fragment = uri.fragment;
    if (fragment.isNotEmpty && fragment.contains('=')) {
      try {
        params.addAll(Uri.splitQueryString(fragment));
      } catch (_) {
        // Ignora fragments fora do formato de query string.
      }
    }

    return params;
  }

  String _mapRedirectError({String? errorCode, String? errorDescription}) {
    switch (errorCode) {
      case 'otp_expired':
        return 'Esse link de acesso expirou ou ja foi usado. Clique em "Receber link de acesso" para solicitar um novo convite.';
      case 'access_denied':
        return 'O link de acesso nao foi aceito. Solicite um novo convite para entrar no portal.';
      default:
        if (errorDescription != null && errorDescription.trim().isNotEmpty) {
          return errorDescription.replaceAll('+', ' ');
        }
        return 'Nao foi possivel concluir o acesso por link. Solicite um novo convite.';
    }
  }

  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }
}
