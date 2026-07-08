import 'package:flutter/material.dart';
import 'package:project_granith/constants/projects_constants.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/projects/project_card.dart';
import 'package:project_granith/widgets/projects/project_filters.dart';
import 'package:project_granith/helpers/projects_helpers.dart';

class ProjectsPageView extends StatelessWidget {
  const ProjectsPageView({super.key, this.budgetService});

  final ProjectBudgetService? budgetService;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        final isDesktop =
            MediaQuery.of(context).size.width >
            ProjectsPageConstants.desktopBreakpoint;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: RefreshIndicator(
            onRefresh: () => controller.loadProjects(forceRefresh: true),
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.accentGold,
            child: Column(
              children: [
                _ProjectsHeader(isDesktop: isDesktop),
                if (!controller.isLoading) const _ProjectsFilters(),
                Expanded(
                  child: _ProjectsContent(
                    isDesktop: isDesktop,
                    budgetService: budgetService,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isDesktop ? null : _ProjectsFAB(),
        );
      },
    );
  }
}

class _ProjectsHeader extends StatelessWidget {
  final bool isDesktop;

  const _ProjectsHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final phone = screenWidth < 600;

    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : (phone ? 14 : 18),
            isDesktop ? 16 : (phone ? 12 : 14),
            isDesktop ? 24 : (phone ? 14 : 18),
            isDesktop ? 14 : (phone ? 10 : 14),
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundMid.withOpacity(0.72),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withOpacity(0.36),
                width: 1,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = _HeaderTitle(
                isDesktop: isDesktop,
                projectCount: controller.projects.length,
                isLoading: controller.isLoading,
              );
              final actions = _HeaderActions(isDesktop: isDesktop);

              final compact = constraints.maxWidth < ResponsiveLayout.compact;
              final phoneLayout = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (phoneLayout)
                    title
                  else if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 12), actions],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 18),
                        actions,
                      ],
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final bool isDesktop;
  final int projectCount;
  final bool isLoading;

  const _HeaderTitle({
    required this.isDesktop,
    required this.projectCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;
    final countLabel =
        isLoading
            ? 'Carregando...'
            : projectCount == 0
            ? 'Nenhum projeto encontrado'
            : '$projectCount ${projectCount == 1 ? 'projeto' : 'projetos'}';

    if (phone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projetos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            countLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.88),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final iconSize = isDesktop ? 44.0 : 40.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.accentGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentGold.withOpacity(0.28)),
          ),
          child: Icon(
            Icons.account_tree_rounded,
            color: AppColors.accentGold,
            size: phone ? 19 : 22,
          ),
        ),
        SizedBox(width: phone ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projetos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: isDesktop ? 24 : (phone ? 20 : 22),
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: phone ? 3 : 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HeaderPill(
                    icon: Icons.folder_open_rounded,
                    label: countLabel,
                    color: AppColors.accentBlue,
                    compact: phone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final bool isDesktop;

  const _HeaderActions({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        if (!isDesktop) {
          return _MobileHeaderActions(
            hasProjects: controller.projects.isNotEmpty,
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            _ViewToggleButtons(isDesktop: isDesktop),
            if (controller.projects.isNotEmpty) ...[
              _ExportButton(hasProjects: controller.projects.isNotEmpty),
            ],
            _RefreshButton(),
            if (isDesktop) _NewProjectButton(),
          ],
        );
      },
    );
  }
}

class _MobileHeaderActions extends StatelessWidget {
  final bool hasProjects;

  const _MobileHeaderActions({required this.hasProjects});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _MobileViewToggle()),
        const SizedBox(width: 8),
        _MobileHeaderMenuButton(hasProjects: hasProjects),
      ],
    );
  }

  static void showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExportOptionsSheet(),
    );
  }
}

