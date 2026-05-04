import 'package:flutter/material.dart';
import 'package:project_granith/widgets/jobroleregistration/job_role_registration_page_page_widgets.dart';

// Esta é a "casca" (wrapper) que deve ser registrada nas rotas do app.
// Ela chama a View refatorada que contém toda a lógica de layout e formulários.
class JobRoleRegistrationPage extends StatelessWidget {
  const JobRoleRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retornamos a View que criamos no arquivo de widgets.
    // Ela lida com a responsividade (Desktop/Mobile) e com o JobRoleController.
    return const JobRoleRegistrationView();
  }
}
