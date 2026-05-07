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
            if (isExpanded) _buildModuleSearch(),
            Expanded(
              child: isExpanded ? _buildExpandedList() : _buildCollapsedRail(),
            ),
            _buildFooter(auth.user?.email ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Autocomplete<NavigationModule>(
        displayStringForOption: (module) => module.title,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return const Iterable<NavigationModule>.empty();
          }
          return modules.where((module) => module.matches(query)).take(8);
        },
        onSelected: (module) => onItemSelected(module.index),
        fieldViewBuilder: (
          context,
          textEditingController,
          focusNode,
          onFieldSubmitted,
        ) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Pesquisar modulo',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
            onSubmitted: (_) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final entries = options.toList();

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: isExpanded ? 244 : 0,
                constraints: const BoxConstraints(maxHeight: 320),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.pageSurfaceGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderColor.withValues(alpha: 0.85),
                  ),
                  boxShadow: AppColors.glowShadows(AppColors.accentBlue),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        color: AppColors.borderColor.withValues(alpha: 0.35),
                      ),
                  itemBuilder: (context, index) {
                    final module = entries[index];
                    final isSelected = module.index == selectedIndex;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        module.icon,
                        color:
                            isSelected
                                ? AppColors.accentBlue
                                : AppColors.textSecondary,
                      ),
                      title: Text(
                        _sidebarTitle(module),
                        style: TextStyle(
                          color:
                              isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        module.section,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      onTap: () => onSelected(module),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String workspaceName, String tagline, bool isCompact) {
    if (!isExpanded) {
      return Container(
        height: 108,
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
            Container(
              width: 34,
              height: 34,
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
              child: const Icon(
                Icons.architecture,
                color: AppColors.textPrimary,
                size: 18,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: _itemDecoration(isSelected),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 46,
                      child: Icon(
                        module.icon,
                        size: 20,
                        color:
                            isSelected
                                ? AppColors.accentBlue
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _sidebarTitle(module),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                            fontSize: 13,
                            height: 1,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
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
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 56,
            height: 48,
            decoration: _itemDecoration(isSelected),
            child: Icon(
              module.icon,
              size: 21,
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
      color: isSelected ? null : Colors.white.withValues(alpha: 0.018),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color:
            isSelected
                ? AppColors.accentBlue.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.03),
      ),
      gradient:
          isSelected
              ? LinearGradient(
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.18),
                  AppColors.auraCyan.withValues(alpha: 0.08),
                ],
              )
              : null,
      boxShadow:
          isSelected ? AppColors.auraShadows(AppColors.accentBlue) : null,
    );
  }

  Widget _buildFooter(String email) {
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
        child: Tooltip(
          message: 'Sair',
          child: IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.accentRed),
          ),
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
      case 14:
        return 'Entradas e Saidas';
      case 16:
        return 'Permissoes';
      default:
        return module.title;
    }
  }
}
