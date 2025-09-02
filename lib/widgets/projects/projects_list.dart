import 'package:flutter/material.dart';
import 'package:project_granith/contants/projects_constants.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/project_card.dart';
import 'package:project_granith/widgets/projects/project_form_dialog.dart';
import 'package:provider/provider.dart';

class ProjectsContent extends StatelessWidget {
  final bool isDesktop;

  const ProjectsContent({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const LoadingState();
        }

        if (controller.errorMessage != null) {
          return ErrorState(
            message: controller.errorMessage!,
            onRetry: controller.loadProjects,
          );
        }

        if (controller.filteredProjects.isEmpty) {
          return EmptyState(
            hasFilters:
                controller.selectedFilter != 'Todos' ||
                controller.searchQuery.isNotEmpty,
            onClearFilters: controller.clearFilters,
          );
        }

        return ProjectsList(
          projects: controller.filteredProjects,
          isGridView: controller.isGridView,
          isDesktop: isDesktop,
        );
      },
    );
  }
}

class ProjectsList extends StatelessWidget {
  final List<Project> projects;
  final bool isGridView;
  final bool isDesktop;

  const ProjectsList({
    super.key,
    required this.projects,
    required this.isGridView,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return ProjectsGrid(projects: projects, isDesktop: isDesktop);
    } else {
      return ProjectsListView(projects: projects);
    }
  }
}

class ProjectsGrid extends StatelessWidget {
  final List<Project> projects;
  final bool isDesktop;

  const ProjectsGrid({
    super.key,
    required this.projects,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isDesktop) {
      crossAxisCount = ProjectsPageConstants.desktopGridColumns;
      childAspectRatio = 0.75; // Ajustado para acomodar a imagem
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
            child: ProjectCardWrapper(project: projects[index]),
          );
        },
      ),
    );
  }
}

class ProjectsListView extends StatelessWidget {
  final List<Project> projects;

  const ProjectsListView({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index % 5) * 50),
          curve: Curves.easeOutQuart,
          child: ProjectCardWrapper(project: projects[index], isListView: true),
        );
      },
    );
  }
}

class ProjectCardWrapper extends StatelessWidget {
  final Project project;
  final bool isListView;

  const ProjectCardWrapper({
    super.key,
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

// Placeholder classes para os states (você deve migrar estas depois)
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

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

class EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const EmptyState({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off_rounded : Icons.construction_rounded,
            size: 64,
            color:
                hasFilters
                    ? AppColors.accentBlue.withOpacity(0.7)
                    : AppColors.accentGold.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'Nenhum projeto encontrado'
                : 'Seus projetos aparecerão aqui',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Tente ajustar os filtros de busca ou criar um novo projeto'
                : 'Comece criando seu primeiro projeto',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpar Filtros'),
            ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showProjectDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              hasFilters ? 'Criar Novo Projeto' : 'Criar Primeiro Projeto',
            ),
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

// Helper functions (estas devem ser movidas para um arquivo separado depois)
void _showProjectDialog(BuildContext context, {Project? project}) {
  final controller = context.read<ProjectsController>();

  showDialog(
    context: context,
    builder:
        (context) => ProjectFormDialog(
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
  ).then((_) {
    controller.loadProjects(forceRefresh: true);
  });
}

void _showDeleteDialog(BuildContext context, Project project) {
  final controller = context.read<ProjectsController>();

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
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
                        content: Text(
                          'Projeto "${project.name}" excluído com sucesso',
                        ),
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
