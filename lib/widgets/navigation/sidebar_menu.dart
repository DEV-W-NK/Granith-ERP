import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class NavigationModule {
  final int index;
  final String title;
  final String section;
  final IconData icon;
  final String aliases;

  const NavigationModule({
    required this.index,
    required this.title,
    required this.section,
    required this.icon,
    required this.aliases,
  });

  bool matches(String query) {
    final searchable = '$title $section $aliases'.toLowerCase();
    return searchable.contains(query);
  }
}

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationModule> modules;
  final bool isExpanded;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggle;
  final Future<void> Function() onLogout;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.modules,
    required this.isExpanded,
    required this.onItemSelected,
    required this.onToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;
    final auth = context.watch<AuthViewModel>();
    final expandedWidth = settings.compactNavigation ? 236.0 : 272.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isExpanded ? expandedWidth : 88,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        gradient: AppColors.pageSurfaceGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.75),
        ),
        boxShadow: AppColors.glowShadows(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(
              settings.workspaceName,
              settings.workspaceTagline,
              settings.compactNavigation,
            ),
            Expanded(
              child: isExpanded ? _buildExpandedList() : _buildCollapsedRail(),
            ),
            _buildFooter(context, auth.user?.email ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String workspaceName, String tagline, bool isCompact) {
    if (!isExpanded) {
      return Container(
        height: 110,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: Column(
          children: [
            IconButton(
              tooltip: 'Expandir menu',
              onPressed: onToggle,
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/branding/granith_app_icon.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 98,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 22),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/branding/granith_app_icon.png',
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspaceName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 17 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: isCompact ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Recolher menu',
            onPressed: onToggle,
            icon: const Icon(
              Icons.menu_open_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedList() {
    final children = <Widget>[];
    String? lastSection;

    for (final module in modules) {
      if (module.section != lastSection) {
        if (module.section != 'Inicio') {
          children.add(_buildSectionTitle(module.section));
        }
        lastSection = module.section;
      }
      children.add(_buildExpandedMenuItem(module));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      children: children,
    );
  }

  Widget _buildCollapsedRail() {
    final children = <Widget>[];
    String? lastSection;

    for (final module in modules) {
      if (lastSection != null && module.section != lastSection) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Divider(
              height: 1,
              color: AppColors.borderColor.withValues(alpha: 0.45),
            ),
          ),
        );
      }
      children.add(_buildRailItem(module));
      lastSection = module.section;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
      children: children,
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

  Widget _buildExpandedMenuItem(NavigationModule module) {
    final isSelected = selectedIndex == module.index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => onItemSelected(module.index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _itemDecoration(isSelected),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Icon(
                  module.icon,
                  size: 23,
                  color:
                      isSelected
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _sidebarTitle(module),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    height: 1,
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

  Widget _buildRailItem(NavigationModule module) {
    final isSelected = selectedIndex == module.index;
    return Tooltip(
      message: module.title,
      waitDuration: const Duration(milliseconds: 450),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () => onItemSelected(module.index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 60,
            height: 52,
            decoration: _itemDecoration(isSelected),
            child: Icon(
              module.icon,
              size: 24,
              color:
                  isSelected ? AppColors.accentBlue : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _itemDecoration(bool isSelected) {
    return BoxDecoration(
      color:
          isSelected
              ? AppColors.accentBlue.withValues(alpha: 0.12)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color:
            isSelected
                ? AppColors.accentBlue.withValues(alpha: 0.58)
                : Colors.transparent,
      ),
    );
  }

  Widget _buildFooter(BuildContext context, String email) {
    if (!isExpanded) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Sobre o Granith',
              child: IconButton(
                onPressed: () => _showAbout(context),
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accentGold,
                ),
              ),
            ),
            Tooltip(
              message: 'Sair',
              child: IconButton(
                onPressed: onLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.accentRed,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.55)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderColor.withValues(alpha: 0.48),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sessao ativa',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showAbout(context),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text('Sobre o Granith'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Granith ERP',
      applicationVersion: '0.1.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/branding/granith_app_icon.png',
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      ),
      applicationLegalese: 'Granith - gestao integrada para obras.',
      children: const [
        SizedBox(height: 12),
        Text(
          'ERP web para controlar projetos, financeiro, estoque, compras, '
          'equipes, rotas, geofencing, portal do cliente e integracoes mobile.',
        ),
      ],
    );
  }

  String _sidebarTitle(NavigationModule module) {
    switch (module.index) {
      case 2:
        return 'Medicoes';
      case 9:
        return 'Tipos de Orc.';
      case 11:
        return 'Catalogo de Itens';
      case 12:
        return 'Compras';
      case 17:
        return 'Entradas e Saidas';
      case 18:
        return 'Ponto e Custos';
      case 19:
        return 'Compras a Pagar';
      case 20:
        return 'DRE';
      case 21:
        return 'Acessos';
      case 28:
        return 'Resultado Adm.';
      default:
        return module.title;
    }
  }
}
