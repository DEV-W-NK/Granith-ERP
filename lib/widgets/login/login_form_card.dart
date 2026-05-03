import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/LoginViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class LoginFormCard extends StatelessWidget {
  final AnimationController parentController;

  const LoginFormCard({super.key, required this.parentController});

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: parentController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: parentController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    final contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: parentController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    return AnimatedBuilder(
      animation: parentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: Opacity(
            opacity: opacityAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.3,
                    ),
                    boxShadow: [
                      ...AppColors.glowShadows(AppColors.accentBlue),
                      ...AppColors.auraShadows(AppColors.accentGold),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: contentFadeAnimation,
                    child: const _CardContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Painel de comando',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre para acompanhar projetos, custos, operacao e equipe em uma unica superficie.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.45),
            ),
          ),
          child: const Text(
            'Colaboradores entram com e-mail e senha ou Google. Clientes recebem um link de acesso para entrar direto no portal. Se o link expirar, basta pedir outro abaixo.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: controller.setEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            hintText: 'seu@email.com.br',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: controller.setPassword,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Senha',
            hintText: '••••••••',
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : () async {
                    final success = await controller.handleEmailPasswordSignIn();
                    if (success && context.mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Entrar com e-mail',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.borderColor.withValues(alpha: 0.9))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou', style: TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(child: Divider(color: AppColors.borderColor.withValues(alpha: 0.9))),
          ],
        ),
        const SizedBox(height: 16),
        _buildGoogleButton(context, controller),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.isLoading
              ? null
              : () async {
                  await controller.handleMagicLinkSignIn();
                },
          icon: const Icon(Icons.mark_email_unread_outlined),
          label: const Text('Receber link de acesso'),
        ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorBox(context, controller),
        ],
        if (controller.infoMessage != null) ...[
          const SizedBox(height: 16),
          _buildInfoBox(context, controller),
        ],
        const SizedBox(height: 20),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context, LoginViewModel controller) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withValues(alpha: 0.92),
            const Color(0xFFFFD77A),
          ],
        ),
        boxShadow: AppColors.auraShadows(AppColors.accentGold),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: controller.isLoading
              ? null
              : () async {
                  final success = await controller.handleGoogleSignIn();
                  if (success && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
          child: Center(
            child: controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryDark),
                    ),
                  )
                : const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.g_mobiledata,
                          size: 32,
                          color: AppColors.primaryDark,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Conectar com Google',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(BuildContext context, LoginViewModel controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.errorMessage!,
              style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.accentRed),
            onPressed: controller.clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, LoginViewModel controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.infoMessage!,
              style: const TextStyle(color: AppColors.accentBlue, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.accentBlue,
            ),
            onPressed: controller.clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} Granith Enterprise',
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}
