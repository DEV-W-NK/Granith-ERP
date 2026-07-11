import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart' as provider;

import 'package:project_granith/app/state/app_state_providers.dart';
import 'package:project_granith/controllers/administrative_profit_controller.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/job_role_controller.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:project_granith/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:project_granith/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:project_granith/features/projects/presentation/controllers/projects_controller.dart';

class AppProviders extends riverpod.ConsumerWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final projectsController = ref.watch(projectsControllerProvider);
    final teamController = ref.watch(teamControllerProvider);
    final materialRequisitionController = ref.watch(
      materialRequisitionControllerProvider,
    );
    final financialController = ref.watch(financialControllerProvider);

    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AuthViewModel()),
        provider.ChangeNotifierProvider(create: (_) => LoginViewModel()),
        provider.ChangeNotifierProvider(
          create: (_) => SystemSettingsViewModel(),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => SubscriptionController(),
        ),
        provider.ChangeNotifierProvider(create: (_) => DailyLogController()),
        provider.ChangeNotifierProvider<ProjectsController>.value(
          value: projectsController,
        ),
        provider.ChangeNotifierProvider(create: (_) => HomeViewModel()),
        provider.ChangeNotifierProvider<TeamController>.value(
          value: teamController,
        ),
        provider.ChangeNotifierProvider(create: (_) => JobRoleController()),
        provider.ChangeNotifierProvider(create: (_) => ReportsController()),
        provider.ChangeNotifierProvider(
          create: (_) => AdministrativeProfitController(),
        ),
        provider.ChangeNotifierProvider<MaterialRequisitionController>.value(
          value: materialRequisitionController,
        ),
        provider.ChangeNotifierProvider<FinancialController>.value(
          value: financialController,
        ),
      ],
      child: child,
    );
  }
}
