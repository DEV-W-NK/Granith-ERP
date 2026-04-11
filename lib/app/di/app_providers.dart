import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/job_role_controller.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:project_granith/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:project_granith/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:project_granith/features/projects/data/services/project_service.dart';
import 'package:project_granith/features/projects/presentation/controllers/projects_controller.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => SubscriptionController()),
        ChangeNotifierProvider(create: (_) => DailyLogController()),
        ChangeNotifierProvider(create: (_) => ProjectsController(ServiceProjetos())),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => TeamController()),
        ChangeNotifierProvider(create: (_) => JobRoleController()),
        ChangeNotifierProvider(create: (_) => ReportsController()),
        ChangeNotifierProvider(create: (_) => MaterialRequisitionController()),
        ChangeNotifierProvider(create: (_) => FinancialController()..init()),
      ],
      child: child,
    );
  }
}
