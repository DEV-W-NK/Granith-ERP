import 'package:flutter/material.dart';
import 'package:project_granith/controllers/logincontroller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/animations/animation_background.dart';
import 'package:project_granith/widgets/components/GranitCard.dart';
import 'package:project_granith/widgets/components/login_logo.dart';
import 'package:project_granith/widgets/login/login_form_card.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _backgroundController;

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
        backgroundColor: Colors.transparent,
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
                    child: isDesktop
                        ? _buildDesktopView(context)
                        : _buildMobileView(context),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: GranitCard(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(40, 48, 40, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.accentBlue.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.accentBlue.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Text(
                    'Granith Command Surface',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Controle a operacao em um clima de fim de tarde.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.08,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Projetos, estoque, compras, financeiro e equipe respirando na mesma camada visual, com leitura rapida e profundidade de interface.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 32),
                _buildFeatureItem(
                  Icons.stacked_line_chart_rounded,
                  'Panorama executivo',
                  'KPIs e custos com hierarquia visual mais cinematografica.',
                  AppColors.accentBlue,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.blur_on_rounded,
                  'Superficies com aura',
                  'Cards transluidos, glow suave e contraste focado em leitura.',
                  AppColors.auraCyan,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.security,
                  'Acesso seguro',
                  'Entrada com e-mail e Google preservando o fluxo do produto.',
                  AppColors.accentGold,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoginLogo(parentController: _mainController),
              const SizedBox(height: 40),
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
        const SizedBox(height: 32),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFeatureBox(Icons.stacked_line_chart_rounded, 'KPIs', AppColors.accentBlue),
              const SizedBox(width: 12),
              _buildFeatureBox(Icons.blur_on_rounded, 'Aura UI', AppColors.auraCyan),
              const SizedBox(width: 12),
              _buildFeatureBox(Icons.security, 'Seguro', AppColors.accentGold),
            ],
          ),
        ),
        const SizedBox(height: 32),
        LoginFormCard(parentController: _mainController),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: AppColors.auraShadows(color),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBox(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: AppColors.auraShadows(color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
