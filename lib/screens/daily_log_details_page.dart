import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class DailyLogDetailsPage extends StatefulWidget {
  final DailyLogModel dailyLog;

  const DailyLogDetailsPage({super.key, required this.dailyLog});

  @override
  State<DailyLogDetailsPage> createState() => _DailyLogDetailsPageState();
}

class _DailyLogDetailsPageState extends State<DailyLogDetailsPage> {
  late DailyLogModel _log;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _log = widget.dailyLog;
  }

  Future<void> _signLog() async {
    setState(() => _isSigning = true);

    try {
      await context.read<DailyLogController>().signLog(_log);
      if (!mounted) return;

      setState(() {
        _log = _log.copyWith(
          status: LogStatus.signed,
          signedAt: DateTime.now(),
          signedByCoordinatorName:
              _log.signedByCoordinatorName ??
              _log.coordinatorName ??
              'Conta administrativa',
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diario assinado e liberado para o cliente.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Nao foi possivel assinar o diario.' : message,
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailsHeader(log: _log),
              const SizedBox(height: 18),
              Expanded(
                child:
                    isWide
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: _ReportPanel(log: _log),
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 360,
                              child: _SignaturePanel(
                                log: _log,
                                isSigning: _isSigning,
                                onSign: _log.isSigned ? null : _signLog,
                              ),
                            ),
                          ],
                        )
                        : ListView(
                          children: [
                            _ReportPanel(log: _log),
                            const SizedBox(height: 14),
                            _SignaturePanel(
                              log: _log,
                              isSigning: _isSigning,
                              onSign: _log.isSigned ? null : _signLog,
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.log});

  final DailyLogModel log;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          tooltip: 'Voltar',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diário de Obras',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${log.projectName} - ${DateFormat('dd/MM/yyyy').format(log.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        _StatusPill(log: log),
      ],
    );
  }
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({required this.log});

  final DailyLogModel log;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoGrid(log: log),
          const SizedBox(height: 22),
          _SectionBlock(
            title: 'Atividades executadas',
            icon: Icons.construction_rounded,
            child: Text(
              log.activitiesDescription.trim().isEmpty
                  ? 'Sem atividades descritas.'
                  : log.activitiesDescription,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionBlock(
            title: 'Impedimentos e ocorrencias',
            icon: Icons.warning_amber_rounded,
            child: Text(
              log.impediments.trim().isEmpty
                  ? 'Nenhum impedimento registrado.'
                  : log.impediments,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (log.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionBlock(
              title: 'Fotos do relatorio',
              icon: Icons.photo_library_outlined,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    log.photoUrls
                        .map(
                          (url) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 130,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 130,
                                    height: 96,
                                    color: AppColors.backgroundMid,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.log});

  final DailyLogModel log;

  @override
  Widget build(BuildContext context) {
    final manpowerTotal = log.manpower.values.fold<int>(
      0,
      (sum, item) => sum + item,
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoTile(
          label: 'Data',
          value: DateFormat('dd/MM/yyyy').format(log.date),
          icon: Icons.calendar_today_rounded,
        ),
        _InfoTile(
          label: 'Clima manha',
          value: log.weatherMorning.name,
          icon: Icons.wb_sunny_outlined,
        ),
        _InfoTile(
          label: 'Clima tarde',
          value: log.weatherAfternoon.name,
          icon: Icons.cloud_outlined,
        ),
        _InfoTile(
          label: 'Mao de obra',
          value: manpowerTotal.toString(),
          icon: Icons.groups_rounded,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMid.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.accentGold),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundMid.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accentGold),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SignaturePanel extends StatelessWidget {
  const _SignaturePanel({
    required this.log,
    required this.isSigning,
    required this.onSign,
  });

  final DailyLogModel log;
  final bool isSigning;
  final VoidCallback? onSign;

  @override
  Widget build(BuildContext context) {
    final signedAt = log.signedAt;
    final signer = log.signedByCoordinatorName ?? log.coordinatorName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor(log).withValues(alpha: 0.34)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_rounded, color: _statusColor(log)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Painel de assinatura',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatusPill(log: log),
          const SizedBox(height: 16),
          _SignatureLine(
            label: 'Coordenador',
            value: log.coordinatorName ?? 'Sem coordenador definido',
          ),
          const SizedBox(height: 10),
          _SignatureLine(
            label: 'Assinado por',
            value: signer ?? 'Aguardando assinatura',
          ),
          const SizedBox(height: 10),
          _SignatureLine(
            label: 'Data da assinatura',
            value:
                signedAt == null
                    ? 'Ainda nao assinado'
                    : DateFormat('dd/MM/yyyy HH:mm').format(signedAt),
          ),
          const SizedBox(height: 18),
          Text(
            log.isSigned
                ? 'Relatorio bloqueado para edicao e liberado no portal do cliente.'
                : 'Ao assinar, o relatorio fica bloqueado para edicao e aparece no portal do cliente.',
            style: const TextStyle(color: AppColors.textMuted, height: 1.45),
          ),
          if (!log.isSigned) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSigning ? null : onSign,
                icon:
                    isSigning
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDark,
                          ),
                        )
                        : const Icon(Icons.verified_rounded),
                label: Text(
                  isSigning ? 'Assinando...' : 'Assinar e liberar ao cliente',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.log});

  final DailyLogModel log;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(log);
    final label =
        log.isSigned
            ? 'Assinado'
            : log.isPendingSignature
            ? 'Pendente'
            : 'Disponivel para assinatura';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _statusColor(DailyLogModel log) {
  if (log.isSigned) return AppColors.accentGreen;
  if (log.isPendingSignature) return AppColors.accentGold;
  return AppColors.accentBlue;
}
