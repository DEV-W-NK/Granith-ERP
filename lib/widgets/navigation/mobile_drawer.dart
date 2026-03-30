import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

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
      backgroundColor: AppColors.backgroundDark,
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.surfaceDark),
            child: Center(child: Text('GRANITH', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          _buildDrawerItem(0, 'Dashboard', Icons.dashboard_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(1, 'Projetos', Icons.business_rounded),
          _buildDrawerItem(2, 'Diário de Obras', Icons.menu_book_rounded),
          _buildDrawerItem(3, 'Requisições', Icons.playlist_add_check_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(4, 'Gestão de RH', Icons.engineering_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(5, 'Orçamentos', Icons.receipt_long_rounded),
          _buildDrawerItem(6, 'Tipos de Orçamento', Icons.category_rounded),
          _buildDrawerItem(7, 'Fornecedores', Icons.store_rounded),
          _buildDrawerItem(8, 'Catálogo de Itens', Icons.inventory_2_rounded),
          _buildDrawerItem(9, 'Compras & Pedidos', Icons.shopping_cart_rounded),
          _buildDrawerItem(10, 'Estoque', Icons.warehouse_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(11, 'Entradas e Saídas', Icons.account_balance_rounded),
          _buildDrawerItem(12, 'DRE Gerencial', Icons.bar_chart_rounded),
          _buildDrawerItem(13, 'Configurações', Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.accentGold : AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 14)),
      onTap: () => onItemSelected(index),
    );
  }
}