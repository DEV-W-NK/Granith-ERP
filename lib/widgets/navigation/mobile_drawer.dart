import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'sidebar_menu.dart'; // Reutiliza a classe MenuItem e a lista estática

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
      backgroundColor: AppColors.surfaceDark,
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, color: AppColors.accentGold, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'GRANITH',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Mobile Access',
                    style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          // Itens (Usando a mesma lista do SidebarMenu para consistência)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
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
                      color: isSelected ? AppColors.accentGold : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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