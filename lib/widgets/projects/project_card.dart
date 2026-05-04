import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/project_image.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool isListView;
  final ProjectBudgetService? budgetService;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    this.isListView = false,
    this.budgetService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            // Borda vermelha sutil se overBudget ou overdue
            color:
                project.isOverBudget || project.isOverdue
                    ? Colors.redAccent.withOpacity(0.35)
                    : AppColors.borderColor,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accentGold.withOpacity(0.1),
          highlightColor: AppColors.accentGold.withOpacity(0.05),
          child: isListView ? _buildListContent() : _buildGridContent(),
        ),
      ),
    );
  }

  // ─── Grid ─────────────────────────────────────────────────────────────────

  Widget _buildGridContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagem + badges flutuantes
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ProjectImageWidget(
                  imageUrl: project.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Gradiente inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.surfaceDark.withOpacity(0.8),
                        AppColors.surfaceDark,
                      ],
                    ),
                  ),
                ),
              ),

              // Status badge
              Positioned(
                top: 12,
                left: 12,
                child: _StatusBadge(project: project),
              ),

              // Badges de alerta (overdue / overBudget) — empilhados à direita
              Positioned(
                top: 12,
                right: 44,
                child: _AlertBadges(project: project),
              ),

              // Menu
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: _buildPopupMenu(iconColor: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // Conteúdo inferior
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nome + cliente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.client,
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MeasuredProgressBar(project: project),
                    const SizedBox(height: 10),
                    _BudgetBar(project: project, budgetService: budgetService),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Widget _buildListContent() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Imagem
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProjectImageWidget(
              imageUrl: project.imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),

          // Infos principais
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(project: project, small: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.client,
                  style: TextStyle(
                    color: AppColors.accentGold.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.textMuted.withOpacity(0.7),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        project.location,
                        style: TextStyle(
                          color: AppColors.textMuted.withOpacity(0.85),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _AlertBadges(project: project, inline: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Budget + barra
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BudgetValues(project: project, budgetService: budgetService),
                const SizedBox(height: 8),
                _MeasuredProgressBar(project: project),
                const SizedBox(height: 8),
                _BudgetBar(project: project, budgetService: budgetService),
              ],
            ),
          ),
          const SizedBox(width: 10),

          _buildPopupMenu(),
        ],
      ),
    );
  }

  // ─── Popup menu ───────────────────────────────────────────────────────────

  Widget _buildPopupMenu({Color? iconColor}) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: iconColor ?? AppColors.textMuted,
        size: 22,
      ),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      offset: const Offset(0, 40),
      itemBuilder:
          (_) => [
            _menuItem(
              'view',
              Icons.visibility_rounded,
              'Ver detalhes',
              AppColors.accentBlue,
            ),
            _menuItem(
              'edit',
              Icons.edit_rounded,
              'Editar',
              AppColors.accentGold,
            ),
            _menuItem(
              'delete',
              Icons.delete_rounded,
              'Excluir',
              AppColors.accentRed,
            ),
          ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            onTap();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Project project;
  final bool small;

  const _StatusBadge({required this.project, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color:
            small
                ? project.status.color.withOpacity(0.15)
                : AppColors.surfaceDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: project.status.color.withOpacity(0.4),
          width: 1,
        ),
        boxShadow:
            small
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: project.status.color),
          const SizedBox(width: 5),
          Text(
            project.status.displayName,
            style: TextStyle(
              color: small ? project.status.color : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert badges ────────────────────────────────────────────────────────────

class _AlertBadges extends StatelessWidget {
  final Project project;
  final bool inline; // true = Row horizontal, false = Column empilhada

  const _AlertBadges({required this.project, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (project.isOverBudget) {
      badges.add(
        _AlertChip(
          icon: Icons.trending_up,
          label: 'Estourado',
          color: Colors.redAccent,
        ),
      );
    }

    if (project.isOverdue) {
      badges.add(
        _AlertChip(
          icon: Icons.schedule,
          label: 'Atrasado',
          color: Colors.orangeAccent,
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children:
            badges.expand((b) => [b, const SizedBox(width: 4)]).toList()
              ..removeLast(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          badges.expand((b) => [b, const SizedBox(height: 4)]).toList()
            ..removeLast(),
    );
  }
}

class _AlertChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AlertChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Budget bar (reativa via stream) ─────────────────────────────────────────

class _MeasuredProgressBar extends StatelessWidget {
  final Project project;

  const _MeasuredProgressBar({required this.project});

  @override
  Widget build(BuildContext context) {
    final hasMeasurementProgress = project.hasMeasuredProgress;
    final pct = (project.progressPercentage / 100).clamp(0.0, 1.0);
    final barColor =
        hasMeasurementProgress
            ? AppColors.accentBlue
            : AppColors.textMuted.withOpacity(0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hasMeasurementProgress
                    ? 'Avanco medido'
                    : 'Avanco estimado indisponivel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      hasMeasurementProgress
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hasMeasurementProgress
                  ? '${project.progressPercentage.toStringAsFixed(1)}%'
                  : '--',
              style: TextStyle(
                color: barColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (_, constraints) {
            final maxW = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 6,
                  width: maxW,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 6,
                  width: maxW * pct,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow:
                        hasMeasurementProgress
                            ? [
                              BoxShadow(
                                color: barColor.withOpacity(0.35),
                                blurRadius: 4,
                              ),
                            ]
                            : null,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final Project project;
  final ProjectBudgetService? budgetService;

  const _BudgetBar({required this.project, this.budgetService});

  @override
  Widget build(BuildContext context) {
    if (project.id.isEmpty || project.budget == 0) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<ProjectBudgetSnapshot>(
      stream: (budgetService ?? ProjectBudgetService()).watchProjectBudget(
        projectId: project.id,
        budgetPrevisto: project.budget,
      ),
      builder: (context, snap) {
        final s =
            snap.data ??
            ProjectBudgetSnapshot.empty(project.id, project.budget);

        final pct = (s.percentualConsumido / 100).clamp(0.0, 1.0);
        final barColor =
            s.isOverBudget
                ? Colors.redAccent
                : s.isNearLimit
                ? Colors.orangeAccent
                : Colors.greenAccent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.isOverBudget ? 'Orçamento estourado' : 'Budget consumido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          s.isOverBudget
                              ? Colors.redAccent
                              : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.percentualConsumido.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: barColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Barra corrigida — usa LayoutBuilder para evitar double.infinity
            LayoutBuilder(
              builder: (_, constraints) {
                final maxW = constraints.maxWidth;
                return Stack(
                  children: [
                    // Fundo
                    Container(
                      height: 6,
                      width: maxW,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Preenchimento
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: 6,
                      width: maxW * pct,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: barColor.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ─── Budget values (para list view) ──────────────────────────────────────────

class _BudgetValues extends StatelessWidget {
  final Project project;
  final ProjectBudgetService? budgetService;

  const _BudgetValues({required this.project, this.budgetService});

  @override
  Widget build(BuildContext context) {
    if (project.id.isEmpty) return const SizedBox.shrink();

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return StreamBuilder<ProjectBudgetSnapshot>(
      stream: (budgetService ?? ProjectBudgetService()).watchProjectBudget(
        projectId: project.id,
        budgetPrevisto: project.budget,
      ),
      builder: (context, snap) {
        final s =
            snap.data ??
            ProjectBudgetSnapshot.empty(project.id, project.budget);

        final valueColor =
            s.isOverBudget ? Colors.redAccent : AppColors.accentGreen;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currency.format(s.custoRealizado),
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'de ${currency.format(s.budgetPrevisto)}',
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            if (s.isOverBudget) ...[
              const SizedBox(height: 2),
              Text(
                '+${currency.format(s.custoRealizado - s.budgetPrevisto)}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
