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
      // Carrega os dados apenas se o controller estiver disponível no contexto
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
            // Header e Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
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
                ),
                
                // Área de Botões (Desktop)
                if (isDesktop)
                  Row(
                    children: [
                      // Botão de IA (Novo)
                      _buildAiButton(context),
                      
                      const SizedBox(width: 16),
                      
                      // Botão Novo Registro
                      ElevatedButton.icon(
                        onPressed: () => _openForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        label: const Text('Novo Registro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
              ],
            ),

            // Botão de IA (Mobile - aparece abaixo do título se for mobile)
            if (!isDesktop) ...[
              const SizedBox(height: 16),
              _buildAiButton(context, fullWidth: true),
            ],
            
            const SizedBox(height: 32),

            // Lista de Diários
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

  Widget _buildAiButton(BuildContext context, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withOpacity(0.8), // Roxo suave
            const Color(0xFF673AB7).withOpacity(0.8), // Azul/Roxo profundo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            // Ação Futura da IA
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🤖 Análise de IA: O clima chuvoso impactou 20% da produtividade esta semana.')),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Altura similar ao botão primário
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Insights IA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Nenhum diário registrado', style: TextStyle(color: AppColors.textMuted, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Registre o progresso das obras hoje para gerar histórico.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}