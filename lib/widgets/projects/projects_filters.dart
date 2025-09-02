import 'package:flutter/material.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/projects/project_filters.dart';
import 'package:provider/provider.dart';

class _ProjectsFilters extends StatelessWidget {
  const _ProjectsFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [_SearchField(), const SizedBox(height: 16), _FiltersRow()],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return Semantics(
          label: 'Campo de busca de projetos',
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Buscar projetos por nome, cliente ou localização...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontSize: 15,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                ),
                suffixIcon:
                    controller.searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 16,
                            ),
                          ),
                          onPressed: () => controller.updateSearchQuery(''),
                          tooltip: 'Limpar busca',
                        )
                        : null,
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.accentGold,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FiltersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsController>(
      builder: (context, controller, child) {
        return ProjectFilters(
          selectedFilter: controller.selectedFilter,
          onFilterChanged: controller.updateFilter,
        );
      },
    );
  }
}
