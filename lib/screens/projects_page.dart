import 'package:flutter/material.dart';
import 'package:project_granith/contants/projects_constants.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/Services/service_projetos.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/project_card.dart';
import 'package:project_granith/widgets/project_filters.dart';
import 'package:project_granith/widgets/project_form_dialog.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProjectsController(ServiceProjetos())..loadProjects(),
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
        final isDesktop = MediaQuery.of(context).size.width > ProjectsPageConstants.desktopBreakpoint;

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
                  child: _ProjectsContent(isDesktop: isDesktop),
                ),
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
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            border: Border(bottom: BorderSide(color: AppColors.borderColor)),
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
            Text(
              'Projetos',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isDesktop ? 32 : 24,
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(width: 12),
              _ProjectCounter(count: projectCount),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Gerencie todas as suas obras e projetos',
          style: Theme.of(context).textTheme.bodyMedium,
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
          children: [
            _ViewModeToggle(),
            if (isDesktop) ...[
              const SizedBox(width: 16),
              _ExportButton(hasProjects: controller.projects.isNotEmpty),
            ],
          ],
        );
      },
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _ViewToggleButton(
                icon: Icons.grid_view,
                isSelected: controller.isGridView,
                onTap: () {
                  if (!controller.isGridView) controller.toggleViewMode();
                },
              ),
              _ViewToggleButton(
                icon: Icons.list,
                isSelected: !controller.isGridView,
                onTap: () {
                  if (controller.isGridView) controller.toggleViewMode();
                },
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

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isSelected ? 'Modo de visualização ativo' : 'Alternar modo de visualização',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentGold.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.accentGold : AppColors.textMuted,
          ),
        ),
      ),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
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
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
      onTap: onTap,
    );
  }
}

class _ProjectsFilters extends StatelessWidget {
  const _ProjectsFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SearchField(),
          const SizedBox(height: 16),
          _FiltersRow(),
        ],
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
          child: TextField(
            onChanged: controller.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Buscar projetos...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () => controller.updateSearchQuery(''),
                      tooltip: 'Limpar busca',
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
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

        if (controller.errorMessage != null) {
          return _ErrorState(
            message: controller.errorMessage!,
            onRetry: controller.loadProjects,
          );
        }

        if (controller.filteredProjects.isEmpty) {
          return _EmptyState(
            hasFilters: controller.selectedFilter != 'Todos' || controller.searchQuery.isNotEmpty,
            onClearFilters: controller.clearFilters,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando projetos...',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
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

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.construction,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Nenhum projeto encontrado' : 'Seus projetos aparecerão aqui',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Tente ajustar os filtros de busca'
                  : 'Comece criando seu primeiro projeto',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasFilters) ...[
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpar Filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderColor),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () => _showProjectDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Criar Projeto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
              ),
            ),
          ],
        ),
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

  const _ProjectsGrid({
    required this.projects,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount;
    double childAspectRatio;
    
    if (isDesktop) {
      crossAxisCount = ProjectsPageConstants.desktopGridColumns;
      childAspectRatio = 1.2;
    } else if (screenWidth > ProjectsPageConstants.tabletBreakpoint) {
      crossAxisCount = ProjectsPageConstants.tabletGridColumns;
      childAspectRatio = 1.1;
    } else {
      crossAxisCount = ProjectsPageConstants.mobileGridColumns;
      childAspectRatio = 2.5;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return _ProjectCardWrapper(project: projects[index]);
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
          child: _ProjectCardWrapper(
            project: projects[index],
            isListView: true,
          ),
        );
      },
    );
  }
}

class _ProjectCardWrapper extends StatelessWidget {
  final Project project;
  final bool isListView;

  const _ProjectCardWrapper({
    required this.project,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return ProjectCard(
          project: project,
          isListView: isListView,
          onEdit: () => _showProjectDialog(context, project: project),
          onDelete: () => _showDeleteDialog(context, project),
          onTap: () => _showProjectDetails(context, project),
        );
      },
    );
  }
}

class _ProjectsFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showProjectDialog(context),
      backgroundColor: AppColors.accentGold,
      foregroundColor: AppColors.primaryDark,
      icon: const Icon(Icons.add),
      label: const Text('Novo Projeto'),
    );
  }
}

// Helper functions
void _showProjectDialog(BuildContext context, {Project? project}) {
  final controller = context.read<ProjectsController>();
  
  showDialog(
    context: context,
    builder: (context) => ProjectFormDialog(
      project: project,
      onSave: (newProject) async {
        try {
          if (project != null) {
            await controller.updateProject(
              newProject.copyWith(id: project.id),
            );
          } else {
            await controller.addProject(newProject);
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  project != null 
                    ? 'Projeto "${newProject.name}" atualizado com sucesso'
                    : 'Projeto "${newProject.name}" criado com sucesso',
                ),
                backgroundColor: AppColors.accentGreen,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao salvar projeto: $e'),
                backgroundColor: AppColors.accentRed,
              ),
            );
          }
        }
      },
    ),
  );
}

void _showDeleteDialog(BuildContext context, Project project) {
  final controller = context.read<ProjectsController>();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Excluir Projeto',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        'Tem certeza que deseja excluir o projeto "${project.name}"? Esta ação não pode ser desfeita.',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await controller.deleteProject(project.id);
              Navigator.pop(context);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Projeto "${project.name}" excluído com sucesso'),
                    backgroundColor: AppColors.accentRed,
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir projeto: $e'),
                    backgroundColor: AppColors.accentRed,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
          ),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

void _showProjectDetails(BuildContext context, Project project) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Detalhes do projeto: ${project.name}'),
      backgroundColor: AppColors.accentBlue,
      action: SnackBarAction(
        label: 'Ver mais',
        textColor: Colors.white,
        onPressed: () {
          // TODO: Navegar para tela de detalhes
        },
      ),
    ),
  );
}