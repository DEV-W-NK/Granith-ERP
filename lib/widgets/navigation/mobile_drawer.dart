import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'package:provider/provider.dart';

class MobileDrawer extends StatefulWidget {
  final int selectedIndex;
  final List<NavigationModule> modules;
  final ValueChanged<int> onItemSelected;
  final Future<void> Function() onLogout;

  const MobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.modules,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  State<MobileDrawer> createState() => _MobileDrawerState();
}

class _MobileDrawerState extends State<MobileDrawer> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SystemSettingsViewModel>().settings;
    final auth = context.watch<AuthViewModel>();
    final filteredModules = _filteredModules();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 420 ? screenWidth * 0.9 : 380.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.96),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: screenWidth < 380 ? 118 : 144,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: AppColors.pageSurfaceGradient,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: screenWidth < 380 ? 42 : 50,
                    height: screenWidth < 380 ? 42 : 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentBlue.withValues(alpha: 0.95),
                          AppColors.auraCyan.withValues(alpha: 0.70),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.auraShadows(AppColors.accentBlue),
                    ),
                    child: const Icon(
                      Icons.architecture_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.workspaceName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 380 ? 18 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          settings.workspaceTagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  _DrawerInfoPill(
                    icon: Icons.grid_view_rounded,
                    label: '${widget.modules.length} modulos',
                  ),
                  const SizedBox(width: 8),
                  const _DrawerInfoPill(
                    icon: Icons.search_rounded,
                    label: 'Busca no menu',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Pesquisar modulo',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon:
                      _query.isEmpty
                          ? null
                          : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (filteredModules.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 22, 18, 12),
                child: Text(
                  'Nenhum modulo encontrado.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ..._buildModuleItems(filteredModules),
            const Divider(color: Colors.white10),
            if ((auth.user?.email ?? '').trim().isNotEmpty)
              ListTile(
                title: Text(
                  auth.user!.email,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.accentRed,
              ),
              title: const Text(
                'Sair',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  List<NavigationModule> _filteredModules() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.modules;
    return widget.modules.where((module) => module.matches(query)).toList();
  }

  List<Widget> _buildModuleItems(List<NavigationModule> modules) {
    final children = <Widget>[];
    String? lastSection;

    for (final module in modules) {
      if (module.section != lastSection) {
        if (lastSection != null) {
          children.add(const Divider(color: Colors.white10));
        }
        if (module.section != 'Inicio') {
          children.add(_DrawerSectionTitle(title: module.section));
        }
        lastSection = module.section;
      }
      children.add(_buildDrawerItem(module));
    }

    return children;
  }

  Widget _buildDrawerItem(NavigationModule module) {
    final isSelected = widget.selectedIndex == module.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor:
            isSelected
                ? AppColors.accentBlue.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.018),
        leading: Icon(
          module.icon,
          color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
        ),
        title: Text(
          module.title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing:
            isSelected
                ? const Icon(
                  Icons.check_rounded,
                  color: AppColors.accentBlue,
                  size: 18,
                )
                : null,
        onTap: () => widget.onItemSelected(module.index),
      ),
    );
  }
}

class _DrawerInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DrawerInfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.42),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  final String title;

  const _DrawerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
