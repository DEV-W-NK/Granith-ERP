import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/themes/app_theme.dart';

class ReportsPageView extends StatelessWidget {
  const ReportsPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relatorios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A base da pagina de relatorios foi restaurada. O proximo passo e estruturar os dashboards por feature.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: controller.setCurrentMonth,
                      child: const Text('Mes Atual'),
                    ),
                    ElevatedButton(
                      onPressed: controller.setCurrentYear,
                      child: const Text('Ano Atual'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
