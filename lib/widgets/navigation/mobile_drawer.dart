import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const MobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;

    return Drawer(
      backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.92),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.pageSurfaceGradient,
              border: Border(
                bottom: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.55)),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    settings.workspaceName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    settings.workspaceTagline,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(0, 'Dashboard', Icons.dashboard_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(1, 'Projetos', Icons.business_rounded),
          _buildDrawerItem(2, 'Diario de Obras', Icons.menu_book_rounded),
          _buildDrawerItem(3, 'Requisicoes', Icons.playlist_add_check_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(4, 'Gestao de RH', Icons.engineering_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(5, 'Orcamentos', Icons.receipt_long_rounded),
          _buildDrawerItem(6, 'Tipos de Orcamento', Icons.category_rounded),
          _buildDrawerItem(7, 'Fornecedores', Icons.store_rounded),
          _buildDrawerItem(8, 'Catalogo de Itens', Icons.inventory_2_rounded),
          _buildDrawerItem(9, 'Compras e Pedidos', Icons.shopping_cart_rounded),
          _buildDrawerItem(10, 'Estoque', Icons.warehouse_rounded),
          const Divider(color: Colors.white10),
          _buildDrawerItem(11, 'Entradas e Saidas', Icons.account_balance_rounded),
          _buildDrawerItem(12, 'DRE Gerencial', Icons.bar_chart_rounded),
          _buildDrawerItem(13, 'Permissoes', Icons.admin_panel_settings_rounded),
          _buildDrawerItem(14, 'Configuracoes', Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: isSelected ? AppColors.accentBlue.withValues(alpha: 0.12) : null,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      onTap: () => onItemSelected(index),
    );
  }
}
