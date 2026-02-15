import 'package:flutter/material.dart';
import 'package:project_granith/constants/budget_type_constants.dart';
import 'package:project_granith/themes/app_theme.dart';

class BudgetTypeFilters extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const BudgetTypeFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > BudgetTypeConstants.desktopBreakpoint;
    
    return isDesktop ? _buildDesktopFilters() : _buildMobileFilters();
  }

  Widget _buildDesktopFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _getFilterOptions().map((filter) {
        return _FilterChip(
          label: filter,
          isSelected: selectedFilter == filter,
          onSelected: () => onFilterChanged(filter),
        );
      }).toList(),
    );
  }

  Widget _buildMobileFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _getFilterOptions().length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _getFilterOptions()[index];
          return _FilterChip(
            label: filter,
            isSelected: selectedFilter == filter,
            onSelected: () => onFilterChanged(filter),
          );
        },
      ),
    );
  }

  List<String> _getFilterOptions() {
    return [
      'Todos',
      'Ativos',
      'Inativos',
      ...BudgetTypeConstants.categories,
    ];
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.backgroundDark,
      selectedColor: AppColors.accentGold,
      side: BorderSide(
        color: isSelected 
            ? AppColors.accentGold
            : AppColors.borderColor.withOpacity(0.3),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}