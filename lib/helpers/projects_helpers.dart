import 'package:flutter/material.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/screens/ProjectDetailsPage.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/project_form_dialog.dart';
import 'package:provider/provider.dart';

void showProjectDialog(BuildContext context, {Project? project}) {
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
                      ? 'Projeto "${newProject.name}" atualizado'
                      : 'Projeto "${newProject.name}" criado',
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

void showDeleteDialog(BuildContext context, Project project) {
  final controller = context.read<ProjectsController>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text('Excluir Projeto',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Text(
        'Tem certeza que deseja excluir "${project.name}"? Esta ação não pode ser desfeita.',
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
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Projeto "${project.name}" excluído'),
                    backgroundColor: AppColors.accentRed,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: AppColors.accentRed,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

/// Navega para a tela de detalhes do projeto.
/// Substitui o SnackBar anterior.
void showProjectDetails(BuildContext context, Project project) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProjectDetailsPage(project: project),
    ),
  );
}