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
    MenuItem(
      title: 'Dashboard', 
      icon: Icons.dashboard_rounded, 
      index: 0
    ),
    MenuItem(
      title: 'Projetos', 
      icon: Icons.business_rounded, 
      index: 1
    ),
    MenuItem(
      title: 'Orçamentos', 
      icon: Icons.receipt_long_rounded, 
      index: 2
    ),
    MenuItem(
      title: 'Tipos de Orçamento',
      icon: Icons.category_rounded,
      index: 3,
    ),
    MenuItem(
      title: 'Fornecedores',
      icon: Icons.store_rounded,
      index: 4,
    ),
    // Novos itens adicionados na ordem correta
    MenuItem(
      title: 'Catálogo de Itens',
      icon: Icons.inventory_2_rounded, // Ícone de caixa/item
      index: 5,
    ),
    MenuItem(
      title: 'Compras',
      icon: Icons.shopping_cart_rounded,
      index: 6,
    ),
    MenuItem(
      title: 'Estoque',
      icon: Icons.inventory_rounded, // Ícone de prancheta/estoque
      index: 7,
    ),
    // Placeholders reindexados
    MenuItem(
      title: 'Financeiro',
      icon: Icons.account_balance_rounded,
      index: 8,
    ),
    MenuItem(
      title: 'Relatórios',
      icon: Icons.analytics_rounded,
      index: 9,
    ),
    MenuItem(
      title: 'Configurações',
      icon: Icons.settings_rounded,
      index: 10,
    ),
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
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.secondaryDark),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, color: AppColors.accentGold, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'GRANITH',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    'ERP System',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1),
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
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGold.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.accentGold.withOpacity(0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.accentGold
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentGold
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => onItemSelected(item.index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Footer / Versão
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: AppColors.textMuted.withOpacity(0.3), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}