class _MobileViewToggle extends StatelessWidget {
  const _MobileViewToggle();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.58),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.44)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MobileViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Grade',
                  selected: controller.isGridView,
                  onTap: () => controller.setViewMode(true),
                ),
              ),
              Expanded(
                child: _MobileViewToggleButton(
                  icon: Icons.view_list_rounded,
                  label: 'Lista',
                  selected: !controller.isGridView,
                  onTap: () => controller.setViewMode(false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MobileViewToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.accentGold.withOpacity(0.18)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border:
                selected
                    ? Border.all(color: AppColors.accentGold.withOpacity(0.24))
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.accentGold : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected ? AppColors.accentGold : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeaderMenuButton extends StatelessWidget {
  final bool hasProjects;

  const _MobileHeaderMenuButton({required this.hasProjects});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.44)),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Ações de projetos',
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textSecondary,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderColor),
        ),
        onSelected: (value) {
          switch (value) {
            case 'grid':
              context.read<ProjectsController>().setViewMode(true);
              break;
            case 'list':
              context.read<ProjectsController>().setViewMode(false);
              break;
            case 'refresh':
              context.read<ProjectsController>().loadProjects(
                forceRefresh: true,
              );
              break;
            case 'export':
              _MobileHeaderActions.showExportOptions(context);
              break;
          }
        },
        itemBuilder:
            (_) => [
              _mobileMenuItem(
                value: 'grid',
                icon: Icons.grid_view_rounded,
                label: 'Grade',
                color: AppColors.textMuted,
              ),
              _mobileMenuItem(
                value: 'list',
                icon: Icons.view_list_rounded,
                label: 'Lista',
                color: AppColors.textMuted,
              ),
              _mobileMenuItem(
                value: 'refresh',
                icon: Icons.refresh_rounded,
                label: 'Atualizar',
                color: AppColors.accentBlue,
              ),
              if (hasProjects)
                _mobileMenuItem(
                  value: 'export',
                  icon: Icons.download_rounded,
                  label: 'Exportar',
                  color: AppColors.accentGold,
                ),
            ],
      ),
    );
  }

  PopupMenuItem<String> _mobileMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButtons extends StatelessWidget {
  final bool isDesktop;

  const _ViewToggleButtons({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.58),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.44),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: controller.isGridView,
                onTap: () => controller.setViewMode(true),
                tooltip: 'Visualização em Grade',
              ),
              _ViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !controller.isGridView,
                onTap: () => controller.setViewMode(false),
                tooltip: 'Visualização em Lista',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tooltip;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.accentGold.withOpacity(0.18)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border:
              isSelected
                  ? Border.all(color: AppColors.accentGold.withOpacity(0.24))
                  : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.accentGold : AppColors.textMuted,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return Semantics(
      button: true,
      label:
          isSelected
              ? 'Modo de visualização ativo'
              : 'Alternar modo de visualização',
      child: button,
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool hasProjects;

  const _ExportButton({required this.hasProjects});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar Projetos',
      child: IconButton(
        onPressed: hasProjects ? () => _showExportOptions(context) : null,
        icon: const Icon(Icons.download_rounded),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceDark.withOpacity(0.58),
          foregroundColor:
              hasProjects ? AppColors.textSecondary : AppColors.textMuted,
          side: BorderSide(color: AppColors.borderColor.withOpacity(0.44)),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExportOptionsSheet(),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Atualizar',
          child: IconButton(
            onPressed:
                controller.isLoading
                    ? null
                    : () => controller.loadProjects(forceRefresh: true),
            icon: Icon(
              Icons.refresh_rounded,
              color:
                  controller.isLoading
                      ? AppColors.textMuted.withOpacity(0.5)
                      : AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceDark.withOpacity(0.58),
              side: BorderSide(color: AppColors.borderColor.withOpacity(0.44)),
            ),
          ),
        );
      },
    );
  }
}

class _NewProjectButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => showProjectDialog(context),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Novo Projeto'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 82).clamp(130.0, 360.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 5 : 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    color == AppColors.accentGold
                        ? color
                        : AppColors.textSecondary,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exportar Projetos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _ExportOption(
            icon: Icons.table_chart,
            title: 'Exportar como CSV',
            subtitle: 'Planilha com todos os dados',
            onTap: () => _handleExport(context, 'CSV'),
          ),
          _ExportOption(
            icon: Icons.picture_as_pdf,
            title: 'Exportar como PDF',
            subtitle: 'Relatório formatado',
            onTap: () => _handleExport(context, 'PDF'),
          ),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context, String type) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportação $type em desenvolvimento'),
        backgroundColor: AppColors.accentBlue,
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentGold),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}

