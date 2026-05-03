import 'package:flutter/material.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;
    final isCompact = settings.compactNavigation;

    return Container(
      width: isCompact ? 236 : 272,
      margin: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      decoration: BoxDecoration(
        gradient: AppColors.pageSurfaceGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.75)),
        boxShadow: AppColors.glowShadows(),
      ),
      child: Column(
        children: [
          _buildLogo(settings.workspaceName, settings.workspaceTagline, isCompact),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              children: [
                _buildMenuItem(0, 'Dashboard', Icons.dashboard_rounded),
                const SizedBox(height: 16),
                _buildSectionTitle('Operacional'),
                _buildMenuItem(1, 'Projetos', Icons.business_rounded),
                _buildMenuItem(2, 'Diario de Obras', Icons.menu_book_rounded),
                _buildMenuItem(3, 'Requisicoes', Icons.playlist_add_check_rounded),
                _buildSectionTitle('Recursos Humanos'),
                _buildMenuItem(4, 'Gestao de RH', Icons.engineering_rounded),
                _buildSectionTitle('Comercial'),
                _buildMenuItem(5, 'Orcamentos', Icons.receipt_long_rounded),
                _buildMenuItem(6, 'Tipos de Orc.', Icons.category_rounded),
                _buildSectionTitle('Suprimentos'),
                _buildMenuItem(7, 'Fornecedores', Icons.store_rounded),
                _buildMenuItem(8, 'Catalogo de Itens', Icons.inventory_2_rounded),
                _buildMenuItem(9, 'Compras', Icons.shopping_cart_rounded),
                _buildMenuItem(10, 'Estoque', Icons.warehouse_rounded),
                _buildSectionTitle('Financeiro'),
                _buildMenuItem(11, 'Entradas e Saidas', Icons.account_balance_rounded),
                _buildMenuItem(12, 'DRE Financeiro', Icons.bar_chart_rounded),
                _buildSectionTitle('Administrativo'),
                _buildMenuItem(13, 'Permissoes', Icons.admin_panel_settings_rounded),
                _buildMenuItem(14, 'Configuracoes', Icons.settings_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String workspaceName, String tagline, bool isCompact) {
    return Container(
      height: 96,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.55)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.95),
                  AppColors.auraCyan.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: AppColors.auraShadows(AppColors.accentBlue),
            ),
            child: const Icon(Icons.architecture, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workspaceName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 17 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tagline,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: isCompact ? 10 : 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentBlue.withValues(alpha: 0.65)
                  : Colors.transparent,
            ),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.18),
                      AppColors.auraCyan.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            boxShadow: isSelected ? AppColors.auraShadows(AppColors.accentBlue) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
