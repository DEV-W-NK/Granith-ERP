import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onTap,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final roleColor = _roleColor(employee.role);
    final statusColor = _statusColor(employee.status);
    final hasMenu = onDismiss != null || onDelete != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.54),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final footerGap =
              constraints.hasBoundedHeight
                  ? const Spacer()
                  : const SizedBox(height: 12);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.18),
                    child: Text(
                      employee.initials,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          employee.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasMenu) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<_EmployeeCardAction>(
                      tooltip: 'Acoes',
                      color: AppColors.surfaceDark,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _EmployeeCardAction.dismiss:
                            onDismiss?.call();
                            break;
                          case _EmployeeCardAction.delete:
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            if (!employee.isDismissed && onDismiss != null)
                              const PopupMenuItem(
                                value: _EmployeeCardAction.dismiss,
                                child: _EmployeeMenuItem(
                                  icon: Icons.person_remove_alt_1_rounded,
                                  label: 'Registrar desligamento',
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: _EmployeeCardAction.delete,
                                child: _EmployeeMenuItem(
                                  icon: Icons.delete_outline_rounded,
                                  label: 'Excluir cadastro',
                                  isDestructive: true,
                                ),
                              ),
                          ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _EmployeeChip(
                    label: employee.role.label,
                    color: roleColor,
                    icon: Icons.manage_accounts_rounded,
                  ),
                  _EmployeeChip(
                    label: _statusLabel(employee.status),
                    color: statusColor,
                    icon: Icons.circle_rounded,
                  ),
                ],
              ),
              Divider(
                color: AppColors.borderColor.withValues(alpha: 0.52),
                height: 22,
              ),
              _buildInfoRow(Icons.school_rounded, employee.educationLevel),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.payments_rounded,
                'Salario: ${currency.format(employee.baseSalary)}',
              ),
              const SizedBox(height: 8),
              if (employee.courses.isNotEmpty)
                _buildInfoRow(
                  Icons.card_membership_rounded,
                  '${employee.courses.split(',').length} curso(s) registrado(s)',
                ),
              footerGap,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accentGold.withValues(alpha: 0.42),
                    ),
                    foregroundColor: AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 17),
                  label: const Text('Ver detalhes'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _roleColor(EmployeeRole role) => switch (role) {
    EmployeeRole.gerente => AppColors.accentGold,
    EmployeeRole.coordenador => AppColors.purple,
    EmployeeRole.supervisor => AppColors.orange,
    EmployeeRole.funcionario => AppColors.accentBlue,
  };

  Color _statusColor(EmployeeStatus status) => switch (status) {
    EmployeeStatus.ativo => AppColors.accentGreen,
    EmployeeStatus.ferias => AppColors.accentBlue,
    EmployeeStatus.afastado => AppColors.orange,
    EmployeeStatus.desligado => AppColors.accentRed,
  };

  String _statusLabel(EmployeeStatus status) => switch (status) {
    EmployeeStatus.ativo => 'Ativo',
    EmployeeStatus.ferias => 'Ferias',
    EmployeeStatus.afastado => 'Afastado',
    EmployeeStatus.desligado => 'Desligado',
  };

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Nao informado' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _EmployeeChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
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
          ),
        ],
      ),
    );
  }
}

enum _EmployeeCardAction { dismiss, delete }

class _EmployeeMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _EmployeeMenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.accentRed : AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
