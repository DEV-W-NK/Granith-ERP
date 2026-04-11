import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:project_granith/app/di/app_providers.dart';
import 'package:project_granith/app/initialization/app_initialization_page.dart';
import 'package:project_granith/app/routing/app_router.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';

class GranithApp extends StatelessWidget {
  const GranithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'Granith ERP',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final easyLoadingBuilder = EasyLoading.init();
          return GranithAppBackdrop(
            child: easyLoadingBuilder(
              context,
              child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AppInitializationPage(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        onUnknownRoute: AppRouter.onUnknownRoute,
      ),
    );
  }
}
