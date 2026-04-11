import 'package:flutter/material.dart';

import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/screens/client_portal_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/subscription_page.dart';
import 'package:project_granith/screens/team_page.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const MainLayout());
      case '/subscription':
        return MaterialPageRoute(builder: (_) => const SubscriptionPage());
      case '/client-portal':
        return MaterialPageRoute(builder: (_) => const ClientPortalPage());
      case '/access-management':
        return MaterialPageRoute(builder: (_) => const AccessManagementPage());
      case '/reports':
        return MaterialPageRoute(builder: (_) => const ReportsPage());
      case '/nova-receita':
      case '/nova-despesa':
        return MaterialPageRoute(builder: (_) => const FinancialPage());
      case '/clientes':
        return MaterialPageRoute(builder: (_) => const TeamPage());
      default:
        return null;
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => const MainLayout());
  }
}
