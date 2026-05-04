import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/settings/presentation/viewmodels/system_settings_view_model.dart';
import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/HrPage.dart';
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
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/seeder.dart';
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
  static const bool _enableDatabaseSeeder = bool.fromEnvironment(
    'ENABLE_DATABASE_SEEDER',
  );

  int selectedIndex = 0;
  bool _isSidebarExpanded = true;

  bool get _canRunSeeder => kDebugMode && _enableDatabaseSeeder;

  late final List<Widget> pages =
      widget.pagesOverride ??
      [
        const HomePage(),
        const ProjectsPage(),
        const ProjectMeasurementsPage(),
        const DailyLogsPage(),
        const MaterialRequisitionPage(),
        const HrPage(),
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
          section: 'Comercial',
          icon: pageIcons[6],
          aliases: 'orcamentos propostas comercial',
        ),
        NavigationModule(
          index: 7,
          title: pageTitles[7],
          section: 'Comercial',
          icon: pageIcons[7],
          aliases: 'categorias tipos orcamento',
        ),
        NavigationModule(
          index: 8,
          title: pageTitles[8],
          section: 'Suprimentos',
          icon: pageIcons[8],
          aliases: 'fornecedor suprimentos parceiros',
        ),
        NavigationModule(
          index: 9,
          title: pageTitles[9],
          section: 'Suprimentos',
          icon: pageIcons[9],
          aliases: 'itens materiais catalogo insumos',
        ),
        NavigationModule(
          index: 10,
          title: pageTitles[10],
          section: 'Suprimentos',
          icon: pageIcons[10],
          aliases: 'compras pedidos cotacoes',
        ),
        NavigationModule(
          index: 11,
          title: pageTitles[11],
          section: 'Suprimentos',
          icon: pageIcons[11],
          aliases: 'estoque almoxarifado inventario',
        ),
        NavigationModule(
          index: 12,
          title: pageTitles[12],
          section: 'Financeiro',
          icon: pageIcons[12],
          aliases: 'entradas saidas receitas despesas caixa',
        ),
        NavigationModule(
          index: 13,
          title: pageTitles[13],
          section: 'Financeiro',
          icon: pageIcons[13],
          aliases: 'dre relatorio gerencial resultados',
        ),
        NavigationModule(
          index: 14,
          title: pageTitles[14],
          section: 'Administrativo',
          icon: pageIcons[14],
          aliases: 'permissoes clientes acesso usuarios portal',
        ),
        NavigationModule(
          index: 15,
          title: pageTitles[15],
          section: 'Administrativo',
          icon: pageIcons[15],
          aliases: 'configuracoes ajustes sistema preferencias',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final workspaceName =
        context.watch<SystemSettingsViewModel>().settings.workspaceName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          _canRunSeeder
              ? FloatingActionButton(
                onPressed: _runSeeder,
                backgroundColor: AppColors.accentBlue,
                tooltip: 'Popular banco de dados',
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: AppColors.textPrimary,
                ),
              )
              : null,
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
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        children: [
                          _buildDesktopTopBar(workspaceName),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.pageSurfaceGradient,
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
                  titleSpacing: 18,
                  title: Row(
                    children: [
                      Icon(
                        pageIcons[selectedIndex],
                        color: AppColors.accentBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedIndex == 0
                              ? workspaceName
                              : pageTitles[selectedIndex],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Pesquisar modulo',
                      onPressed: _openModuleSearchDialog,
                      icon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: _confirmAndLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  backgroundColor: AppColors.primaryDark.withValues(
                    alpha: 0.52,
                  ),
                  elevation: 0,
                ),
                drawer: MobileDrawer(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) {
                    _selectModule(index);
                    Navigator.pop(context);
                  },
                  onLogout: _confirmAndLogout,
                ),
                body: GranithPageBackground(child: pages[selectedIndex]),
              ),
    );
  }

  void _selectModule(int index) {
    if (index < 0 || index >= pages.length) return;
    setState(() => selectedIndex = index);
  }

  Widget _buildDesktopTopBar(String workspaceName) {
    final currentTitle =
        selectedIndex == 0 ? workspaceName : pageTitles[selectedIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.pageSurfaceGradient,
        borderRadius: BorderRadius.circular(24),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  pageIcons[selectedIndex],
                  color: AppColors.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  currentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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

          if (constraints.maxWidth < 920) {
            return Column(
              children: [
                Row(children: [Expanded(child: leading), logoutButton]),
                const SizedBox(height: 12),
                _buildModuleSearch(),
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 18),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildModuleSearch(),
                ),
              ),
              const SizedBox(width: 10),
              logoutButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleSearch({
    ValueChanged<int>? onModuleSelected,
    bool autofocus = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final optionsWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth < 520
                ? constraints.maxWidth
                : 520.0;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Autocomplete<NavigationModule>(
            displayStringForOption: (module) => module.title,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return const Iterable<NavigationModule>.empty();
              }

              return _navigationModules
                  .where((module) => module.matches(query))
                  .take(8);
            },
            onSelected: (module) {
              final handler = onModuleSelected;
              if (handler != null) {
                handler(module.index);
                return;
              }

              _selectModule(module.index);
            },
            fieldViewBuilder: (
              context,
              textEditingController,
              focusNode,
              onFieldSubmitted,
            ) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                autofocus: autofocus,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Pesquisar modulo',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
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
                    width: optionsWidth,
                    constraints: const BoxConstraints(maxHeight: 360),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.pageSurfaceGradient,
                      borderRadius: BorderRadius.circular(18),
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
                            color: AppColors.borderColor.withValues(
                              alpha: 0.35,
                            ),
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
                            module.title,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            module.section,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.accentBlue,
                                  )
                                  : const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.textMuted,
                                    size: 14,
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
      },
    );
  }

  Future<void> _openModuleSearchDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pesquisar modulo'),
          content: SizedBox(
            width: 520,
            child: _buildModuleSearch(
              autofocus: true,
              onModuleSelected: (index) {
                Navigator.pop(dialogContext);
                _selectModule(index);
              },
            ),
          ),
        );
      },
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

  Future<void> _runSeeder() async {
    if (!_canRunSeeder) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.92),
            title: const Text(
              'Executar Seeder?',
              style: TextStyle(color: AppColors.accentBlue),
            ),
            content: const Text(
              'Isso ira criar dados ficticios no banco de dados. Deseja continuar?',
              style: TextStyle(color: AppColors.textPrimary),
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
                  'Sim, popular',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciando Seeder... isso pode levar alguns segundos.'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        final seeder = DatabaseSeeder();
        final success = await seeder.seed();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Banco de dados populado com sucesso.'
                  : 'Erro ao popular banco. Verifique o console.',
            ),
            backgroundColor:
                success ? AppColors.accentGreen : AppColors.accentRed,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro critico: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }
}
