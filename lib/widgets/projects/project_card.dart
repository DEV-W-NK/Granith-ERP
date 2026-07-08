import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
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
    final compactScreen = MediaQuery.sizeOf(context).width < 600;
    final alertColor =
        project.isOverBudget || project.isOverdue
            ? AppColors.accentRed
            : AppColors.borderColor;
    final cardAccent =
        project.isOverBudget || project.isOverdue
            ? AppColors.accentRed
            : AppColors.accentBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: AppDecorations.cardSurface(
        accent: cardAccent,
        emphasized: !compactScreen,
        elevated: !compactScreen,
        radius: 18,
      ).copyWith(
        border: Border.all(
          color: alertColor.withOpacity(compactScreen ? 0.40 : 0.58),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.accentGold.withOpacity(0.10),
          highlightColor: AppColors.accentGold.withOpacity(0.05),
          child:
              isListView
                  ? LayoutBuilder(
                    builder:
                        (context, constraints) =>
                            constraints.maxWidth < ResponsiveLayout.compact
                                ? _buildCompactListContent()
                                : _buildListContent(),
                  )
                  : _buildGridContent(),
        ),
      ),
    );
  }

  // ─── Grid ─────────────────────────────────────────────────────────────────

  Widget _buildGridContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenCompact = MediaQuery.sizeOf(context).width < 600;
        final compact = screenCompact || constraints.maxWidth < 420;
        final imageHeight = compact ? 118.0 : 150.0;
        final contentPadding =
            compact
                ? const EdgeInsets.fromLTRB(12, 10, 12, 12)
                : const EdgeInsets.fromLTRB(15, 14, 15, 15);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem + badges flutuantes
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
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
                    height: compact ? 84 : 92,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.backgroundDark.withOpacity(0.72),
                            AppColors.backgroundDark.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Status badge
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _StatusBadge(project: project),
                  ),

                  // Badges de alerta (overdue / overBudget) — empilhados à direita
                  if (!compact)
                    Positioned(
                      top: 8,
                      left: 10,
                      right: 8,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _AlertBadges(project: project),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: _buildPopupMenu(iconColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Conteúdo inferior
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      _CompactCardActions(
                        alerts: _AlertBadges(project: project, inline: true),
                        menu: _buildPopupMenu(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _ProjectTitleBlock(project: project, compact: compact),
                    SizedBox(height: compact ? 8 : 10),
                    if (compact)
                      _CompactProjectMetaLine(project: project)
                    else
                      _ProjectMetaWrap(project: project),
                    const Spacer(),
                    _MeasuredProgressBar(project: project),
                    if (!compact) ...[
                      const SizedBox(height: 10),
                      _BudgetBar(
                        project: project,
                        budgetService: budgetService,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
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

  Widget _buildCompactListContent() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProjectImageWidget(
                  imageUrl: project.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    Text(
                      project.location,
                      style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.85),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPopupMenu(),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusBadge(project: project, small: true),
              _AlertBadges(project: project, inline: true),
            ],
          ),
          const SizedBox(height: 12),
          _BudgetValues(project: project, budgetService: budgetService),
          const SizedBox(height: 8),
          _MeasuredProgressBar(project: project),
          const SizedBox(height: 8),
          _BudgetBar(project: project, budgetService: budgetService),
        ],
      ),
    );
  }

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

class _ProjectTitleBlock extends StatelessWidget {
  final Project project;
  final bool compact;

  const _ProjectTitleBlock({required this.project, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: 0,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.business_center_rounded,
              size: 13,
              color: AppColors.accentGold,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                project.client,
                style: TextStyle(
                  color: AppColors.accentGold.withOpacity(0.92),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactCardActions extends StatelessWidget {
  final Widget alerts;
  final Widget menu;

  const _CompactCardActions({required this.alerts, required this.menu});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: alerts),
          ),
          const SizedBox(width: 8),
          Align(alignment: Alignment.centerRight, child: menu),
        ],
      ),
    );
  }
}

class _CompactProjectMetaLine extends StatelessWidget {
  final Project project;

  const _CompactProjectMetaLine({required this.project});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (project.location.trim().isNotEmpty) project.location.trim(),
      '${project.teamSize} pessoas',
    ];

    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textMuted.withOpacity(0.86),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProjectMetaWrap extends StatelessWidget {
  final Project project;

  const _ProjectMetaWrap({required this.project});

  @override
  Widget build(BuildContext context) {
    final deadline = _deadlineLabel(project);
    final coordinator = project.coordinatorName?.trim();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (project.location.trim().isNotEmpty)
          _ProjectMetaChip(
            icon: Icons.location_on_rounded,
            label: project.location,
            color: AppColors.accentBlue,
          ),
        _ProjectMetaChip(
          icon: Icons.groups_2_rounded,
          label: '${project.teamSize} pessoas',
          color: AppColors.accentGreen,
        ),
        if (coordinator != null && coordinator.isNotEmpty)
          _ProjectMetaChip(
            icon: Icons.assignment_ind_rounded,
            label: 'Coord. $coordinator',
            color: AppColors.accentGold,
          ),
        if (deadline != null)
          _ProjectMetaChip(
            icon: Icons.event_available_rounded,
            label: deadline,
            color:
                project.isOverdue ? AppColors.accentRed : AppColors.textMuted,
          ),
      ],
    );
  }

  String? _deadlineLabel(Project project) {
    if (project.isCompleted) return 'Concluido';
    if (project.endDate == null) return null;
    if (project.isOverdue) return 'Atrasado';

    final days = project.daysUntilDeadline;
    if (days == null) return null;
    if (days == 0) return 'vence hoje';
    if (days <= 7) return '$days dias';
    return DateFormat('dd/MM').format(project.endDate!);
  }
}

class _ProjectMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProjectMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    color == AppColors.textMuted
                        ? AppColors.textSecondary
                        : color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
