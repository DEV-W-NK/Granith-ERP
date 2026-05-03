import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class SubscriptionDashboard extends StatefulWidget {
  const SubscriptionDashboard({super.key});

  @override
  State<SubscriptionDashboard> createState() => _SubscriptionDashboardState();
}

class _SubscriptionDashboardState extends State<SubscriptionDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().loadUsageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubscriptionController>();
    final auth = context.watch<AuthViewModel>();
    final canSync = auth.isAdminUser ||
        auth.hasPermission('billing.manage') ||
        auth.hasPermission('infra.sync_usage') ||
        auth.hasPermission('settings.manage');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Uso da Plataforma'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            )
          : controller.currentUsage == null
              ? const Center(
                  child: Text(
                    'Nenhum dado de uso foi encontrado.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        controller.currentUsage!,
                        canSync: canSync,
                        controller: controller,
                      ),
                      const SizedBox(height: 24),
                      _buildSummaryGrid(controller.currentUsage!),
                      const SizedBox(height: 24),
                      _buildUsageTimeline(controller.currentUsage!),
                      const SizedBox(height: 24),
                      _buildInterpretationCard(controller.currentUsage!),
                      if (!controller.currentUsage!.hasSnapshot) ...[
                        const SizedBox(height: 24),
                        _buildActivationCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(
    UsageStatsModel usage, {
    required bool canSync,
    required SubscriptionController controller,
  }) {
    final periodFormat = DateFormat('dd/MM');
    final periodLabel =
        '${periodFormat.format(usage.periodStart)} - ${periodFormat.format(usage.periodEnd)}';
    final status = _statusPresentation(usage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.18),
            AppColors.surfaceDark.withValues(alpha: 0.86),
            AppColors.auraCyan.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.22),
        ),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            label: status.label,
            color: status.color,
          ),
          const SizedBox(height: 16),
          const Text(
            'Visao simples do uso do sistema',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aqui voce acompanha o ritmo de uso, o volume de arquivos e o tamanho da base de dados de forma executiva, sem detalhes tecnicos desnecessarios.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.date_range_rounded,
                label: 'Periodo analisado: $periodLabel',
              ),
              _InfoPill(
                icon: Icons.sync_rounded,
                label: usage.sourceLabel,
              ),
              if (usage.lastSyncedAt != null)
                _InfoPill(
                  icon: Icons.schedule_rounded,
                  label:
                      'Atualizado em ${DateFormat('dd/MM HH:mm').format(usage.lastSyncedAt!.toLocal())}',
                ),
            ],
          ),
          if (canSync) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: controller.isSyncing
                  ? null
                  : () async {
                      final success = await controller.syncUsageData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.feedbackMessage ??
                                (success
                                    ? 'Dados atualizados com sucesso.'
                                    : 'Falha ao atualizar os dados.'),
                          ),
                          backgroundColor:
                              success ? AppColors.accentBlue : AppColors.accentRed,
                        ),
                      );
                    },
              icon: controller.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                controller.isSyncing ? 'Atualizando...' : 'Atualizar dados',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(UsageStatsModel usage) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          title: 'Atividade do sistema',
          value: _formatCompactNumber(usage.observedOperations),
          subtitle: 'interacoes registradas no periodo',
          color: AppColors.accentBlue,
        ),
        _MetricCard(
          title: 'Base de dados',
          value: '${usage.databaseUsedGB.toStringAsFixed(2)} GB',
          subtitle: usage.databaseUsedMB > 0
              ? 'tamanho atual da base'
              : 'medicao indisponivel no momento',
          color: AppColors.accentGold,
        ),
        _MetricCard(
          title: 'Arquivos armazenados',
          value: '${usage.storageUsedGB.toStringAsFixed(2)} GB',
          subtitle: usage.storageUsedMB > 0
              ? 'documentos e arquivos do sistema'
              : 'medicao indisponivel no momento',
          color: AppColors.auraCyan,
        ),
        _MetricCard(
          title: 'Pico diario',
          value: _formatCompactNumber(usage.peakDayOperations),
          subtitle: 'dia mais movimentado do periodo',
          color: AppColors.accentGreen,
        ),
      ],
    );
  }

  Widget _buildUsageTimeline(UsageStatsModel usage) {
    final entries = usage.dailyOperations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.62),
        ),
        boxShadow: AppColors.glowShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movimento ao longo dos dias',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            usage.hasUsageData
                ? 'Uma leitura simples da atividade do sistema no periodo analisado.'
                : 'Ainda nao ha dados suficientes para montar a curva de uso.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            const _SectionEmptyCopy(
              title: 'Sem historico disponivel',
              message:
                  'Depois da primeira sincronizacao, esta area passa a mostrar a variacao diaria de uso.',
            )
          else ...[
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _TimelineChartPainter(
                  values: entries.map((entry) => entry.value.toDouble()).toList(),
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: entries.reversed.take(6).map((entry) {
                return _InfoPill(
                  icon: Icons.timeline_rounded,
                  label:
                      '${_formatDateLabel(entry.key)}: ${_formatCompactNumber(entry.value)}',
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterpretationCard(UsageStatsModel usage) {
    final partialMetrics = <String>[];
    if (usage.databaseUsedMB <= 0) {
      partialMetrics.add('base de dados');
    }
    if (usage.storageUsedMB <= 0) {
      partialMetrics.add('arquivos');
    }

    final partialLabel = partialMetrics.isEmpty
        ? 'Todos os indicadores principais foram carregados.'
        : 'Os indicadores de ${partialMetrics.join(' e ')} ainda nao estao disponiveis neste ambiente.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.62),
        ),
        boxShadow: AppColors.glowShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leitura rapida',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            partialLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const _ReadingPoint(
            title: 'Atividade do sistema',
            body:
                'Mostra o volume de uso do periodo e ajuda a entender crescimento, picos e sazonalidade.',
          ),
          const SizedBox(height: 10),
          const _ReadingPoint(
            title: 'Base e arquivos',
            body:
                'Ajudam a acompanhar expansao de dados e armazenamento sem precisar abrir o painel tecnico do Supabase.',
          ),
          const SizedBox(height: 10),
          const _ReadingPoint(
            title: 'Uso pratico',
            body:
                'Use este painel como acompanhamento interno. Para faturamento oficial do Supabase, continue considerando o dashboard da propria plataforma.',
          ),
        ],
      ),
    );
  }

  Widget _buildActivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.25),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primeira sincronizacao pendente',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Assim que os dados forem sincronizados pela primeira vez, este painel passa a exibir atividade, armazenamento e historico de uso automaticamente.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  _UsageStatusPresentation _statusPresentation(UsageStatsModel usage) {
    final lower = usage.sourceLabel.toLowerCase();
    if (!usage.hasSnapshot) {
      return const _UsageStatusPresentation(
        label: 'Aguardando sincronizacao',
        color: AppColors.accentGold,
      );
    }
    if (lower.contains('parciais')) {
      return const _UsageStatusPresentation(
        label: 'Dados parciais',
        color: AppColors.accentGold,
      );
    }
    return const _UsageStatusPresentation(
      label: 'Dados atualizados',
      color: AppColors.accentGreen,
    );
  }

  String _formatDateLabel(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) {
      return isoDate;
    }
    return DateFormat('dd/MM').format(parsed);
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}

class _UsageStatusPresentation {
  final String label;
  final Color color;

  const _UsageStatusPresentation({
    required this.label,
    required this.color,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: AppColors.glowShadows(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingPoint extends StatelessWidget {
  final String title;
  final String body;

  const _ReadingPoint({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.accentBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionEmptyCopy extends StatelessWidget {
  final String title;
  final String message;

  const _SectionEmptyCopy({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _TimelineChartPainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.30),
          color.withValues(alpha: 0.00),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;
    final step =
        values.length == 1 ? size.width : size.width / (values.length - 1);

    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final normalized = (values[i] - minValue) / range;
      final y =
          size.height - (normalized * size.height * 0.78) - (size.height * 0.11);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final previousX = (i - 1) * step;
        final previousNormalized = (values[i - 1] - minValue) / range;
        final previousY = size.height -
            (previousNormalized * size.height * 0.78) -
            (size.height * 0.11);
        final controlX = previousX + (x - previousX) / 2;
        path.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TimelineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
