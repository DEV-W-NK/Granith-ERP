import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/ViewModels/ProjectDetailsViewModel.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/widgets/projectdetails/projectdetailspage_page_widgets.dart';

class ProjectDetailsPage extends StatelessWidget {
  final Project project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectDetailsViewModel(project: project),
      child: const ProjectDetailsPageView(),
    );
  }
}

class ProjectsDetailsPage extends StatelessWidget {
  final Project project;

  const ProjectsDetailsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ProjectDetailsPage(project: project);
  }
}
