import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final int index;

  MenuItem({
    required this.title,
    required this.icon,
    required this.index,
  });
}

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static final List<MenuItem> menuItems = [
    MenuItem(title: 'Dashboard', icon: Icons.dashboard, index: 0),
    MenuItem(title: 'Projetos', icon: Icons.construction, index: 1),
    MenuItem(title: 'Orçamentos', icon: Icons.calculate, index: 2),
    MenuItem(title: 'Estoque', icon: Icons.inventory, index: 3),
    MenuItem(title: 'Financeiro', icon: Icons.account_balance, index: 4),
    MenuItem(title: 'Relatórios', icon: Icons.analytics, index: 5),
    MenuItem(title: 'Configurações', icon: Icons.settings, index: 6),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.primaryDark,
      child: Column(
        children: [
          // Header do menu
          Container(
            padding: const EdgeInsets.all(20),
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
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'GRANITH',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'ERP System',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == item.index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentGold.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                      ? Border.all(color: AppColors.accentGold.withOpacity(0.3))
                      : null,
                  ),
                  child: ListTile(
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
                    onTap: () => onItemSelected(item.index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}