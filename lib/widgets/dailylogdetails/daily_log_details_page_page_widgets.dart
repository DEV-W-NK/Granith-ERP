import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/DailyLogsViewModel.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_card.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_form_dialog.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class DailyLogsPageView extends StatelessWidget {
  const DailyLogsPageView({super.key});

  @override
  Widget build(BuildContext context) {
    // Injetamos o ViewModel que servirá esta View
    return ChangeNotifierProvider(
      create:
          (context) => DailyLogsViewModel(context.read<DailyLogController>()),
      child: const _DailyLogsPageContent(),
    );
  }
}

class _DailyLogsPageContent extends StatelessWidget {
  const _DailyLogsPageContent();

  void _openForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DailyLogFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 768;
    final viewModel = context.watch<DailyLogsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: ResponsiveLayout.pagePadding(width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DailyLogsHeader(isDesktop: isDesktop),
            if (!isDesktop) ...[
              const SizedBox(height: 16),
              const _AiInsightsButton(fullWidth: true),
            ],
            SizedBox(height: isDesktop ? 32 : 20),
            Expanded(
              child:
                  viewModel.isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      )
                      : viewModel.logs.isEmpty
                      ? const _DailyLogsEmptyState()
                      : ListView.separated(
                        itemCount: viewModel.logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return DailyLogCard(log: viewModel.logs[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          !isDesktop
              ? FloatingActionButton(
                onPressed: () => _openForm(context),
                backgroundColor: AppColors.accentGold,
                child: const Icon(Icons.add, color: AppColors.primaryDark),
              )
              : null,
    );
  }
}

class _DailyLogsHeader extends StatelessWidget {
  final bool isDesktop;
  const _DailyLogsHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diário de Obras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registro diário de atividades e progresso',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop)
          Row(
            children: [
              const _AiInsightsButton(),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    () => showDialog(
                      context: context,
                      builder: (_) => const DailyLogFormDialog(),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Novo Registro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AiInsightsButton extends StatelessWidget {
  final bool fullWidth;
  const _AiInsightsButton({this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DailyLogsViewModel>();

    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withOpacity(0.8),
            const Color(0xFF673AB7).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(viewModel.getAiInsight())));
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Insights IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyLogsEmptyState extends StatelessWidget {
  const _DailyLogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum diário registrado',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre o progresso das obras hoje para gerar histórico.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
