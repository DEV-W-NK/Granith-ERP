import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../models/project_model.dart';

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
    ...ProjectStatus.values.map((e) => e.displayName).toList(),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.accentGold.withOpacity(0.1),
              side: BorderSide(
                color: isSelected ? AppColors.accentGold : AppColors.borderColor,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accentGold : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
