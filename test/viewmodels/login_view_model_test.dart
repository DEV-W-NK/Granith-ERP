import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/LoginViewModel.dart';
import 'package:project_granith/services/auth_service.dart';

import '../helpers/fake_auth_service.dart';

Future<void> _noopShow({String? status}) async {}
Future<void> _noopDismiss() async {}

void main() {
  group('LoginViewModel', () {
    test('bloqueia login por e-mail se campos estiverem vazios', () async {
      final authService = FakeAuthService();
      final viewModel = LoginViewModel(
        authService: authService,
        showLoading: _noopShow,
        dismissLoading: _noopDismiss,
        isWeb: false,
      );

      final result = await viewModel.handleEmailPasswordSignIn();

      expect(result, isFalse);
      expect(
        viewModel.errorMessage,
        'Informe e-mail e senha para prosseguir.',
      );
      expect(authService.lastEmail, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('envia e-mail e senha ao service quando formulario esta valido', () async {
      final authService = FakeAuthService();
      final viewModel = LoginViewModel(
        authService: authService,
        showLoading: _noopShow,
        dismissLoading: _noopDismiss,
        isWeb: false,
      );
      viewModel.setEmail('cliente@granith.com');
      viewModel.setPassword('12345678');

      final result = await viewModel.handleEmailPasswordSignIn();

      expect(result, isTrue);
      expect(authService.lastEmail, 'cliente@granith.com');
      expect(authService.lastPassword, '12345678');
      expect(viewModel.errorMessage, isNull);
    });

    test('expoe erro de link expirado vindo do redirect web', () {
      final viewModel = LoginViewModel(
        authService: FakeAuthService(),
        showLoading: _noopShow,
        dismissLoading: _noopDismiss,
        isWeb: true,
        initialUri: Uri.parse(
          'http://localhost:3000/?error=access_denied&error_code=otp_expired',
        ),
      );

      expect(
        viewModel.errorMessage,
        'Esse link de acesso expirou ou ja foi usado. Clique em "Receber link de acesso" para solicitar um novo convite.',
      );
    });

    test('propaga AppAuthException ao pedir magic link', () async {
      final authService = FakeAuthService()
        ..magicLinkError = const AppAuthException(
          code: 'magic_link_failed',
          message: 'Falha no envio do link.',
        );
      final viewModel = LoginViewModel(
        authService: authService,
        showLoading: _noopShow,
        dismissLoading: _noopDismiss,
        isWeb: false,
      );
      viewModel.setEmail('cliente@granith.com');

      final result = await viewModel.handleMagicLinkSignIn();

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'Falha no envio do link.');
      expect(authService.magicLinkCalled, isTrue);
    });
  });
}
