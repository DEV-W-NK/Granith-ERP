import 'package:flutter/material.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_card.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_form_dialog.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/themes/app_theme.dart';

class DailyLogsPage extends StatefulWidget {
  const DailyLogsPage({super.key});

  @override
  State<DailyLogsPage> createState() => _DailyLogsPageState();
}

class _DailyLogsPageState extends State<DailyLogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyLogController>().loadLogs();
    });
  }

  void _openForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DailyLogFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final controller = context.watch<DailyLogController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diário de Obras',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registro diário de atividades e progresso',
                      style: TextStyle(color: AppColors.textMuted, fontSize: isDesktop ? 16 : 14),
                    ),
                  ],
                ),
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Registro', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Lista
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                  : controller.logs.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: controller.logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return DailyLogCard(log: controller.logs[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: !isDesktop 
        ? FloatingActionButton(
            onPressed: () => _openForm(context),
            backgroundColor: AppColors.accentGold,
            child: const Icon(Icons.add, color: AppColors.primaryDark),
          )
        : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Nenhum diário registrado', style: TextStyle(color: AppColors.textMuted, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Registre o progresso das obras hoje.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}