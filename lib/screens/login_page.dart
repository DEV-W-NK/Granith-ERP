import 'package:flutter/material.dart';
import 'package:project_granith/controllers/logincontroller.dart';
import 'package:project_granith/widgets/animations/animation_background.dart';
import 'package:project_granith/widgets/components/login_logo.dart';
import 'package:project_granith/widgets/components/GranitCard.dart';
import 'package:project_granith/widgets/login/login_form_card.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/themes/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            AnimatedBackground(controller: _backgroundController),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isDesktop ? _buildDesktopView(context) : _buildMobileView(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: GranitCard(
            backgroundColor: AppColors.surfaceDark.withOpacity(0.85),
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo ao Granith ERP', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.accentGold)),
                const SizedBox(height: 12),
                Text(
                  'Painel de controle moderno para faturamento, estoque e finanças com métricas em tempo real.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    _buildFeatureBox(Icons.pie_chart_outline, 'Dashboard de DRE', 'Visualização de receitas e despesas em um só lugar', AppColors.accentBlue),
                    _buildFeatureBox(Icons.timeline, 'Indicadores Inteligentes', 'Taxas, crescimento e comparaçõa mensal', AppColors.accentGreen),
                    _buildFeatureBox(Icons.security, 'Autenticação Segura', 'Login com Google e sessões criptografadas', AppColors.accentGold),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Comece digitando seu e-mail da empresa e conectando com Google. Em seguida, acesse o painel de administração.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              LoginLogo(parentController: _mainController),
              const SizedBox(height: 32),
              LoginFormCard(parentController: _mainController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoginLogo(parentController: _mainController),
        const SizedBox(height: 20),
        _buildFeatureBox(Icons.pie_chart_outline, 'DRE Rápido', 'Receitas e despesas em tempo real', AppColors.accentBlue, compact: true),
        const SizedBox(height: 8),
        _buildFeatureBox(Icons.timeline, 'Insights', 'Indicadores de performance', AppColors.accentGreen, compact: true),
        const SizedBox(height: 8),
        _buildFeatureBox(Icons.security, 'Login Seguro', 'Google OAuth + proteção', AppColors.accentGold, compact: true),
        const SizedBox(height: 20),
        LoginFormCard(parentController: _mainController),
      ],
    );
  }

  Widget _buildFeatureBox(IconData icon, String title, String desc, Color iconColor, {bool compact = false}) {
    return GranitCard(
      backgroundColor: AppColors.secondaryDark.withOpacity(0.8),
      borderRadius: BorderRadius.circular(16),
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
