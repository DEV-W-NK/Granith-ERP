import 'package:flutter/material.dart';
import 'package:project_granith/constants/projects_constants.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/project_card.dart';
import 'package:project_granith/widgets/projects/project_filters.dart';
import 'package:project_granith/helpers/projects_helpers.dart'; // Import the helpers

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => ProjectsController(ServiceProjetos())..loadProjects(),
      child: const _ProjectsPageView(),
    );
  }
}

class _ProjectsPageView extends StatelessWidget {
  const _ProjectsPageView();

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
                Expanded(child: _ProjectsContent(isDesktop: isDesktop)),
              ],
            ),
          ),
          floatingActionButton: _ProjectsFAB(),
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
        Text(
          'Projetos',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isDesktop ? 28 : 24,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          Text(
            'Carregando...',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 14,
            ),
          )
        else
          Text(
            projectCount == 0
                ? 'Nenhum projeto encontrado'
                : '$projectCount ${projectCount == 1 ? 'projeto' : 'projetos'}',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 14,
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
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.2),
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
          foregroundColor:
              hasProjects ? AppColors.textSecondary : AppColors.textMuted,
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
          ),
        );
      },
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [_SearchField(), const SizedBox(height: 16), _FiltersRow()],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
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
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Buscar projetos por nome, cliente ou localização...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontSize: 15,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.accentGold,
                    size: 20,
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
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.accentGold,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
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

  const _ProjectsContent({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const _LoadingState();
        }

        if (controller.hasError) {
          // ← Agora reconhece hasError
          return _ErrorState(
            message: controller.errorMessage ?? 'Erro desconhecido',
            onRetry: () => controller.loadProjects(forceRefresh: true),
          );
        }

        if (controller.filteredProjects.isEmpty) {
          return _EmptyState(
            hasFilters:
                controller
                    .hasActiveFilters, // ← Agora reconhece hasActiveFilters
            onClearFilters:
                controller.clearFilters, // ← Nome corrigido do método
            onCreateProject: () => showProjectDialog(context),
          );
        }

        return _ProjectsList(
          projects: controller.filteredProjects,
          isGridView: controller.isGridView,
          isDesktop: isDesktop,
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
                letterSpacing: -0.2,
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

  const _ProjectsList({
    required this.projects,
    required this.isGridView,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _ProjectsGrid(projects: projects, isDesktop: isDesktop);
    } else {
      return _ProjectsListView(projects: projects);
    }
  }
}

class _ProjectsGrid extends StatelessWidget {
  final List<Project> projects;
  final bool isDesktop;

  const _ProjectsGrid({required this.projects, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isDesktop) {
      crossAxisCount = ProjectsPageConstants.desktopGridColumns;
      childAspectRatio = 0.75;
      spacing = 20;
    } else if (screenWidth > ProjectsPageConstants.tabletBreakpoint) {
      crossAxisCount = ProjectsPageConstants.tabletGridColumns;
      childAspectRatio = 0.8;
      spacing = 16;
    } else {
      crossAxisCount = ProjectsPageConstants.mobileGridColumns;
      childAspectRatio = 0.85;
      spacing = 12;
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index % 3) * 100),
            curve: Curves.easeOutBack,
            child: _ProjectCardWrapper(project: projects[index]),
          );
        },
      ),
    );
  }
}

class _ProjectsListView extends StatelessWidget {
  final List<Project> projects;

  const _ProjectsListView({required this.projects});

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

  const _ProjectCardWrapper({required this.project, this.isListView = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return ProjectCard(
          project: project,
          isListView: isListView,
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
      child: FloatingActionButton.extended(
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
