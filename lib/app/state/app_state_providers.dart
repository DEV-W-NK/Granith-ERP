import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/services/financial_service.dart';
import 'package:project_granith/services/material_requisition_service.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/services/team_service.dart';

final serviceProjetosProvider = Provider<ServiceProjetos>((ref) {
  return ServiceProjetos();
});

final financialServiceProvider = Provider<FinancialService>((ref) {
  return FinancialService();
});

final materialRequisitionServiceProvider = Provider<MaterialRequisitionService>(
  (ref) {
    return MaterialRequisitionService();
  },
);

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService();
});

final projectsControllerProvider = Provider<ProjectsController>((ref) {
  final controller = ProjectsController(ref.watch(serviceProjetosProvider));
  controller.init();
  ref.onDispose(controller.dispose);
  return controller;
});

final financialControllerProvider = Provider<FinancialController>((ref) {
  final controller = FinancialController(
    service: ref.watch(financialServiceProvider),
  );
  controller.init();
  ref.onDispose(controller.dispose);
  return controller;
});

final materialRequisitionControllerProvider =
    Provider<MaterialRequisitionController>((ref) {
      final controller = MaterialRequisitionController(
        service: ref.watch(materialRequisitionServiceProvider),
      );
      controller.init();
      ref.onDispose(controller.dispose);
      return controller;
    });

final teamControllerProvider = Provider<TeamController>((ref) {
  final controller = TeamController(service: ref.watch(teamServiceProvider));
  controller.init();
  ref.onDispose(controller.dispose);
  return controller;
});
