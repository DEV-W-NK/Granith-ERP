import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/helpers/projects_helpers.dart';

class _ProjectsFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => showProjectDialog(context), // Remove the underscore
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Novo Projeto',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}