class _ProjectsFilters extends StatelessWidget {
  const _ProjectsFilters();

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        phone ? 12 : 20,
        phone ? 8 : 10,
        phone ? 12 : 20,
        0,
      ),
      child: Container(
        padding: EdgeInsets.all(phone ? 10 : 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.42),
          borderRadius: BorderRadius.circular(phone ? 14 : 16),
          border: Border.all(
            color: AppColors.borderColor.withOpacity(0.42),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;

            if (phone) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SearchField(compact: true),
                  const SizedBox(height: 8),
                  const _MobileMinimalControls(),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SearchField(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _FiltersRow()),
                          const SizedBox(width: 8),
                          const _ClearFiltersButton(),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      SizedBox(
                        width:
                            constraints.maxWidth.clamp(360.0, 460.0).toDouble(),
                        child: const _SearchField(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _FiltersRow()),
                      const SizedBox(width: 8),
                      const _ClearFiltersButton(),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MobileMinimalControls extends StatelessWidget {
  const _MobileMinimalControls();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Row(
          children: [
            Expanded(
              child: _MobileStatusFilterButton(
                selectedFilter: controller.selectedFilter,
                filteredCount: controller.filteredProjects.length,
                onFilterChanged: controller.updateFilter,
              ),
            ),
            const SizedBox(width: 8),
            _MobileHeaderMenuButton(
              hasProjects: controller.projects.isNotEmpty,
            ),
          ],
        );
      },
    );
  }
}

class _MobileStatusFilterButton extends StatelessWidget {
  final String selectedFilter;
  final int filteredCount;
  final ValueChanged<String> onFilterChanged;

  const _MobileStatusFilterButton({
    required this.selectedFilter,
    required this.filteredCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = selectedFilter != 'Todos';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStatusPicker(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                hasFilter
                    ? AppColors.accentGold.withOpacity(0.10)
                    : AppColors.backgroundMid.withOpacity(0.58),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  hasFilter
                      ? AppColors.accentGold.withOpacity(0.28)
                      : AppColors.borderColor.withOpacity(0.34),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasFilter ? _statusIconFor(selectedFilter) : Icons.tune_rounded,
                color: hasFilter ? AppColors.accentGold : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasFilter ? selectedFilter : 'Todos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        hasFilter
                            ? AppColors.accentGold
                            : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$filteredCount',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.86),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted.withOpacity(0.82),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final filter in ProjectFilters.filters)
                    _MobileStatusOption(
                      label: filter,
                      icon:
                          filter == 'Todos'
                              ? Icons.layers_rounded
                              : _statusIconFor(filter),
                      selected: selectedFilter == filter,
                      onTap: () {
                        Navigator.pop(context);
                        onFilterChanged(filter);
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  IconData _statusIconFor(String filter) {
    final status = ProjectStatus.values.firstWhere(
      (status) => status.displayName == filter,
      orElse: () => ProjectStatus.planning,
    );
    return status.icon;
  }
}

class _MobileStatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MobileStatusOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        icon,
        color: selected ? AppColors.accentGold : AppColors.textMuted,
        size: 19,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.accentGold : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      trailing:
          selected
              ? const Icon(
                Icons.check_rounded,
                color: AppColors.accentGold,
                size: 18,
              )
              : null,
      onTap: onTap,
    );
  }
}

class _ClearFiltersButton extends StatelessWidget {
  const _ClearFiltersButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        if (!controller.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: 'Limpar filtros',
          child: IconButton(
            onPressed: controller.clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accentGold.withOpacity(0.10),
              foregroundColor: AppColors.accentGold,
              side: BorderSide(color: AppColors.accentGold.withOpacity(0.26)),
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  final bool compact;

  const _SearchField({this.compact = false});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        if (_textController.text != controller.searchQuery) {
          _textController.value = TextEditingValue(
            text: controller.searchQuery,
            selection: TextSelection.collapsed(
              offset: controller.searchQuery.length,
            ),
          );
        }

        final compact = widget.compact;

        return Semantics(
          label: 'Campo de busca de projetos',
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText:
                    compact
                        ? 'Buscar projeto, cliente ou local...'
                        : 'Buscar projetos por nome, cliente ou local...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontSize: compact ? 13 : 15,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(compact ? 7 : 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(compact ? 9 : 8),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.accentGold,
                    size: compact ? 18 : 20,
                  ),
                ),
                suffixIcon:
                    controller.searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 16,
                            ),
                          ),
                          onPressed: () => controller.updateSearchQuery(''),
                          tooltip: 'Limpar busca',
                        )
                        : null,
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  borderSide: const BorderSide(
                    color: AppColors.accentGold,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 20,
                  vertical: compact ? 12 : 16,
                ),
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FiltersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return ProjectFilters(
          selectedFilter: controller.selectedFilter,
          onFilterChanged: controller.updateFilter,
        );
      },
    );
  }
}

