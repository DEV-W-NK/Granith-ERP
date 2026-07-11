import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/models/ai_assistant_models.dart';
import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/screens/administrative_profit_page.dart';
import 'package:project_granith/screens/ai_assistant_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/HrPage.dart';
import 'package:project_granith/screens/benefits_page.dart';
import 'package:project_granith/screens/budget_types_page.dart';
import 'package:project_granith/screens/budgets_page.dart';
import 'package:project_granith/screens/dailyLogsPage.dart';
import 'package:project_granith/screens/geofencing_page.dart';
import 'package:project_granith/screens/inventory_page.dart';
import 'package:project_granith/screens/items_page.dart';
import 'package:project_granith/screens/labor_finance_analysis_page.dart';
import 'package:project_granith/screens/material_requisition_page.dart';
import 'package:project_granith/screens/project_measurements_page.dart';
import 'package:project_granith/screens/projects_page.dart';
import 'package:project_granith/screens/purchase_finance_page.dart';
import 'package:project_granith/screens/purchase_logistics_page.dart';
import 'package:project_granith/screens/purchases_page.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/system_settings_page.dart';
import 'package:project_granith/screens/suppliers_page.dart';
import 'package:project_granith/screens/team_page.dart';
import 'package:project_granith/screens/vehicles_page.dart';
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
  final int initialIndex;

  const MainLayout({
    super.key,
    this.pagesOverride,
    this.pageTitlesOverride,
    this.pageIconsOverride,
    this.navigationModulesOverride,
    this.initialIndex = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const double _desktopBreakpoint = 1100;

  late int selectedIndex;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

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
        const PurchaseLogisticsPage(),
        const InventoryPage(),
        const VehiclesPage(),
        const GeofencingPage(),
        const FinancialPage(),
        const LaborFinanceAnalysisPage(),
        const PurchaseFinancePage(),
        const ReportsPage(),
        const AccessManagementPage(),
        const AiAssistantPage(area: AiAssistantArea.operational),
        const AiAssistantPage(area: AiAssistantArea.humanResources),
        const AiAssistantPage(area: AiAssistantArea.commercial),
        const AiAssistantPage(area: AiAssistantArea.supplies),
        const AiAssistantPage(area: AiAssistantArea.administrative),
        const SystemSettingsPage(),
        const AdministrativeProfitPage(),
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
        'Coletas e Entregas',
        'Estoque',
        'Frota e Veiculos',
        'Geofencing',
        'Financeiro',
        'Ponto e Custos',
        'Compras no Financeiro',
        'DRE Gerencial',
        'Permissoes e Clientes',
        'IA Operacional',
        'IA Recursos Humanos',
        'IA Comercial',
        'IA Suprimentos',
        'IA Administrativa',
        'Configuracoes',
        'Resultado Administrativo',
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
        Icons.route_rounded,
        Icons.warehouse_rounded,
        Icons.directions_car_filled_rounded,
        Icons.map_rounded,
        Icons.account_balance_rounded,
        Icons.price_check_rounded,
        Icons.receipt_long_rounded,
        Icons.bar_chart_rounded,
        Icons.admin_panel_settings_rounded,
        Icons.engineering_rounded,
        Icons.badge_rounded,
        Icons.handshake_rounded,
        Icons.inventory_2_rounded,
        Icons.account_tree_rounded,
        Icons.settings_rounded,
        Icons.query_stats_rounded,
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
          aliases: 'rotas entregas coletas motorista km compras',
        ),
        NavigationModule(
          index: 14,
          title: pageTitles[14],
          section: 'Suprimentos',
          icon: pageIcons[14],
          aliases: 'estoque almoxarifado inventario',
        ),
        NavigationModule(
          index: 15,
          title: pageTitles[15],
          section: 'Administrativo',
          icon: pageIcons[15],
          aliases: 'frota veiculos carros combustivel consumo abastecimento',
        ),
        NavigationModule(
          index: 16,
          title: pageTitles[16],
          section: 'Administrativo',
          icon: pageIcons[16],
          aliases: 'geofencing cercas coordenadas mapa localizacao obra ponto',
        ),
        NavigationModule(
          index: 17,
          title: pageTitles[17],
          section: 'Financeiro',
          icon: pageIcons[17],
          aliases: 'entradas saidas receitas despesas caixa',
        ),
        NavigationModule(
          index: 18,
          title: pageTitles[18],
          section: 'Financeiro',
          icon: pageIcons[18],
          aliases: 'ponto custos horas mao obra geofence cerca funcionario',
        ),
        NavigationModule(
          index: 19,
          title: pageTitles[19],
          section: 'Financeiro',
          icon: pageIcons[19],
          aliases: 'compras financeiro contas pagar nota fiscal fornecedor',
        ),
        NavigationModule(
          index: 20,
          title: pageTitles[20],
          section: 'Financeiro',
          icon: pageIcons[20],
          aliases: 'dre relatorio gerencial resultados',
        ),
        NavigationModule(
          index: 21,
          title: pageTitles[21],
          section: 'Administrativo',
          icon: pageIcons[21],
          aliases: 'permissoes clientes acesso usuarios portal',
        ),
        NavigationModule(
          index: 22,
          title: pageTitles[22],
          section: 'I.A',
          icon: pageIcons[22],
          aliases: 'ia operacional obras campo diarios medicoes',
        ),
        NavigationModule(
          index: 23,
          title: pageTitles[23],
          section: 'I.A',
          icon: pageIcons[23],
          aliases: 'ia rh recursos humanos pessoas equipe beneficios',
        ),
        NavigationModule(
          index: 24,
          title: pageTitles[24],
          section: 'I.A',
          icon: pageIcons[24],
          aliases: 'ia comercial orcamentos clientes propostas',
        ),
        NavigationModule(
          index: 25,
          title: pageTitles[25],
          section: 'I.A',
          icon: pageIcons[25],
          aliases: 'ia suprimentos compras fornecedores estoque',
        ),
        NavigationModule(
          index: 26,
          title: pageTitles[26],
          section: 'I.A',
          icon: pageIcons[26],
          aliases: 'ia administrativa configuracoes acessos uso plataforma',
        ),
        NavigationModule(
          index: 27,
          title: pageTitles[27],
          section: 'Administrativo',
          icon: pageIcons[27],
          aliases: 'configuracoes ajustes sistema preferencias',
        ),
        NavigationModule(
          index: 28,
          title: pageTitles[28],
          section: 'Administrativo',
          icon: pageIcons[28],
          aliases:
              'resultado administrativo despesas lucro rentabilidade periodo obra',
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(contentRadius),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.pageSurfaceGradient,
                            borderRadius: BorderRadius.circular(contentRadius),
                            border: Border.all(
                              color: AppColors.borderColor.withValues(
                                alpha: 0.72,
                              ),
                            ),
                            boxShadow: AppColors.glowShadows(),
                          ),
                          child: GranithPageBackground(
                            child: _ModulePageSwitcher(
                              selectedIndex: selectedIndex,
                              child: pages[selectedIndex],
                            ),
                          ),
                        ),
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
                  child: GranithPageBackground(
                    child: _ModulePageSwitcher(
                      selectedIndex: selectedIndex,
                      child: pages[selectedIndex],
                    ),
                  ),
                ),
              ),
    );
  }

  void _selectModule(int index) {
    if (index < 0 || index >= pages.length) return;
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);
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

class _ModulePageSwitcher extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const _ModulePageSwitcher({required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (switchChild, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: switchChild,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(selectedIndex), child: child),
    );
  }
}
