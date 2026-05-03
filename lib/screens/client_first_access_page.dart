import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class ClientFirstAccessPage extends StatefulWidget {
  const ClientFirstAccessPage({super.key});

  @override
  State<ClientFirstAccessPage> createState() => _ClientFirstAccessPageState();
}

class _ClientFirstAccessPageState extends State<ClientFirstAccessPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteFirstAccess() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    await EasyLoading.show(status: 'Definindo senha...');

    try {
      await _authService.completeClientFirstAccess(
        password: _passwordController.text,
      );

      await EasyLoading.dismiss();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Primeiro acesso concluido'),
            content: const Text(
              'Sua senha foi definida com sucesso. Agora voce sera redirecionado para a tela de login para entrar normalmente com e-mail e senha.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _authService.signOut();
                },
                child: const Text('Ir para login'),
              ),
            ],
          );
        },
      );
    } on AppAuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel concluir o primeiro acesso.';
    } finally {
      await EasyLoading.dismiss();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final account = auth.primaryClientAccount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.borderColor.withValues(alpha: 0.65),
                  ),
                  boxShadow: AppColors.glowShadows(),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.accentGold.withValues(alpha: 0.14),
                          border: Border.all(
                            color: AppColors.accentGold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Text(
                          'Primeiro acesso do cliente',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        account?.name ?? 'Portal do cliente',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Defina agora sua senha de acesso. Depois disso, suas proximas entradas acontecerao normalmente pela tela de login com e-mail e senha.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nova senha',
                          hintText: 'Minimo de 8 caracteres',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a nova senha.';
                          }
                          if (value.trim().length < 8) {
                            return 'Use pelo menos 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nova senha',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Confirme a nova senha.';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas nao conferem.';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  AppColors.accentRed.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.accentRed,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _handleCompleteFirstAccess,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Salvar senha e continuar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
