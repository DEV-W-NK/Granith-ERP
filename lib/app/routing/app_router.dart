import 'package:flutter/material.dart';

import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/screens/client_portal_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/login_page.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/subscription_page.dart';
import 'package:project_granith/screens/system_settings_page.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return _guardedRoute(
          settings,
          const MainLayout(),
          allow: _canAccessInternalApp,
        );
      case '/projects':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 1),
          allow: _canAccessInternalApp,
        );
      case '/daily-logs':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 3),
          allow: _canAccessInternalApp,
        );
      case '/requisitions':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 4),
          allow: _canAccessInternalApp,
        );
      case '/hr':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 5),
          allow: _canAccessInternalApp,
        );
      case '/ai/operational':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 22),
          allow: _canAccessInternalApp,
        );
      case '/ai/hr':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 23),
          allow: _canAccessInternalApp,
        );
      case '/ai/commercial':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 24),
          allow: _canAccessInternalApp,
        );
      case '/ai/supplies':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 25),
          allow: _canAccessInternalApp,
        );
      case '/ai/administrative':
        return _guardedRoute(
          settings,
          const MainLayout(initialIndex: 26),
          allow: _canAccessInternalApp,
        );
      case '/subscription':
        return _guardedRoute(
          settings,
          const SubscriptionPage(),
          allow:
              (auth) =>
                  auth.isAdminUser ||
                  auth.hasPermission('billing.manage') ||
                  auth.hasPermission('settings.manage'),
        );
      case '/client-portal':
        return _guardedRoute(
          settings,
          const ClientPortalPage(),
          allow: (auth) => auth.isClientUser || auth.isAdminUser,
        );
      case '/access-management':
        return _guardedRoute(
          settings,
          const AccessManagementPage(),
          allow:
              (auth) => auth.isAdminUser || auth.hasPermission('access.manage'),
        );
      case '/settings':
        return _guardedRoute(
          settings,
          const SystemSettingsPage(),
          allow:
              (auth) =>
                  auth.isAdminUser || auth.hasPermission('settings.manage'),
        );
      case '/reports':
        return _guardedRoute(
          settings,
          const ReportsPage(),
          allow:
              (auth) =>
                  auth.isAdminUser || auth.hasPermission('financial.read'),
        );
      case '/nova-receita':
      case '/nova-despesa':
        return _guardedRoute(
          settings,
          const FinancialPage(),
          allow:
              (auth) =>
                  auth.isAdminUser || auth.hasPermission('financial.read'),
        );
      case '/clientes':
        return _guardedRoute(
          settings,
          const AccessManagementPage(initialTabIndex: 1),
          allow:
              (auth) => auth.isAdminUser || auth.hasPermission('access.manage'),
        );
      default:
        return null;
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _guardedRoute(
      settings,
      const MainLayout(),
      allow: _canAccessInternalApp,
    );
  }

  static Route<dynamic> _guardedRoute(
    RouteSettings settings,
    Widget page, {
    required bool Function(AuthViewModel auth) allow,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final auth = context.watch<AuthViewModel>();

        if (!auth.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginPage();
        }

        if (allow(auth)) {
          return page;
        }

        if (auth.isClientUser) {
          return const ClientPortalPage();
        }

        return const _AccessDeniedPage();
      },
    );
  }

  static bool _canAccessInternalApp(AuthViewModel auth) {
    return auth.isEmployeeUser || auth.isAdminUser;
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Acesso restrito',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua conta nao possui permissao para abrir este modulo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false),
                  child: const Text('Voltar ao inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
