import 'package:flutter/material.dart';
import 'package:project_granith/screens/access_management_page.dart';
import 'package:project_granith/screens/FinancialPage.dart';
import 'package:project_granith/screens/HrPage.dart';
import 'package:project_granith/screens/budget_types_page.dart';
import 'package:project_granith/screens/budgets_page.dart';
import 'package:project_granith/screens/dailyLogsPage.dart';
import 'package:project_granith/screens/inventory_page.dart';
import 'package:project_granith/screens/items_page.dart';
import 'package:project_granith/screens/material_requisition_page.dart';
import 'package:project_granith/screens/projects_page.dart';
import 'package:project_granith/screens/purchases_page.dart';
import 'package:project_granith/screens/reports_page.dart';
import 'package:project_granith/screens/suppliers_page.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/seeder.dart';
import 'package:project_granith/widgets/chrome/granith_app_backdrop.dart';
import 'package:project_granith/widgets/navigation/mobile_drawer.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';

import 'home_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;

  late final List<Widget> pages = [
    const HomePage(),
    const ProjectsPage(),
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
    _buildPlaceholderPage('Configuracoes', 'Em breve'),
  ];

  final List<String> pageTitles = [
    'Granith ERP',
    'Projetos',
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

  final List<IconData> pageIcons = [
    Icons.dashboard_rounded,
    Icons.business_rounded,
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _runSeeder,
        backgroundColor: AppColors.accentBlue,
        tooltip: 'Popular banco de dados',
        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.textPrimary),
      ),
      body: isDesktop
          ? Row(
              children: [
                SidebarMenu(
                  selectedIndex: selectedIndex,
                  onItemSelected: (index) =>
                      setState(() => selectedIndex = index),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.pageSurfaceGradient,
                          border: Border.all(
                            color: AppColors.borderColor.withValues(alpha: 0.72),
                          ),
                          boxShadow: AppColors.glowShadows(),
                        ),
                        child: GranithPageBackground(child: pages[selectedIndex]),
                      ),
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
                    Icon(pageIcons[selectedIndex],
                        color: AppColors.accentBlue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pageTitles[selectedIndex],
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
                backgroundColor: AppColors.primaryDark.withValues(alpha: 0.52),
                elevation: 0,
              ),
              drawer: MobileDrawer(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() => selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
              body: GranithPageBackground(child: pages[selectedIndex]),
            ),
    );
  }

  static Widget _buildPlaceholderPage(String title, String description) {
    return Center(
      child: Text(
        '$title\n$description',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _runSeeder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            backgroundColor: success ? AppColors.accentGreen : AppColors.accentRed,
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
