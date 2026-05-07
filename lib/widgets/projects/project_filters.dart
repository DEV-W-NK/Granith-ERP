import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../../models/project_model.dart';

class ProjectFilters extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const ProjectFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static final List<String> filters = [
    'Todos',
    ...ProjectStatus.values.map((e) => e.displayName),
  ];

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 600;

    return SizedBox(
      height: phone ? 38 : 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: ChoiceChip(
              avatar: Icon(
                filter == 'Todos'
                    ? Icons.layers_rounded
                    : _statusIconFor(filter),
                size: phone ? 13 : 15,
                color: isSelected ? AppColors.accentGold : AppColors.textMuted,
              ),
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
              backgroundColor: AppColors.backgroundMid.withOpacity(0.54),
              selectedColor: AppColors.accentGold.withOpacity(0.13),
              side: BorderSide(
                color:
                    isSelected
                        ? AppColors.accentGold.withOpacity(0.42)
                        : AppColors.borderColor.withOpacity(0.42),
              ),
              showCheckmark: false,
              padding: EdgeInsets.symmetric(
                horizontal: phone ? 8 : 10,
                vertical: phone ? 7 : 9,
              ),
              labelStyle: TextStyle(
                color:
                    isSelected ? AppColors.accentGold : AppColors.textSecondary,
                fontSize: phone ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _statusIconFor(String filter) {
    final status = ProjectStatus.values.firstWhere(
      (status) => status.displayName == filter,
      orElse: () => ProjectStatus.planning,
    );
    return status.icon;
  }
}
