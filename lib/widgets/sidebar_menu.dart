import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final int index;

  MenuItem({required this.title, required this.icon, required this.index});
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
    MenuItem(icon: Icons.dashboard_rounded, title: 'Dashboard', index: 0),
    MenuItem(icon: Icons.business_rounded, title: 'Projetos', index: 1),
    MenuItem(icon: Icons.receipt_long_rounded, title: 'Orçamentos', index: 2),
    MenuItem(
      icon: Icons.category_rounded,
      title: 'Tipos de Orçamento',
      index: 3,
    ),
    MenuItem(
      icon: Icons.store_rounded,
      title: 'Fornecedores',
      index: 4,
    ), // Adicionado
    MenuItem(
      icon: Icons.inventory_rounded,
      title: 'Estoque',
      index: 5,
    ), // Reindexado
    MenuItem(
      icon: Icons.account_balance_rounded,
      title: 'Financeiro',
      index: 6, // Reindexado
    ),
    MenuItem(
      icon: Icons.analytics_rounded,
      title: 'Relatórios',
      index: 7,
    ), // Reindexado
    MenuItem(
      icon: Icons.settings_rounded,
      title: 'Configurações',
      index: 8,
    ), // Reindexado
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
            decoration: const BoxDecoration(color: AppColors.secondaryDark),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, color: AppColors.accentGold, size: 32),
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
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.accentGold.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isSelected
                            ? Border.all(
                              color: AppColors.accentGold.withOpacity(0.3),
                            )
                            : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color:
                          isSelected
                              ? AppColors.accentGold
                              : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color:
                            isSelected
                                ? AppColors.accentGold
                                : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
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
