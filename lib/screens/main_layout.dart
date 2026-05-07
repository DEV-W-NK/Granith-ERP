import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/HrPage.dart';
import 'package:project_granith/screens/benefits_page.dart';
import 'package:project_granith/screens/budget_types_page.dart';
import 'package:project_granith/screens/budgets_page.dart';
import 'package:project_granith/screens/dailyLogsPage.dart';
import 'package:project_granith/screens/inventory_page.dart';
import 'package:project_granith/screens/items_page.dart';
import 'package:project_granith/screens/material_requisition_page.dart';
import 'package:project_granith/screens/project_measurements_page.dart';
import 'package:project_granith/screens/projects_page.dart';
import 'package:project_granith/screens/purchases_page.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/system_settings_page.dart';
import 'package:project_granith/screens/suppliers_page.dart';
import 'package:project_granith/screens/team_page.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:project_granith/widgets/navigation/mobile_drawer.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';

class MainLayout extends StatefulWidget {
  final List<Widget>? pagesOverride;
  final List<String>? pageTitlesOverride;
  final List<IconData>? pageIconsOverride;
  final List<NavigationModule>? navigationModulesOverride;

  const MainLayout({
    super.key,
    this.pagesOverride,
    this.pageTitlesOverride,
    this.pageIconsOverride,
    this.navigationModulesOverride,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const double _desktopBreakpoint = 1100;

  int selectedIndex = 0;
  bool _isSidebarExpanded = true;

  late final List<Widget> pages =
      widget.pagesOverride ??
      [
        const HomePage(),
        const ProjectsPage(),
        const ProjectMeasurementsPage(),
        const DailyLogsPage(),
        const MaterialRequisitionPage(),
        const HrPage(),
        const BenefitsPage(),
        const TeamPage(),
        const BudgetsPage(),
        const BudgetTypesPage(),
        const SuppliersPage(),
        const ItemsPage(),
        const PurchasesPage(),
        const InventoryPage(),
        const FinancialPage(),
        const ReportsPage(),
        const AccessManagementPage(),
        const SystemSettingsPage(),
      ];

  late final List<String> pageTitles =
      widget.pageTitlesOverride ??
      [
        'Granith ERP',
        'Projetos',
        'Medicoes de Obra',
        'Diario de Obras',
        'Requisicoes',
        'Recursos Humanos',
        'Beneficios',
        'Equipes',
        'Orcamentos',
        'Tipos de Orcamento',
        'Fornecedores',
        'Catalogo de Itens',
        'Compras e Pedidos',
        'Estoque',
        'Financeiro',
        'DRE Gerencial',
        'Permissoes e Clientes',
        'Configuracoes',
      ];

  late final List<IconData> pageIcons =
      widget.pageIconsOverride ??
      [
        Icons.dashboard_rounded,
        Icons.business_rounded,
        Icons.query_stats_rounded,
        Icons.menu_book_rounded,
        Icons.assignment_rounded,
        Icons.badge_rounded,
        Icons.card_giftcard_rounded,
        Icons.groups_2_rounded,
        Icons.receipt_long_rounded,
        Icons.category_rounded,
        Icons.store_rounded,
        Icons.inventory_2_rounded,
        Icons.shopping_cart_rounded,
        Icons.warehouse_rounded,
        Icons.account_balance_rounded,
        Icons.bar_chart_rounded,
        Icons.admin_panel_settings_rounded,
        Icons.settings_rounded,
      ];

  late final List<NavigationModule> _navigationModules =
      widget.navigationModulesOverride ??
      [
        NavigationModule(
          index: 0,
          title: pageTitles[0],
          section: 'Inicio',
          icon: pageIcons[0],
          aliases: 'dashboard painel indicadores home',
        ),
        NavigationModule(
          index: 1,
          title: pageTitles[1],
          section: 'Operacional',
          icon: pageIcons[1],
          aliases: 'obras contratos execucao',
        ),
        NavigationModule(
          index: 2,
          title: pageTitles[2],
          section: 'Operacional',
          icon: pageIcons[2],
          aliases: 'medicoes progresso andamento fisico percentual obra',
        ),
        NavigationModule(
          index: 3,
          title: pageTitles[3],
          section: 'Operacional',
          icon: pageIcons[3],
          aliases: 'rdo diario obras campo',
        ),
        NavigationModule(
          index: 4,
          title: pageTitles[4],
          section: 'Operacional',
          icon: pageIcons[4],
          aliases: 'materiais requisicoes pedidos internos',
        ),
        NavigationModule(
          index: 5,
          title: pageTitles[5],
          section: 'Recursos Humanos',
          icon: pageIcons[5],
          aliases: 'rh funcionarios equipe pessoas colaboradores',
        ),
        NavigationModule(
          index: 6,
          title: pageTitles[6],
          section: 'Recursos Humanos',
          icon: pageIcons[6],
          aliases: 'beneficios categorias vale reembolso colaboradores',
        ),
        NavigationModule(
          index: 7,
          title: pageTitles[7],
          section: 'Recursos Humanos',
          icon: pageIcons[7],
          aliases: 'equipes time montagem colaboradores rh coordenadores',
        ),
        NavigationModule(
          index: 8,
          title: pageTitles[8],
          section: 'Comercial',
          icon: pageIcons[8],
          aliases: 'orcamentos propostas comercial',
        ),
        NavigationModule(
          index: 9,
          title: pageTitles[9],
          section: 'Comercial',
          icon: pageIcons[9],
          aliases: 'categorias tipos orcamento',
        ),
        NavigationModule(
          index: 10,
          title: pageTitles[10],
          section: 'Suprimentos',
          icon: pageIcons[10],
          aliases: 'fornecedor suprimentos parceiros',
        ),
        NavigationModule(
          index: 11,
          title: pageTitles[11],
          section: 'Suprimentos',
          icon: pageIcons[11],
          aliases: 'itens materiais catalogo insumos',
        ),
        NavigationModule(
          index: 12,
          title: pageTitles[12],
          section: 'Suprimentos',
          icon: pageIcons[12],
          aliases: 'compras pedidos cotacoes',
        ),
        NavigationModule(
          index: 13,
          title: pageTitles[13],
          section: 'Suprimentos',
          icon: pageIcons[13],
          aliases: 'estoque almoxarifado inventario',
        ),
        NavigationModule(
          index: 14,
          title: pageTitles[14],
          section: 'Financeiro',
          icon: pageIcons[14],
          aliases: 'entradas saidas receitas despesas caixa',
        ),
        NavigationModule(
          index: 15,
          title: pageTitles[15],
          section: 'Financeiro',
          icon: pageIcons[15],
          aliases: 'dre relatorio gerencial resultados',
        ),
        NavigationModule(
          index: 16,
          title: pageTitles[16],
          section: 'Administrativo',
          icon: pageIcons[16],
          aliases: 'permissoes clientes acesso usuarios portal',
        ),
        NavigationModule(
          index: 17,
          title: pageTitles[17],
          section: 'Administrativo',
          icon: pageIcons[17],
          aliases: 'configuracoes ajustes sistema preferencias',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _desktopBreakpoint;
    final desktopPadding = screenWidth >= 1280 ? 18.0 : 12.0;
    final contentRadius = screenWidth >= 1280 ? 28.0 : 22.0;
    final workspaceName =
        context.watch<SystemSettingsViewModel>().settings.workspaceName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          isDesktop
              ? Row(
                children: [
                  SidebarMenu(
                    selectedIndex: selectedIndex,
                    modules: _navigationModules,
                    isExpanded: _isSidebarExpanded,
                    onItemSelected: _selectModule,
                    onToggle:
                        () => setState(
                          () => _isSidebarExpanded = !_isSidebarExpanded,
                        ),
                    onLogout: _confirmAndLogout,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(desktopPadding),
                      child: Column(
                        children: [
                          _buildDesktopTopBar(workspaceName),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                contentRadius,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.pageSurfaceGradient,
                                  borderRadius: BorderRadius.circular(
                                    contentRadius,
                                  ),
                                  border: Border.all(
                                    color: AppColors.borderColor.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                  boxShadow: AppColors.glowShadows(),
                                ),
                                child: GranithPageBackground(
                                  child: pages[selectedIndex],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  titleSpacing: 10,
                  title: Row(
                    children: [
                      Icon(
                        pageIcons[selectedIndex],
                        color: AppColors.accentBlue,
                        size: screenWidth < 380 ? 20 : 24,
                      ),
                      SizedBox(width: screenWidth < 380 ? 8 : 12),
                      Expanded(
                        child: Text(
                          selectedIndex == 0
                              ? workspaceName
                              : pageTitles[selectedIndex],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth < 380 ? 15 : 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: _confirmAndLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  backgroundColor: AppColors.primaryDark.withValues(
                    alpha: 0.52,
                  ),
                  elevation: 0,
                ),
                drawer: MobileDrawer(
                  selectedIndex: selectedIndex,
                  modules: _navigationModules,
                  onItemSelected: (index) {
                    _selectModule(index);
                    Navigator.pop(context);
                  },
                  onLogout: _confirmAndLogout,
                ),
                body: SafeArea(
                  top: false,
                  child: GranithPageBackground(child: pages[selectedIndex]),
                ),
              ),
    );
  }

  void _selectModule(int index) {
    if (index < 0 || index >= pages.length) return;
    setState(() => selectedIndex = index);
  }

  Widget _buildDesktopTopBar(String workspaceName) {
    final currentModule = _navigationModules.firstWhere(
      (module) => module.index == selectedIndex,
      orElse: () => _navigationModules.first,
    );
    final currentTitle =
        selectedIndex == 0 ? workspaceName : pageTitles[selectedIndex];
    final currentSection = currentModule.section;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: AppColors.pageSurfaceGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.72),
        ),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leading = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.22),
                      AppColors.auraCyan.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  pageIcons[selectedIndex],
                  color: AppColors.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentSection,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final logoutButton = IconButton(
            tooltip: 'Sair',
            onPressed: _confirmAndLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textPrimary,
            ),
          );

          return Row(
            children: [
              Expanded(child: leading),
              const SizedBox(width: 10),
              if (constraints.maxWidth >= 720) ...[
                _TopBarPill(
                  icon: Icons.layers_rounded,
                  label: currentSection,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 8),
                _TopBarPill(
                  icon: Icons.auto_awesome_rounded,
                  label: 'ERP ativo',
                  color: AppColors.auraCyan,
                ),
                const SizedBox(width: 8),
              ],
              logoutButton,
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.92),
            title: const Text(
              'Encerrar sessao?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Voce sera redirecionado para a tela de login.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sair',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    await context.read<AuthViewModel>().logout();
  }
}

class _TopBarPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TopBarPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
