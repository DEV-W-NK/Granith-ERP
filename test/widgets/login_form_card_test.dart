import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/LoginViewModel.dart';
import 'package:project_granith/widgets/login/login_form_card.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';

Future<void> _noopShow({String? status}) async {}
Future<void> _noopDismiss() async {}

class _LoginFormHarness extends StatefulWidget {
  const _LoginFormHarness({
    required this.viewModel,
  });

  final LoginViewModel viewModel;

  @override
  State<_LoginFormHarness> createState() => _LoginFormHarnessState();
}

class _LoginFormHarnessState extends State<_LoginFormHarness>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
      value: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>.value(
      value: widget.viewModel,
      child: MaterialApp(
        routes: {
          '/home': (_) => const Scaffold(body: Text('home')),
        },
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 460,
                child: LoginFormCard(parentController: _controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renderiza acoes principais do login', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    final viewModel = LoginViewModel(
      authService: FakeAuthService(),
      showLoading: _noopShow,
      dismissLoading: _noopDismiss,
      isWeb: false,
    );

    await tester.pumpWidget(_LoginFormHarness(viewModel: viewModel));

    expect(find.text('Entrar com e-mail'), findsOneWidget);
    expect(find.text('Conectar com Google'), findsOneWidget);
    expect(find.text('Receber link de acesso'), findsOneWidget);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('mostra erro visual ao tentar entrar sem credenciais', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    final viewModel = LoginViewModel(
      authService: FakeAuthService(),
      showLoading: _noopShow,
      dismissLoading: _noopDismiss,
      isWeb: false,
    );

    await tester.pumpWidget(_LoginFormHarness(viewModel: viewModel));
    await tester.tap(find.text('Entrar com e-mail'));
    await tester.pumpAndSettle();

    expect(
      find.text('Informe e-mail e senha para prosseguir.'),
      findsOneWidget,
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('mostra mensagem informativa ao solicitar link de acesso', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    final viewModel = LoginViewModel(
      authService: FakeAuthService(),
      showLoading: _noopShow,
      dismissLoading: _noopDismiss,
      isWeb: false,
    );

    await tester.pumpWidget(_LoginFormHarness(viewModel: viewModel));
    await tester.enterText(find.byType(TextField).first, 'cliente@granith.com');
    await tester.tap(find.text('Receber link de acesso'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Link enviado. Se a conta estiver habilitada'),
      findsOneWidget,
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
