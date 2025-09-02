import 'package:flutter/material.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _ProjectsHeader extends StatelessWidget {
  final bool isDesktop;

  const _ProjectsHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Container(
          padding: EdgeInsets.all(isDesktop ? 32 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, Color(0xFF1a1a2e)],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _HeaderTitle(
                  isDesktop: isDesktop,
                  projectCount: controller.projects.length,
                  isLoading: controller.isLoading,
                ),
              ),
              _HeaderActions(isDesktop: isDesktop),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.construction_rounded,
                color: AppColors.accentGold,
                size: isDesktop ? 28 : 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projetos',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerencie todas as suas obras e projetos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(width: 16),
              _ProjectCounter(count: projectCount),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProjectCounter extends StatelessWidget {
  final int count;

  const _ProjectCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.accentGold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão de alternar visualização (Grid/Lista)
            _ViewToggleButtons(isDesktop: isDesktop),

            if (isDesktop) const SizedBox(width: 16),

            // Botão de exportar (apenas se houver projetos)
            if (controller.projects.isNotEmpty) ...[
              if (!isDesktop) const SizedBox(width: 12),
              _ExportButton(hasProjects: controller.projects.isNotEmpty),
            ],

            if (isDesktop) ...[
              const SizedBox(width: 16),
              // Botão de recarregar
              _RefreshButton(),
            ],
          ],
        );
      },
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
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
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
              Container(
                width: 1,
                height: 24,
                color: AppColors.borderColor.withOpacity(0.3),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.accentGold.withOpacity(0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Recarregar Projetos',
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed:
                  controller.isLoading
                      ? null
                      : () => controller.loadProjects(forceRefresh: true),
              icon: AnimatedRotation(
                turns: controller.isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 1000),
                child: Icon(
                  Icons.refresh_rounded,
                  color:
                      controller.isLoading
                          ? AppColors.textMuted.withOpacity(0.5)
                          : AppColors.textMuted,
                  size: 20,
                ),
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool hasProjects;

  const _ExportButton({required this.hasProjects});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: hasProjects ? () => _showExportOptions(context) : null,
      icon: const Icon(Icons.file_download, size: 18),
      label: const Text('Exportar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderColor),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) => _ExportOptionsSheet(),
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
