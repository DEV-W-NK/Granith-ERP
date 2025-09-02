import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading indicator personalizado
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold.withOpacity(0.3),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold,
                  ),
                ),
              ),
              const Icon(
                Icons.construction_rounded,
                color: AppColors.accentGold,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Carregando projetos...',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Aguarde um momento',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateProject; // Add this callback

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onCreateProject, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustração animada
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          hasFilters
                              ? AppColors.accentBlue.withOpacity(0.2)
                              : AppColors.accentGold.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      hasFilters
                          ? Icons.search_off_rounded
                          : Icons.construction_rounded,
                      size: 64,
                      color:
                          hasFilters
                              ? AppColors.accentBlue.withOpacity(0.7)
                              : AppColors.accentGold.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Título principal
            Text(
              hasFilters
                  ? 'Nenhum projeto encontrado'
                  : 'Seus projetos aparecerão aqui',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtítulo
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                hasFilters
                    ? 'Tente ajustar os filtros de busca ou criar um novo projeto'
                    : 'Comece criando seu primeiro projeto e acompanhe o progresso das suas obras',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // Botões de ação
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (hasFilters) ...[
                  OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.clear_all_rounded, size: 20),
                    label: const Text('Limpar Filtros'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: AppColors.borderColor.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onCreateProject, // Use the callback instead
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      hasFilters
                          ? 'Criar Novo Projeto'
                          : 'Criar Primeiro Projeto',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (!hasFilters) ...[
              const SizedBox(height: 40),

              // Cards de exemplo/dicas
              Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Text(
                      'Com projetos você pode:',
                      style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _FeatureCard(
                          icon: Icons.trending_up_rounded,
                          title: 'Acompanhar Progresso',
                          description: 'Monitore o avanço das suas obras',
                          color: AppColors.accentGreen,
                        ),
                        _FeatureCard(
                          icon: Icons.attach_money_rounded,
                          title: 'Controlar Custos',
                          description: 'Gerencie orçamentos e gastos',
                          color: AppColors.accentBlue,
                        ),
                        _FeatureCard(
                          icon: Icons.location_on_rounded,
                          title: 'Organizar Obras',
                          description: 'Mantenha tudo organizado',
                          color: AppColors.accentGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.accentRed.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar projetos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            description,
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}