import 'package:flutter/material.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/project_form_dialog.dart';
import 'package:provider/provider.dart';

void showProjectDialog(BuildContext context, {Project? project}) {
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

void showDeleteDialog(BuildContext context, Project project) {
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

void showProjectDetails(BuildContext context, Project project) {
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