class _ProjectsContent extends StatelessWidget {
  final bool isDesktop;
  final ProjectBudgetService? budgetService;

  const _ProjectsContent({required this.isDesktop, this.budgetService});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const _LoadingState();
        }

        if (controller.hasError) {
          return _ErrorState(
            message: controller.errorMessage ?? 'Erro desconhecido',
            onRetry: () => controller.loadProjects(forceRefresh: true),
          );
        }

        if (controller.filteredProjects.isEmpty) {
          return _EmptyState(
            hasFilters: controller.hasActiveFilters,
            onClearFilters: controller.clearFilters,
            onCreateProject: () => showProjectDialog(context),
          );
        }

        return _ProjectsList(
          projects: controller.filteredProjects,
          isGridView: controller.isGridView,
          isDesktop: isDesktop,
          budgetService: budgetService,
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
  final VoidCallback onCreateProject;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              hasFilters
                  ? 'Nenhum projeto encontrado'
                  : 'Seus projetos aparecerão aqui',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
                    onPressed: onCreateProject,
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

class _ProjectsList extends StatelessWidget {
  final List<Project> projects;
  final bool isGridView;
  final bool isDesktop;
  final ProjectBudgetService? budgetService;

  const _ProjectsList({
    required this.projects,
    required this.isGridView,
    required this.isDesktop,
    this.budgetService,
  });

  @override
  Widget build(BuildContext context) {
    return isGridView
        ? _ProjectsGrid(
          projects: projects,
          isDesktop: isDesktop,
          budgetService: budgetService,
        )
        : _ProjectsListView(projects: projects, budgetService: budgetService);
  }
}

class _ProjectsGrid extends StatelessWidget {
  final List<Project> projects;
  final bool isDesktop;
  final ProjectBudgetService? budgetService;

  const _ProjectsGrid({
    required this.projects,
    required this.isDesktop,
    this.budgetService,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = ResponsiveLayout.gap(width);
        final crossAxisCount = ResponsiveLayout.columnsFor(
          width,
          compactColumns: ProjectsPageConstants.mobileGridColumns,
          mediumColumns: ProjectsPageConstants.tabletGridColumns,
          expandedColumns: ProjectsPageConstants.desktopGridColumns,
        );
        final cardHeight =
            crossAxisCount == 1
                ? (width < 360
                    ? 328.0
                    : width < 520
                    ? 318.0
                    : 352.0)
                : isDesktop
                ? 392.0
                : 380.0;

        return Padding(
          padding: EdgeInsets.all(spacing),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: cardHeight,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index % 3) * 100),
                curve: Curves.easeOutBack,
                child: _ProjectCardWrapper(
                  project: projects[index],
                  budgetService: budgetService,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProjectsListView extends StatelessWidget {
  final List<Project> projects;
  final ProjectBudgetService? budgetService;

  const _ProjectsListView({required this.projects, this.budgetService});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index % 3) * 100),
            curve: Curves.easeOutBack,
            child: _ProjectCardWrapper(
              project: projects[index],
              isListView: true,
              budgetService: budgetService,
            ),
          ),
        );
      },
    );
  }
}

class _ProjectCardWrapper extends StatelessWidget {
  final Project project;
  final bool isListView;
  final ProjectBudgetService? budgetService;

  const _ProjectCardWrapper({
    required this.project,
    this.isListView = false,
    this.budgetService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return ProjectCard(
          project: project,
          isListView: isListView,
          budgetService: budgetService,
          onEdit: () => showProjectDialog(context, project: project),
          onDelete: () => showDeleteDialog(context, project),
          onTap: () => showProjectDetails(context, project),
        );
      },
    );
  }
}

class _ProjectsFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          compact
              ? FloatingActionButton(
                tooltip: 'Novo Projeto',
                onPressed: () => showProjectDialog(context),
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                child: const Icon(Icons.add_rounded, size: 24),
              )
              : FloatingActionButton.extended(
                onPressed: () => showProjectDialog(context),
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Novo Projeto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
    );
  }
}
