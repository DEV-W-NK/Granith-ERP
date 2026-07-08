import 'package:flutter/material.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/screens/daily_log_details_page.dart';
import 'package:project_granith/themes/app_theme.dart';

class DailyLogCard extends StatelessWidget {
  final DailyLogModel log;
  final VoidCallback? onEdit;
  final VoidCallback? onSign;
  final bool isSigning;

  const DailyLogCard({
    super.key,
    required this.log,
    this.onEdit,
    this.onSign,
    this.isSigning = false,
  });

  @override
  Widget build(BuildContext context) {
    final signatureColor = _signatureColor(log);

    return Container(
      decoration: AppDecorations.cardSurface(
        accent: signatureColor,
        emphasized: log.isPendingSignature,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyLogDetailsPage(dailyLog: log),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SignatureBadge(log: log),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  log.activitiesDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaPill(
                      icon: Icons.calendar_today_outlined,
                      label:
                          '${log.date.day}/${log.date.month}/${log.date.year}',
                    ),
                    _MetaPill(
                      icon: Icons.wb_sunny_outlined,
                      label: log.weatherMorning.name,
                    ),
                    if (log.coordinatorName?.trim().isNotEmpty == true)
                      _MetaPill(
                        icon: Icons.engineering_outlined,
                        label: log.coordinatorName!,
                      ),
                    if (log.isSigned)
                      _MetaPill(
                        icon: Icons.lock_rounded,
                        label: 'Bloqueado para edicao',
                        color: signatureColor,
                      ),
                  ],
                ),
                if (onEdit != null || onSign != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (onEdit != null)
                        OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color: AppColors.borderColor.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      if (onSign != null)
                        FilledButton.icon(
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
                                  : const Icon(Icons.draw_rounded, size: 18),
                          label: Text(
                            isSigning ? 'Assinando...' : 'Assinar relatorio',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: AppColors.primaryDark,
                          ),
                        ),
                    ],
                  ),
                ],
                if (log.isPendingSignature) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Pendente de assinatura do coordenador responsavel.',
                    style: TextStyle(
                      color: signatureColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _signatureColor(DailyLogModel log) {
    if (log.isSigned) return AppColors.accentGreen;
    if (log.isPendingSignature) return AppColors.accentGold;
    return AppColors.textMuted;
  }
}

class _SignatureBadge extends StatelessWidget {
  const _SignatureBadge({required this.log});

  final DailyLogModel log;

  @override
  Widget build(BuildContext context) {
    final color =
        log.isSigned
            ? AppColors.accentGreen
            : log.isPendingSignature
            ? AppColors.accentGold
            : AppColors.textMuted;
    final label =
        log.isSigned
            ? 'Assinado'
            : log.isPendingSignature
            ? 'Pendente'
            : 'Sem assinatura';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color = AppColors.textMuted,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final emphasized = color != AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: emphasized ? color : AppColors.textMuted,
            fontSize: 12,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
