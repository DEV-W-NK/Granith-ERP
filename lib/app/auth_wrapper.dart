import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/screens/client_portal_page.dart';
import 'package:project_granith/screens/login_page.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, child) {
        if (!auth.isInitialized) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginPage();
        }

        if (auth.isClientUser) {
          return const ClientPortalPage();
        }

        return const MainLayout();
      },
    );
  }
}
