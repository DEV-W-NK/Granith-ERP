import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:project_granith/controllers/logincontroller.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/themes/app_theme.dart';

/// Card principal de login com efeito de Glassmorphism.
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
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
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
    final controller = context.watch<LoginController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo ao Futuro',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acesse sua central de gestão integrada',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        TextField(
          onChanged: controller.setEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'E-mail',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintText: 'seu@email.com.br',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceDark.withOpacity(0.72),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          onChanged: controller.setPassword,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Senha',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintText: '••••••••',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceDark.withOpacity(0.72),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 52,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: controller.isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primaryDark)))
                : const Text('Entrar com e-mail', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),

        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Divider(color: AppColors.borderColor)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Divider(color: AppColors.borderColor)),
        ]),
        const SizedBox(height: 16),

        _buildGoogleButton(context, controller),

        if (controller.errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorBox(context, controller),
        ],

        const SizedBox(height: 20),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context, LoginController controller) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [AppColors.accentGold, Color(0xFFE5B800)]),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata, size: 32, color: AppColors.primaryDark),
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
    );
  }

  Widget _buildErrorBox(BuildContext context, LoginController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.5)),
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
          )
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} Granith Enterprise',
      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1.2),
    );
  }
}