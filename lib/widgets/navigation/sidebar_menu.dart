import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.surfaceDark,
      child: Column(
        children: [
          _buildLogo(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(0, 'Dashboard', Icons.dashboard_rounded),
                const Divider(color: Colors.white10, height: 32, indent: 16, endIndent: 16),
                
                _buildSectionTitle('Operacional'),
                _buildMenuItem(1, 'Projetos', Icons.business_rounded),
                _buildMenuItem(2, 'Diário de Obras', Icons.menu_book_rounded),
                _buildMenuItem(3, 'Requisições', Icons.playlist_add_check_rounded),

                
                _buildSectionTitle('Recursos Humanos'),
                _buildMenuItem(4, 'Gestão de RH', Icons.engineering_rounded),

                const SizedBox(height: 8),
                
                _buildSectionTitle('Comercial'),
                _buildMenuItem(5, 'Orçamentos', Icons.receipt_long_rounded),
                _buildMenuItem(6, 'Tipos de Orç.', Icons.category_rounded),
                
                _buildSectionTitle('Suprimentos'),
                _buildMenuItem(7, 'Fornecedores', Icons.store_rounded),
                _buildMenuItem(8, 'Catálogo de Itens', Icons.inventory_2_rounded),
                _buildMenuItem(9, 'Compras', Icons.shopping_cart_rounded),
                _buildMenuItem(10, 'Estoque', Icons.warehouse_rounded),
                
                const Divider(color: Colors.white10, height: 32, indent: 16, endIndent: 16),

                _buildSectionTitle('Financeiro'),
                _buildMenuItem(11, 'Entradas e Saidas', Icons.account_balance_rounded),
                _buildMenuItem(12, 'DRE Financeiro', Icons.bar_chart_rounded),


                _buildSectionTitle('Administrativo'),
                _buildMenuItem(13, 'Configurações', Icons.settings_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        children: const [
          Icon(Icons.architecture, color: AppColors.accentGold),
          SizedBox(width: 12),
          Text('GRANITH', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: isSelected ? const Border(right: BorderSide(color: AppColors.accentGold, width: 3)) : null,
          color: isSelected ? AppColors.accentGold.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.accentGold : AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}