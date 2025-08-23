import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'sidebar_menu.dart';

class MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const MobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.secondaryDark,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    color: AppColors.accentGold,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'GRANITH',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'ERP System',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              itemCount: SidebarMenu.menuItems.length,
              itemBuilder: (context, index) {
                final item = SidebarMenu.menuItems[index];
                final isSelected = selectedIndex == item.index;
                
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? AppColors.accentGold : AppColors.textSecondary,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? AppColors.accentGold : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.accentGold.withOpacity(0.1),
                  onTap: () => onItemSelected(item.index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}