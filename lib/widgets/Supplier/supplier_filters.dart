import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/constants/supplier_constants.dart';

class SupplierFilters extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const SupplierFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width > SupplierConstants.desktopBreakpoint;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Todos',
          isSelected: selectedFilter == SupplierConstants.filterAll,
          onTap: () => onFilterChanged(SupplierConstants.filterAll),
          icon: Icons.all_inclusive_rounded,
          color: AppColors.accentBlue,
        ),
        _FilterChip(
          label: 'Ativos',
          isSelected: selectedFilter == SupplierConstants.filterActive,
          onTap: () => onFilterChanged(SupplierConstants.filterActive),
          icon: Icons.check_circle_rounded,
          color: AppColors.accentGreen,
        ),
        _FilterChip(
          label: 'Inativos',
          isSelected: selectedFilter == SupplierConstants.filterInactive,
          onTap: () => onFilterChanged(SupplierConstants.filterInactive),
          icon: Icons.cancel_rounded,
          color: AppColors.accentRed,
        ),
        if (isDesktop) ...[
          _FilterChip(
            label: 'Recentes',
            isSelected: selectedFilter == 'recent',
            onTap: () => onFilterChanged('recent'),
            icon: Icons.schedule_rounded,
            color: AppColors.accentGold,
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SupplierConstants.animationDuration,
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? color.withOpacity(0.15)
                      : AppColors.surfaceDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected
                        ? color.withOpacity(0.4)
                        : AppColors.borderColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color:
                      isSelected ? color : AppColors.textMuted.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? color
                            : AppColors.textMuted.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
